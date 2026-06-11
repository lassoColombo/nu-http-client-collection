# Auto-generated client for weather.gov API v3.9.2
# Source: https://api.weather.gov/openapi.json
# Auth: --token flag or $env.WEATHER_GOV_API_TOKEN

const BASE_URL = "https://api.weather.gov"
const DEFAULT_AUTH = "user-agent"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEATHER_GOV_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "user-agent" => { {headers: {User-Agent: $token_val}, query: ""} }
    "api-key" => { {headers: {API-Key: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://api.weather.gov"] }
def auth-scheme-completer [] { ["user-agent" "api-key"] }

# Completers for enum parameters
def region-type-completer [] { ["land" "marine"] }
def accept-completer [] { ["application/cap+xml" "application/geo+json" "application/ld+json"] }
def accept-completer-1 [] { ["application/geo+json" "application/vnd.noaa.uswx+xml"] }
def accept-completer-2 [] { ["application/geo+json" "application/ld+json"] }
def units-completer [] { ["si" "us"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alerts query" } } | get name | first)
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

# Returns all alerts
#
# GET /alerts
# operationId: alerts_query
@deprecated --flag active
export def "alerts query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # List only active alerts (use /alerts/active endpoints instead) (DEPRECATED)
  --start: string # Start time (format: date-time)
  --end: string # End time (format: date-time)
  --status: list # Status (actual, exercise, system, test, draft)
  --message-type: list # Message type (alert, update, cancel)
  --event: list # Event name
  --code: list # Event code
  --area: list # State/territory code or marine area code This parameter is incompatible with the following parameters: point, region, region_type, zone
  --point: string # Point (latitude,longitude) This parameter is incompatible with the following parameters: area, region, region_type, zone
  --region: list # Marine region code This parameter is incompatible with the following parameters: area, point, region_type, zone
  --region-type: string@region-type-completer # Region type (land or marine) This parameter is incompatible with the following parameters: area, point, region, zone
  --zone: list # Zone ID (forecast or county) This parameter is incompatible with the following parameters: area, point, region, region_type
  --urgency: list # Urgency (immediate, expected, future, past, unknown)
  --severity: list # Severity (extreme, severe, moderate, minor, unknown)
  --certainty: list # Certainty (observed, likely, possible, unlikely, unknown)
  --limit: int # Limit (default: 500)
  --cursor: string # Pagination cursor
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "status" $status "csv") (serialize-qp "message_type" $message_type "csv") (serialize-qp "event" $event "csv") (serialize-qp "code" $code "csv") (serialize-qp "area" $area "csv") (serialize-qp "point" $point "scalar") (serialize-qp "region" $region "csv") (serialize-qp "region_type" $region_type "scalar") (serialize-qp "zone" $zone "csv") (serialize-qp "urgency" $urgency "csv") (serialize-qp "severity" $severity "csv") (serialize-qp "certainty" $certainty "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all currently active alerts
#
# GET /alerts/active
# operationId: alerts_active
export def "alerts-active active" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list # Status (actual, exercise, system, test, draft)
  --message-type: list # Message type (alert, update, cancel)
  --event: list # Event name
  --code: list # Event code
  --area: list # State/territory code or marine area code This parameter is incompatible with the following parameters: point, region, region_type, zone
  --point: string # Point (latitude,longitude) This parameter is incompatible with the following parameters: area, region, region_type, zone
  --region: list # Marine region code This parameter is incompatible with the following parameters: area, point, region_type, zone
  --region-type: string@region-type-completer # Region type (land or marine) This parameter is incompatible with the following parameters: area, point, region, zone
  --zone: list # Zone ID (forecast or county) This parameter is incompatible with the following parameters: area, point, region, region_type
  --urgency: list # Urgency (immediate, expected, future, past, unknown)
  --severity: list # Severity (extreme, severe, moderate, minor, unknown)
  --certainty: list # Certainty (observed, likely, possible, unlikely, unknown)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "csv") (serialize-qp "message_type" $message_type "csv") (serialize-qp "event" $event "csv") (serialize-qp "code" $code "csv") (serialize-qp "area" $area "csv") (serialize-qp "point" $point "scalar") (serialize-qp "region" $region "csv") (serialize-qp "region_type" $region_type "scalar") (serialize-qp "zone" $zone "csv") (serialize-qp "urgency" $urgency "csv") (serialize-qp "severity" $severity "csv") (serialize-qp "certainty" $certainty "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns info on the number of active alerts
#
# GET /alerts/active/count
# operationId: alerts_active_count
export def "alerts-active-count count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/active/count")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns active alerts for the given NWS public zone or county
#
# GET /alerts/active/zone/{zoneId}
# operationId: alerts_active_zone
export def "alerts-active-zone zone" [
  zoneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/active/zone/($zoneId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns active alerts for the given area (state or marine area)
#
# GET /alerts/active/area/{area}
# operationId: alerts_active_area
export def "alerts-active-area area" [
  area: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/active/area/($area)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns active alerts for the given marine region
#
# GET /alerts/active/region/{region}
# operationId: alerts_active_region
export def "alerts-active-region region" [
  region: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/active/region/($region)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of alert types
#
# GET /alerts/types
# operationId: alerts_types
export def "alerts-types types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/types")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a specific alert
#
# GET /alerts/{id}
# operationId: alerts_single
export def "alerts single" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)")
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a Center Weather Service Unit
#
# GET /aviation/cwsus/{cwsuId}
# operationId: cwsu
export def "aviation-cwsus cwsu" [
  cwsuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aviation/cwsus/($cwsuId)")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of Center Weather Advisories from a CWSU
#
# GET /aviation/cwsus/{cwsuId}/cwas
# operationId: cwas
export def "aviation-cwsus-cwas cwas" [
  cwsuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aviation/cwsus/($cwsuId)/cwas")
  let accept_val = "application/geo+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of Center Weather Advisories from a CWSU
#
# GET /aviation/cwsus/{cwsuId}/cwas/{date}/{sequence}
# operationId: cwa
export def "aviation-cwsus-cwas cwa" [
  cwsuId: string
  date: string
  sequence: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aviation/cwsus/($cwsuId)/cwas/($date)/($sequence)")
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of SIGMET/AIRMETs
#
# GET /aviation/sigmets
# operationId: sigmetQuery
export def "aviation-sigmets sigmetQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Start time (format: date-time)
  --end: string # End time (format: date-time)
  --date: string # Date (YYYY-MM-DD format) (format: date)
  --atsu: string # ATSU identifier
  --sequence: string # SIGMET sequence number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "atsu" $atsu "scalar") (serialize-qp "sequence" $sequence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aviation/sigmets" $qp)
  let accept_val = "application/geo+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of SIGMET/AIRMETs for the specified ATSU
#
# GET /aviation/sigmets/{atsu}
# operationId: sigmetsByATSU
export def "aviation-sigmets sigmetsByATSU" [
  atsu: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aviation/sigmets/($atsu)")
  let accept_val = "application/geo+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of SIGMET/AIRMETs for the specified ATSU for the specified date
#
# GET /aviation/sigmets/{atsu}/{date}
# operationId: sigmetsByATSUByDate
export def "aviation-sigmets sigmetsByATSUByDate" [
  atsu: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aviation/sigmets/($atsu)/($date)")
  let accept_val = "application/geo+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a specific SIGMET/AIRMET
#
# GET /aviation/sigmets/{atsu}/{date}/{time}
# operationId: sigmet
export def "aviation-sigmets sigmet" [
  atsu: string
  date: string
  time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aviation/sigmets/($atsu)/($date)/($time)")
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns glossary terms
#
# GET /glossary
# operationId: glossary
export def "glossary glossary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/glossary")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns raw numerical forecast data for a 2.5km grid area
#
# GET /gridpoints/{wfo}/{x},{y}
# operationId: gridpoint
export def "gridpoints gridpoint" [
  wfo: string
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gridpoints/($wfo)/($x),($y)")
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a textual forecast for a 2.5km grid area
#
# GET /gridpoints/{wfo}/{x},{y}/forecast
# operationId: gridpoint_forecast
export def "gridpoints-forecast forecast" [
  wfo: any
  x: any
  y: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --units: string@units-completer # Use US customary or SI (metric) units in textual output (default: us)
  --Feature-Flags: list # Enable future and experimental features (see documentation for more info): * forecast_temperature_qv: Represent temperature as QuantitativeValue * forecast_wind_speed_qv: Represent wind speed as QuantitativeValue
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "units" $units "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/gridpoints/($wfo)/($x),($y)/forecast" $qp)
  let extra_headers = {"Feature-Flags": $Feature_Flags} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a textual hourly forecast for a 2.5km grid area
#
# GET /gridpoints/{wfo}/{x},{y}/forecast/hourly
# operationId: gridpoint_forecast_hourly
export def "gridpoints-forecast-hourly hourly" [
  wfo: any
  x: any
  y: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --units: string@units-completer # Use US customary or SI (metric) units in textual output (default: us)
  --Feature-Flags: list # Enable future and experimental features (see documentation for more info): * forecast_temperature_qv: Represent temperature as QuantitativeValue * forecast_wind_speed_qv: Represent wind speed as QuantitativeValue
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "units" $units "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/gridpoints/($wfo)/($x),($y)/forecast/hourly" $qp)
  let extra_headers = {"Feature-Flags": $Feature_Flags} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of observation stations usable for a given 2.5km grid area
#
# GET /gridpoints/{wfo}/{x},{y}/stations
# operationId: gridpoint_stations
export def "gridpoints-stations stations" [
  wfo: string
  x: int
  y: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit (default: 500)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/gridpoints/($wfo)/($x),($y)/stations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a forecast icon. Icon services in API are deprecated.
#
# GET /icons/{set}/{timeOfDay}/{first}
# DEPRECATED
# operationId: icons
@deprecated
export def "icons icons" [
  set: string
  timeOfDay: string
  first: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: string # Font size
  --fontsize: int # Font size
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "fontsize" $fontsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/icons/($set)/($timeOfDay)/($first)" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a forecast icon. Icon services in API are deprecated.
#
# GET /icons/{set}/{timeOfDay}/{first}/{second}
# DEPRECATED
# operationId: iconsDualCondition
@deprecated
export def "icons iconsDualCondition" [
  set: string
  timeOfDay: string
  first: string
  second: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: string # Font size
  --fontsize: int # Font size
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "fontsize" $fontsize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/icons/($set)/($timeOfDay)/($first)/($second)" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of icon codes and textual descriptions. Icon services in API are deprecated.
#
# GET /icons
# DEPRECATED
# operationId: icons_summary
@deprecated
export def "icons summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/icons")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a thumbnail image for a satellite region. Image services in API are deprecated.
#
# GET /thumbnails/satellite/{area}
# DEPRECATED
# operationId: satellite_thumbnails
@deprecated
export def "thumbnails-satellite thumbnails" [
  area: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/thumbnails/satellite/($area)")
  let accept_val = "image/jpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of observations for a given station
#
# GET /stations/{stationId}/observations
# operationId: station_observation_list
export def "stations-observations list" [
  stationId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Start time (format: date-time)
  --end: string # End time (format: date-time)
  --cursor: string # Pagination cursor
  --limit: int # Limit
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stations/($stationId)/observations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the latest observation for a station
#
# GET /stations/{stationId}/observations/latest
# operationId: station_observation_latest
export def "stations-observations-latest latest" [
  stationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --require-qc: string@bool-completer # Require QC
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "require_qc" $require_qc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/stations/($stationId)/observations/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a single observation.
#
# GET /stations/{stationId}/observations/{time}
# operationId: station_observation_time
export def "stations-observations time" [
  stationId: string
  time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stations/($stationId)/observations/($time)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns Terminal Aerodrome Forecasts for the specified airport station.
#
# GET /stations/{stationId}/tafs
# operationId: tafs
export def "stations-tafs tafs" [
  stationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stations/($stationId)/tafs")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a single Terminal Aerodrome Forecast.
#
# GET /stations/{stationId}/tafs/{date}/{time}
# operationId: taf
export def "stations-tafs taf" [
  stationId: string
  date: string
  time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stations/($stationId)/tafs/($date)/($time)")
  let accept_val = "application/vnd.wmo.iwxxm+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of observation stations.
#
# GET /stations
# operationId: obs_stations
export def "stations stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: list # Filter by observation station ID
  --state: list # Filter by state/marine area code
  --limit: int # Limit (default: 500)
  --cursor: string # Pagination cursor
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "state" $state "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a given observation station
#
# GET /stations/{stationId}
# operationId: obs_station
export def "stations station" [
  stationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stations/($stationId)")
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a NWS forecast office
#
# GET /offices/{officeId}
# operationId: office
export def "offices office" [
  officeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offices/($officeId)")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns active briefing for an NWS office
#
# GET /offices/{officeId}/briefing
# operationId: office_briefing
export def "offices-briefing briefing" [
  officeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offices/($officeId)/briefing")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the latest briefing for an office
#
# GET /offices/{officeId}/briefing/download/latest
# operationId: office_briefing_download_latest
export def "offices-briefing-download-latest latest" [
  officeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offices/($officeId)/briefing/download/latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a briefing for an office
#
# GET /offices/{officeId}/briefing/download/{briefingId}
# operationId: office_briefing_download
export def "offices-briefing-download download" [
  officeId: string
  briefingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offices/($officeId)/briefing/download/($briefingId)")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a specific news headline for a given NWS office
#
# GET /offices/{officeId}/headlines/{headlineId}
# operationId: office_headline
export def "offices-headlines headline" [
  officeId: string
  headlineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offices/($officeId)/headlines/($headlineId)")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of news headlines for a given NWS office
#
# GET /offices/{officeId}/headlines
# operationId: office_headlines
export def "offices-headlines headlines" [
  officeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offices/($officeId)/headlines")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns active weather stories for an NWS office
#
# GET /offices/{officeId}/weatherstories
# operationId: office_weatherstory
export def "offices-weatherstories weatherstory" [
  officeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offices/($officeId)/weatherstories")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the image for a weather story
#
# GET /offices/{officeId}/weatherstories/download/{imageId}
# operationId: office_weatherstory_image
export def "offices-weatherstories-download image" [
  officeId: string
  imageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/offices/($officeId)/weatherstories/download/($imageId)")
  let accept_val = "image/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a given latitude/longitude point
#
# GET /points/{latitude},{longitude}
# operationId: point
export def "points point" [
  latitude: float
  longitude: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/points/($latitude),($longitude)")
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns NOAA Weather Radio broadcast script for a latitude/longitude point
#
# GET /points/{latitude},{longitude}/radio
# Docs: https://www.w3.org/TR/speech-synthesis/
# operationId: point_radio
export def "points-radio radio" [
  latitude: float
  longitude: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/points/($latitude),($longitude)/radio")
  let accept_val = "application/ssml+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of observation stations for a given point
#
# GET /points/{latitude},{longitude}/stations
# DEPRECATED
# operationId: point_stations
@deprecated
export def "points-stations stations" [
  latitude: float
  longitude: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/points/($latitude),($longitude)/stations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of radar servers
#
# GET /radar/servers
# operationId: radar_servers
export def "radar-servers servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reportingHost: string # Show records from specific reporting host
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportingHost" $reportingHost "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/radar/servers" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a given radar server
#
# GET /radar/servers/{id}
# operationId: radar_server
export def "radar-servers server" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reportingHost: string # Show records from specific reporting host
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportingHost" $reportingHost "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/radar/servers/($id)" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of radar spgds
#
# GET /radar/spgds
# operationId: radar_spgds
export def "radar-spgds spgds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --published: string # Range for publish time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "published" $published "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/radar/spgds" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of radar stations
#
# GET /radar/stations
# operationId: radar_stations
export def "radar-stations stations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --stationType: list # Limit results to a specific station type or types
  --reportingHost: string # Show RDA and latency info from specific reporting host
  --host: string # Show latency info from specific LDM host
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stationType" $stationType "csv") (serialize-qp "reportingHost" $reportingHost "scalar") (serialize-qp "host" $host "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/radar/stations" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a given radar station
#
# GET /radar/stations/{stationId}
# operationId: radar_station
export def "radar-stations station" [
  stationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --reportingHost: string # Show RDA and latency info from specific reporting host
  --host: string # Show latency info from specific LDM host
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportingHost" $reportingHost "scalar") (serialize-qp "host" $host "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/radar/stations/($stationId)" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a given radar station alarms
#
# GET /radar/stations/{stationId}/alarms
# operationId: radar_station_alarms
export def "radar-stations-alarms alarms" [
  stationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/radar/stations/($stationId)/alarms")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a given radar queue
#
# GET /radar/queues/{host}
# operationId: radar_queue
export def "radar-queues queue" [
  host: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Record limit
  --arrived: string # Range for arrival time
  --created: string # Range for creation time
  --published: string # Range for publish time
  --station: string # Station identifier
  --type: string # Record type
  --feed: string # Originating product feed
  --resolution: int # Resolution version
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "arrived" $arrived "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "published" $published "scalar") (serialize-qp "station" $station "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "feed" $feed "scalar") (serialize-qp "resolution" $resolution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/radar/queues/($host)" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a given radar wind profiler
#
# GET /radar/profilers/{stationId}
# operationId: radar_profiler
export def "radar-profilers profiler" [
  stationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time: string # Time interval
  --interval: string # Averaging interval
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/radar/profilers/($stationId)" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns NOAA Weather Radio broadcast script for a transmitter
#
# GET /radio/{callSign}/broadcast
# Docs: https://www.w3.org/TR/speech-synthesis/
# operationId: area_radio
export def "radio-broadcast radio" [
  callSign: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/radio/($callSign)/broadcast")
  let accept_val = "application/ssml+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of text products
#
# GET /products
# operationId: products_query
export def "products query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: list # Location id
  --start: string # Start time (format: date-time)
  --end: string # End time (format: date-time)
  --office: list # Issuing office
  --wmoid: list # WMO id code
  --type: list # Product code
  --limit: int # Limit
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "csv") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "office" $office "csv") (serialize-qp "wmoid" $wmoid "csv") (serialize-qp "type" $type "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp)
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of valid text product issuance locations
#
# GET /products/locations
# operationId: product_locations
export def "products-locations locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products/locations")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of valid text product types and codes
#
# GET /products/types
# operationId: product_types
export def "products-types types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products/types")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a specific text product
#
# GET /products/{productId}
# operationId: product
export def "products product" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($productId)")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of text products of a given type
#
# GET /products/types/{typeId}
# operationId: products_type
export def "products-types type" [
  typeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/types/($typeId)")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of valid text product issuance locations for a given product type
#
# GET /products/types/{typeId}/locations
# operationId: products_type_locations
export def "products-types-locations locations" [
  typeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/types/($typeId)/locations")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of valid text product types for a given issuance location
#
# GET /products/locations/{locationId}/types
# operationId: location_products
export def "products-locations-types products" [
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/locations/($locationId)/types")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of text products of a given type for a given issuance location
#
# GET /products/types/{typeId}/locations/{locationId}
# operationId: products_type_location
export def "products-types-locations location" [
  typeId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/types/($typeId)/locations/($locationId)")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns latest text products of a given type for a given issuance location with product text
#
# GET /products/types/{typeId}/locations/{locationId}/latest
# operationId: latest_product_type_location
export def "products-types-locations-latest location" [
  typeId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/types/($typeId)/locations/($locationId)/latest")
  let accept_val = "application/ld+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of zones
#
# GET /zones
# operationId: zone_list
export def "zones list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --id: list # Zone ID (forecast or county)
  --area: list # State/marine area code
  --region: list # Region code
  --type: list # Zone type
  --point: string # Point (latitude,longitude)
  --include-geometry: string@bool-completer # Include geometry in results (true/false)
  --limit: int # Limit
  --effective: string # Effective date/time (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "area" $area "csv") (serialize-qp "region" $region "csv") (serialize-qp "type" $type "csv") (serialize-qp "point" $point "scalar") (serialize-qp "include_geometry" $include_geometry "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "effective" $effective "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/zones" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of zones of a given type
#
# GET /zones/{type}
# operationId: zone_list_type
export def "zones type" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --id: list # Zone ID (forecast or county)
  --area: list # State/marine area code
  --region: list # Region code
  --type: list # Zone type
  --point: string # Point (latitude,longitude)
  --include-geometry: string@bool-completer # Include geometry in results (true/false)
  --limit: int # Limit
  --effective: string # Effective date/time (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "area" $area "csv") (serialize-qp "region" $region "csv") (serialize-qp "type" $type "csv") (serialize-qp "point" $point "scalar") (serialize-qp "include_geometry" $include_geometry "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "effective" $effective "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($type)" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata about a given zone
#
# GET /zones/{type}/{zoneId}
# operationId: zone
export def "zones zone" [
  type: string
  zoneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --effective: string # Effective date/time (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "effective" $effective "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/($type)/($zoneId)" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the current zone forecast for a given zone
#
# GET /zones/{type}/{zoneId}/forecast
# operationId: zone_forecast
export def "zones-forecast forecast" [
  type: string
  zoneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/zones/($type)/($zoneId)/forecast")
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of observations for a given zone
#
# GET /zones/forecast/{zoneId}/observations
# operationId: zone_obs
export def "zones-forecast-observations obs" [
  zoneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --start: string # Start date/time (format: date-time)
  --end: string # End date/time (format: date-time)
  --limit: int # Limit
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/forecast/($zoneId)/observations" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of observation stations for a given zone
#
# GET /zones/forecast/{zoneId}/stations
# operationId: zone_stations
export def "zones-forecast-stations stations" [
  zoneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit (default: 500)
  --cursor: string # Pagination cursor
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user-agent"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/zones/forecast/($zoneId)/stations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
