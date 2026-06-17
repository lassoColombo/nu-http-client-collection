# Auto-generated client for Netatmo v1.1.5
# Source: https://api.apis.guru/v2/specs/netatmo.net/1.1.5/openapi.json
# Auth: --token flag or $env.NETATMO_TOKEN

const BASE_URL = "https://api.netatmo.net/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NETATMO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.netatmo.net/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def app-type-completer [] { ["app_station" "app_thermostat"] }
def scale-completer [] { ["1day" "1hour" "1month" "1week" "30min" "3hours" "max"] }
def setpoint-mode-completer [] { ["away" "hg" "manual" "max" "off" "program"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addwebhook create-webhook" } } | get name | first)
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

# Links a callback url to a user.
#
# GET /addwebhook
# operationId: addwebhook
export def "addwebhook create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-url: string # Your webhook callback url
  --app-type: string # Webhooks are only available for Welcome, enter app_camera.
]: nothing -> record<status: string, time_exec: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "app_type" $app_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addwebhook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method createnewschedule creates a new schedule stored in the backup list.
#
# POST /createnewschedule
# operationId: createnewschedule
export def "createnewschedule create-newschedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id
  --module-id: string # The thermostat id
  --body: record
]: any -> record<body: record<schedule_id: string>, status: string, time_exec: float, time_server: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/createnewschedule" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# The method devicelist returns the list of devices owned by the user, and their modules. A device is identified by its _id (which is its mac address) and each device may have one, several or no modules, also identified by an _id.
#
# GET /devicelist
# DEPRECATED
# operationId: devicelist
@deprecated
export def "devicelist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-type: string@app-type-completer # Defines which device type will be returned by devicelist. It could be app_thermostat or app_station (by default if not provided)
  --device-id: string # Specify a device_id if you want to retrieve only this device informations.
  --get-favorites: oneof<nothing, bool> # When set to "true", the favorite devices of the user are returned. This flag is available only if the devices requested are Weather Stations. (default: false)
]: nothing -> record<body: record<devices: list<record>, modules: list<record>>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_type" $app_type "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "get_favorites" $get_favorites "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devicelist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dissociates a webhook from a user.
#
# GET /dropwebhook
# operationId: dropwebhook
export def "dropwebhook get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-type: string # For Welcome, use app_camera
]: nothing -> record<status: string, time_exec: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_type" $app_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dropwebhook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the snapshot associated to an event.
#
# GET /getcamerapicture
# operationId: getcamerapicture
export def "getcamerapicture get-camerapicture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-id: string # id of the image (can be retrieved as 'id' in 'face' in Gethomedata, or as 'id' in 'snapshot' in Getnextevents, Getlasteventof and Geteventsuntil)
  --key: string # Security key to access snapshots.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "image_id" $image_id "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getcamerapicture" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the snapshot associated to an event.
#
# GET /geteventsuntil
# operationId: geteventsuntil
export def "geteventsuntil get-eventsuntil" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in
  --event-id: string # Your request will retrieve all the events until this one
]: nothing -> record<body: record<events_list: list<record>>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "event_id" $event_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geteventsuntil" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method gethomecoachsdata Returns data from a user Healthy Home Coach Station (measures and device specific data).
#
# GET /gethomecoachsdata
# operationId: gethomecoachsdata
export def "gethomecoachsdata get-homecoachsdata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # Id of the device you want to retrieve information of
]: nothing -> record<body: record<devices: list<record>, user: record<_id: string, administrative: record, date_creation: record, devices: list, friend_devices: list, mail: string, timeline_not_read: int, timeline_size: int>>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gethomecoachsdata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about users homes and cameras.
#
# GET /gethomedata
# operationId: gethomedata
export def "gethomedata get-homedata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # Specify if you're looking for the events of a specific Home.
  --size: int # Number of events to retrieve. Default is `30`.
]: nothing -> record<body: record<global_info: record<show_tags: bool>, homes: list<record>, user: record<lang: string, reg_locale: string>>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gethomedata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns most recent events.
#
# GET /getlasteventof
# operationId: getlasteventof
export def "getlasteventof get-lasteventof" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in
  --person-id: string # Your request will retrieve all events of the given home until the most recent event of the given person
  --offset: int # Number of events to retrieve. Default is 30.
]: nothing -> record<body: record<events_list: list<record>>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "person_id" $person_id "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getlasteventof" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method getmeasure returns the measurements of a device or a module.
#
# GET /getmeasure
# operationId: getmeasure
export def "getmeasure get-measure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # Id of the device whose module's measurements you want to retrieve. This _id can be found in the user's devices field.
  --module-id: string # If you don't specify any module_id you will retrieve the device's measurements. If you specify a module_id you will retrieve the module's measurements.
  --scale: string@scale-completer # Defines the time interval between two measurements. Possible values : max -> every value stored will be returned 30min -> 1 value every 30 minutes 1hour -> 1 value every hour 3hours -> 1 value every 3 hours 1day -> 1 value per day 1week -> 1 value per week 1month -> 1 value per month
  --type: list # Measures you are interested in. Data you can request depends on the scale. **For Weather Station:**   * max -> Temperature (°C), CO2 (ppm), Humidity (%), Pressure (mbar), Noise (db), Rain (mm), WindStrength (km/h), WindAngle (angles), Guststrength (km/h), GustAngle (angles)   * 30min, 1hour, 3hours -> Same as above + min_temp, max_temp, min_hum, max_hum, min_pressure, max_pressure, min_noise, max_noise, sum_rain, date_max_gust   * 1day, 1week, 1month -> Same as above + date_min_temp, date_max_temp, date_min_hum, date_max_hum, date_min_pressure, date_max_pressure, date_min_noise, date_max_noise, date_min_co2, date_max_co2  **For Thermostat:**   * max -> temperature (°C), sp_temperature (°C), boileron (sec), boileroff (sec)   * 30min, 1hour, 3hours -> temperature, sp_temperature, min_temp, max_temp, sum_boiler_on, sum_boiler_off   * 1day, 1week, 1month -> temperature, min_temp, date_min_temp, max_temp, sum_boiler_on, sum_boiler_off
  --date-begin: int # Starting timestamp (utc) of the requested measurements. Please note measurement retrieving is limited to 1024 measurements.  (format: int32)
  --date-end: string # Ending timestamp (utc) of the request measurements. If you want only the last measurement, do not provide date_begin, and set date_end to `last`.
  --limit: int # Limits the number of measurements returned (default & max is 1024) (format: int32)
  --optimize: oneof<nothing, bool> # Allows you to choose the format of the answer. If you build a mobile app and bandwith usage is an issue, use `optimize = true`. Use `optimize = false`, for an easier parse. In this case, values are indexed by sorted timestamp. Example of un-optimized response : ```json {"status": "ok",    "body": {     "1347575400": [18.3,39],     "1347586200": [20.6,48]   }, "time_exec": 0.012136936187744} ``` If optimize is set true, measurements are returned as an array of series of regularly spaced measurements. Each series is defined by a beginning time beg_time and a step between measurements, step_time: ```json {"status": "ok",   "body": [     {"beg_time": 1347575400,      "step_time": 10800,      "value":          [[18.3,39],         [ 20.6,48]]     }], "time_exec": 0.014238119125366} ``` Default value is `true`.
  --real-time: oneof<nothing, bool> # In scales higher than max, since the data is aggregated, the timestamps returned are by default offset by +(scale/2). For instance, if you ask for measurements at a daily scale, you will receive data timestamped at 12:00 if real_time is set to `false` (default case), and timestamped at 00:00 if real_time is set to `true`. NB : The servers always store data with real_time set to `true` and data are offset by this parameter AFTER having being time-filtered, thus you could have data after date_end if real_time is set to `false`.
]: nothing -> record<body: table<beg_time: int, step_time: int, value: list>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar") (serialize-qp "scale" $scale "scalar") (serialize-qp "type" $type "csv") (serialize-qp "date_begin" $date_begin "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "optimize" $optimize "scalar") (serialize-qp "real_time" $real_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getmeasure" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns previous events.
#
# GET /getnextevents
# operationId: getnextevents
export def "getnextevents get-nextevents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in
  --event-id: string # Your request will retrieve events occured before this one
  --size: int # Number of events to retrieve. Default is 30.
]: nothing -> record<body: record<events_list: list<record>>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "event_id" $event_id "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getnextevents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves publicly shared weather data from Outdoor Modules within a predefined area.
#
# GET /getpublicdata
# operationId: getpublicdata
export def "getpublicdata get-publicdata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat-ne: int # Latitude of the north east corner of the requested area. -85 <= lat_ne <= 85 and lat_ne>lat_sw (format: int32)
  --lon-ne: int # Longitude of the north east corner of the requested area. -180 <= lon_ne <= 180 and lon_ne>lon_sw (format: int32)
  --lat-sw: int # Latitude of the south west corner of the requested area. -85 <= lat_sw <= 85 (format: int32)
  --lon-sw: int # Longitude of the south west corner of the requested area. -180 <= lon_sw <= 180 (format: int32)
  --required-data: list # To filter stations based on relevant measurements you want (e.g. rain will only return stations with rain gauges). Default is no filter. You can find all measurements available on the Thermostat page.
  --filter: oneof<nothing, bool> # True to exclude stations with abnormal temperature measures. Default is false.
]: nothing -> record<body: table<_id: string, mark: int, measures: record, module_types: record, modules: list, place: record>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat_ne" $lat_ne "scalar") (serialize-qp "lon_ne" $lon_ne "scalar") (serialize-qp "lat_sw" $lat_sw "scalar") (serialize-qp "lon_sw" $lon_sw "scalar") (serialize-qp "required_data" $required_data "csv") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getpublicdata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method getstationsdata Returns data from a user's Weather Stations (measures and device specific data).
#
# GET /getstationsdata
# operationId: getstationsdata
export def "getstationsdata get-stationsdata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # Id of the device you want to retrieve information of
  --get-favorites: oneof<nothing, bool> # Whether to include the user's favorite Weather Stations in addition to the user's own Weather Stations (default: false)
]: nothing -> record<body: record<devices: list<record>, user: record<_id: string, administrative: record, date_creation: record, devices: list, friend_devices: list, mail: string, timeline_not_read: int, timeline_size: int>>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "get_favorites" $get_favorites "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getstationsdata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method getthermostatsdata returns information about user's thermostats such as their last measurements.
#
# GET /getthermostatsdata
# operationId: getthermostatsdata
export def "getthermostatsdata get-thermostatsdata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # Id of the device you want to retrieve information of
]: nothing -> record<body: record<devices: list<record>, user: record<_id: string, administrative: record, date_creation: record, devices: list, friend_devices: list, mail: string, timeline_not_read: int, timeline_size: int>>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getthermostatsdata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method getthermstate returns the last Thermostat measurements, its current weekly schedule, and, if present, its current manual temperature setpoint.
#
# GET /getthermstate
# DEPRECATED
# operationId: getthermstate
@deprecated
export def "getthermstate get-thermstate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id
  --module-id: string # The thermostat id
]: nothing -> record<body: record<battery_percent: int, battery_vp: int, last_plug_seen: int, last_therm_seen: int, measured: record<setpoint_temp: float, temperature: float, time: int>, plug_connected_boiler: int, rf_status: int, setpoint: record<setpoint_endtime: int, setpoint_mode: string, setpoint_temp: float>, setpoint_order: record<setpoint_endtime: int, setpoint_mode: string, setpoint_temp: float>, therm_orientation: int, therm_program: record<name: string, program_id: string, selected: bool, timetable: list, zones: list>, therm_program_backup: list<record>, therm_program_order: record<name: string, program_id: string, selected: bool, timetable: list, zones: list>, therm_relay_cmd: int, udp_conn: bool, wifi_status: int>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getthermstate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method getuser returns information about a user such as prefered language, prefered units, and list of devices.
#
# GET /getuser
# DEPRECATED
# operationId: getuser
@deprecated
export def "getuser get-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: record<_id: string, administrative: record<country: string, feel_like_algo: string, lang: string, pressureunit: string, reg_locale: string, unit: string, windunit: string>, date_creation: record<sec: int, usec: int>, devices: list<string>, friend_devices: list<string>, mail: string, timeline_not_read: int, timeline_size: int>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getuser")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method partnerdevices returns the list of device_id to which your partner application has access to.
#
# GET /partnerdevices
# operationId: partnerdevices
export def "partnerdevices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: list<string>, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partnerdevices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets a person as 'Away' or the Home as 'Empty'. The event will be added to the user’s timeline.
#
# POST /setpersonsaway
# operationId: setpersonsaway
export def "setpersonsaway post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in
  --person-id: string # If a person_id is specified, that person will be set as 'Away'. If no person_id is specified, the Home will be set as 'Empty'.
]: nothing -> record<status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "person_id" $person_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setpersonsaway" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets a person as 'At home'.
#
# POST /setpersonshome
# operationId: setpersonshome
export def "setpersonshome post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --home-id: string # ID of the Home you're interested in
  --person-ids: string # List of persons IDs
]: nothing -> record<status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "home_id" $home_id "scalar") (serialize-qp "person_ids" $person_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setpersonshome" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method setthermpoint changes the Thermostat manual temperature setpoint.
#
# POST /setthermpoint
# operationId: setthermpoint
export def "setthermpoint post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id
  --module-id: string # The thermostat id
  --setpoint-mode: string@setpoint-mode-completer # Chosen setpoint_mode
  --setpoint-endtime: int # When using the manual or max setpoint_mode, this parameter defines when the setpoint expires. (format: int32)
  --setpoint-temp: float # When using the manual setpoint_mode, this parameter defines the temperature setpoint (in Celcius) to use. (format: float)
]: nothing -> record<body: string, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar") (serialize-qp "setpoint_mode" $setpoint_mode "scalar") (serialize-qp "setpoint_endtime" $setpoint_endtime "scalar") (serialize-qp "setpoint_temp" $setpoint_temp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setthermpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method switchschedule switches the Thermostat's schedule to another existing schedule.
#
# POST /switchschedule
# operationId: switchschedule
export def "switchschedule post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id
  --module-id: string # The thermostat id
  --schedule-id: string # The schedule id. It can be found in the getthermstate response, under the keys `therm_program_backup` and `therm_program`.
]: nothing -> record<body: string, status: string, time_exec: float, time_server: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar") (serialize-qp "schedule_id" $schedule_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/switchschedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The method syncschedule changes the Thermostat weekly schedule.
#
# POST /syncschedule
# operationId: syncschedule
export def "syncschedule sync-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-id: string # The relay id
  --module-id: string # The thermostat id
  --body: record
]: any -> record<body: string, status: string, time_exec: float, time_server: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "device_id" $device_id "scalar") (serialize-qp "module_id" $module_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/syncschedule" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}
