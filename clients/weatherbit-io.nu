# Auto-generated client for Weatherbit - Interactive Swagger UI Documentation v2.0.0
# Source: https://api.apis.guru/v2/specs/weatherbit.io/2.0.0/swagger.json
# Auth: --token flag or $env.WEATHERBIT_INTERACTIVE_SWAGGER_UI_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.weatherbit.io/v2.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEATHERBIT_INTERACTIVE_SWAGGER_UI_DOCUMENTATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.weatherbit.io/v2.0" "http://api.weatherbit.io/v2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def units-completer [] { ["I" "S"] }
def marine-completer [] { ["t"] }
def lang-completer [] { ["ar" "az" "be" "bg" "bs" "ca" "cs" "de" "el" "es" "et" "fi" "fr" "hr" "hu" "id" "is" "it" "kw" "nb" "nl" "pl" "pt" "ro" "ru" "sk" "sl" "sr" "sv" "tr" "uk" "zh" "zh-tw"] }
def include-completer [] { ["minutely"] }
def tp-completer [] { ["daily" "hourly"] }
def tp-completer-1 [] { ["daily" "hourly" "monthly"] }
def tz-completer [] { ["local" "utc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alerts-lat-lat-lon-lon get" } } | get name | first)
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

# Returns severe weather alerts issued by meteorological agencies - Given a lat/lon.
#
# GET /alerts?lat={lat}&lon={lon}
export def "alerts-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<alerts: table<alerts: list, description: string, effective_local: string, effective_utc: string, expires_local: string, expires_utc: string, severity: string, title: string, uri: string>, lat: float, lon: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/alerts?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download pre-generated bulk datasets
#
# GET /bulk/files/{file}
export def "bulk-files get" [
  file: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Your registered API key. (format: string)
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file: (encode-path-segment $file)} | format pattern "/bulk/files/{file}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns current air quality conditions - Given City and/or State, Country.
#
# GET /current/airquality?city={city}&country={country}
export def "current-airquality-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/current/airquality?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns current air quality conditions - Given a City ID.
#
# GET /current/airquality?city_id={city_id}
export def "current-airquality-city-id-city-id get" [
  city_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/current/airquality?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns current air quality conditions - Given a lat/lon.
#
# GET /current/airquality?lat={lat}&lon={lon}
export def "current-airquality-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/current/airquality?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns current air quality conditions - Given a Postal Code.
#
# GET /current/airquality?postal_code={postal_code}
export def "current-airquality-postal-code-postal-code get" [
  postal_code: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/current/airquality?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a group of observations given a list of cities
#
# GET /current?cities={cities}
export def "current-cities-cities get" [
  cities: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "units" $units "scalar") (serialize-qp "marine" $marine "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cities: (encode-path-segment $cities)} | format pattern "/current?cities={cities}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a Current Observation - Given City and/or State, Country.
#
# GET /current?city={city}&country={country}
export def "current-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --state: string # Full name of state. (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "marine" $marine "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/current?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a current observation by city id.
#
# GET /current?city_id={city_id}
export def "current-city-id-city-id get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "units" $units "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "marine" $marine "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/current?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a Current Observation - Given a lat/lon.
#
# GET /current?lat={lat}&lon={lon}
export def "current-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "marine" $marine "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/current?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a group of observations given a list of points in the format (lat1, lon1), (lat2, lon2), (latN, lonN), ...
#
# GET /current?points={points}
export def "current-points-points get" [
  points: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({points: (encode-path-segment $points)} | format pattern "/current?points={points}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a current observation by postal code.
#
# GET /current?postal_code={postal_code}
export def "current-postal-code-postal-code get" [
  postal_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --marine: string@marine-completer # Marine stations only (buoys, oil platforms, etc) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback - Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "marine" $marine "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/current?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a Current Observation. - Given a station ID.
#
# GET /current?station={station}
export def "current-station-station get" [
  station: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer # Include 1 hour - minutely forecast in the response (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({station: (encode-path-segment $station)} | format pattern "/current?station={station}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a group of observations given a list of stations
#
# GET /current?stations={stations}
export def "current-stations-stations get" [
  stations: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<app_temp: float, aqi: float, city_name: string, clouds: int, country_code: string, datetime: string, dewpt: float, dhi: float, dni: float, elev_angle: float, ghi: float, gust: float, hour_angle: float, lat: float, lon: float, ob_time: string, pod: string, precip: float, pres: float, rh: int, slp: float, snow: float, solar_rad: float, sources: list, state_code: string, station: string, sunrise: string, sunset: string, temp: float, timezone: string, ts: float, uv: float, vis: int, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_speed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({stations: (encode-path-segment $stations)} | format pattern "/current?stations={stations}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns 72 hour (hourly) Air Quality forecast - Given City and/or State, Country.
#
# GET /forecast/airquality?city={city}&country={country}
export def "forecast-airquality-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/forecast/airquality?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns 72 hour (hourly) Air Quality forecast - Given a City ID.
#
# GET /forecast/airquality?city_id={city_id}
export def "forecast-airquality-city-id-city-id get" [
  city_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/forecast/airquality?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns 72 hour (hourly) Air Quality forecast - Given a lat/lon.
#
# GET /forecast/airquality?lat={lat}&lon={lon}
export def "forecast-airquality-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
  --hours: int # Number of hours to return. (format: integer)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "hours" $hours "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/forecast/airquality?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns 72 hour (hourly) Air Quality forecast - Given a Postal Code.
#
# GET /forecast/airquality?postal_code={postal_code}
export def "forecast-airquality-postal-code-postal-code get" [
  postal_code: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float, timestamp_local: string, timestamp_utc: string, ts: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/forecast/airquality?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a daily forecast - Given City and/or State, Country.
#
# GET /forecast/daily?city={city}&country={country}
export def "forecast-daily-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --days: float # Number of days to return. Default 16. (format: integer)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/forecast/daily?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a daily forecast - Given a City ID.
#
# GET /forecast/daily?city_id={city_id}
export def "forecast-daily-city-id-city-id get" [
  city_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days: float # Number of days to return. Default 16. (format: integer)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/forecast/daily?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a daily forecast - Given Lat/Lon.
#
# GET /forecast/daily?lat={lat}&lon={lon}
export def "forecast-daily-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --days: float # Number of days to return. Default 16. (format: integer)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/forecast/daily?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a daily forecast - Given a Postal Code.
#
# GET /forecast/daily?postal_code={postal_code}
export def "forecast-daily-postal-code-postal-code get" [
  postal_code: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --days: float # Number of days to return. Default 16. (format: integer)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_max_temp: float, app_min_temp: float, clouds: int, datetime: string, dewpt: float, max_dhi: float, max_temp: float, min_temp: float, moon_phase: float, moonrise_ts: int, moonset_ts: int, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, sunrise_ts: int, sunset_ts: int, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/forecast/daily?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Energy Forecast API response - Given a single lat/lon.
#
# GET /forecast/energy?lat={lat}&lon={lon}
export def "forecast-energy-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --threshold: float # Temperature threshold to use to calculate degree days (default 18 C) (format: double)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --tp: string@tp-completer # Time period (default: daily) (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<cdd: float, clouds: int, date: string, dewpt: float, hdd: float, precip: float, rh: int, snow: float, sun_hours: float, t_dhi: float, t_dni: float, t_ghi: float, temp: float, wind_dir: int, wind_spd: float>, lat: string, lon: string, state_code: string, threshold_units: string, threshold_value: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "threshold" $threshold "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "tp" $tp "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/forecast/energy?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns an hourly forecast - Given City and/or State, Country.
#
# GET /forecast/hourly?city={city}&country={country}
export def "forecast-hourly-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/forecast/hourly?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns an hourly forecast - Given a City ID.
#
# GET /forecast/hourly?city_id={city_id}
export def "forecast-hourly-city-id-city-id get" [
  city_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/forecast/hourly?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns an hourly forecast - Given a lat/lon.
#
# GET /forecast/hourly?lat={lat}&lon={lon}
export def "forecast-hourly-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
  --hours: int # Number of hours to return. (format: integer)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "hours" $hours "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/forecast/hourly?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns an hourly forecast - Given a Postal Code.
#
# GET /forecast/hourly?postal_code={postal_code}
export def "forecast-hourly-postal-code-postal-code get" [
  postal_code: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --hours: int # Number of hours to return. (format: integer)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, clouds: int, datetime: string, dewpt: float, dhi: float, dni: float, ghi: float, pod: string, pop: float, precip: float, pres: float, rh: int, slp: float, snow: float, snow_depth: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_cdir: string, wind_cdir_full: string, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "hours" $hours "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/forecast/hourly?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns 72 hours of historical quality conditions - Given City and/or State, Country.
#
# GET /history/airquality?city={city}&country={country}
export def "history-airquality-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/history/airquality?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns 72 hours of historical air quality conditions - Given a City ID.
#
# GET /history/airquality?city_id={city_id}
export def "history-airquality-city-id-city-id get" [
  city_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/history/airquality?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns 72 hours of historical air quality conditions - Given a lat/lon.
#
# GET /history/airquality?lat={lat}&lon={lon}
export def "history-airquality-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/history/airquality?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns 72 hours of historical air quality conditions - Given a Postal Code.
#
# GET /history/airquality?postal_code={postal_code}
export def "history-airquality-postal-code-postal-code get" [
  postal_code: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --callback: string # Wraps return in jsonp callback. Example - callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<aqi: int, no2: float, o3: float, pm10: float, pm25: float, so2: float>, lat: string, lon: string, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/history/airquality?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given City and/or State, Country.
#
# GET /history/daily?city={city}&country={country}
export def "history-daily-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/history/daily?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a City ID
#
# GET /history/daily?city_id={city_id}
export def "history-daily-city-id-city-id get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/history/daily?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a lat/lon.
#
# GET /history/daily?lat={lat}&lon={lon}
export def "history-daily-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/history/daily?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a Postal Code
#
# GET /history/daily?postal_code={postal_code}
export def "history-daily-postal-code-postal-code get" [
  postal_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/history/daily?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a station ID.
#
# GET /history/daily?station={station}
export def "history-daily-station-station get" [
  station: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<datetime: string, dewpt: float, dhi: int, dni: int, ghi: int, max_temp: float, max_temp_ts: float, max_uv: float, max_wind_dir: int, max_wind_spd: float, max_wind_spd_ts: float, min_temp: float, min_temp_ts: float, precip: float, precip_gpm: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, snow_depth: float, t_dhi: int, t_dni: int, t_ghi: int, temp: float, ts: int, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({station: (encode-path-segment $station)} | format pattern "/history/daily?station={station}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Energy API response - Given a single lat/lon.
#
# GET /history/energy?lat={lat}&lon={lon}
export def "history-energy-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --tp: string@tp-completer-1 # Time period to aggregate by (daily, monthly) (format: string)
  --threshold: float # Temperature threshold to use to calculate degree days (default 18 C) (format: double)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<count: int, data: table<cdd: float, city_name: string, clouds: int, country_code: string, dewpt: float, hdd: float, lat: string, lon: string, precip: float, rh: int, snow: float, sources: list, state_code: string, station_id: string, sun_hours: float, t_dhi: float, t_dni: float, t_ghi: float, temp: float, timezone: string, wind_dir: int, wind_spd: float>, end_date: int, start_date: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "tp" $tp "scalar") (serialize-qp "threshold" $threshold "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/history/energy?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given City and/or State, Country.
#
# GET /history/hourly?city={city}&country={country}
export def "history-hourly-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/history/hourly?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a City ID
#
# GET /history/hourly?city_id={city_id}
export def "history-hourly-city-id-city-id get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/history/hourly?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a lat/lon.
#
# GET /history/hourly?lat={lat}&lon={lon}
export def "history-hourly-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/history/hourly?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a Postal Code
#
# GET /history/hourly?postal_code={postal_code}
export def "history-hourly-postal-code-postal-code get" [
  postal_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/history/hourly?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a station ID.
#
# GET /history/hourly?station={station}
export def "history-hourly-station-station get" [
  station: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({station: (encode-path-segment $station)} | format pattern "/history/hourly?station={station}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given City and/or State, Country.
#
# GET /history/subhourly?city={city}&country={country}
export def "history-subhourly-city-city-country-country get" [
  city: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # Full name of state. (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city: (encode-path-segment $city), country: (encode-path-segment $country)} | format pattern "/history/subhourly?city={city}&country={country}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a City ID
#
# GET /history/subhourly?city_id={city_id}
export def "history-subhourly-city-id-city-id get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/history/subhourly?city_id={city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a lat/lon.
#
# GET /history/subhourly?lat={lat}&lon={lon}
export def "history-subhourly-lat-lat-lon-lon get" [
  lat: float
  lon: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/history/subhourly?lat={lat}&lon={lon}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a Postal Code
#
# GET /history/subhourly?postal_code={postal_code}
export def "history-subhourly-postal-code-postal-code get" [
  postal_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country Code (2 letter). (format: string)
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH) (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postal_code: (encode-path-segment $postal_code)} | format pattern "/history/subhourly?postal_code={postal_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Historical Observations - Given a station ID.
#
# GET /history/subhourly?station={station}
export def "history-subhourly-station-station get" [
  station: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --end-date: string # End Date (YYYY-MM-DD or YYYY-MM-DD:HH). (format: string)
  --units: string@units-completer # Convert to units. Default Metric See units field description (format: string)
  --lang: string@lang-completer # Language (Default: English) See language field description (format: string)
  --tz: string@tz-completer # Assume utc (default) or local time for start_date, end_date (format: string)
  --callback: string # Wraps return in jsonp callback. Example: callback=func (format: string)
  --key: string # Your registered API key. (format: string)
]: nothing -> record<city_name: string, country_code: string, data: table<app_temp: float, azimuth: float, clouds: int, datetime: string, dewpt: int, dhi: float, dni: float, elev_angle: float, ghi: float, h_angle: float, pod: string, precip: float, pres: float, revision_status: string, rh: int, slp: float, snow: float, solar_rad: float, temp: float, timestamp_local: string, timestamp_utc: string, ts: float, uv: float, vis: float, weather: record, wind_dir: int, wind_gust_spd: float, wind_spd: float>, lat: string, lon: string, sources: list<string>, state_code: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "tz" $tz "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({station: (encode-path-segment $station)} | format pattern "/history/subhourly?station={station}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
