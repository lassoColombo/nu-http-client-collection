# Auto-generated client for Visual Crossing Weather API v4.6
# Source: https://api.apis.guru/v2/specs/visualcrossing.com/weather/4.6/openapi.json
# Auth: --token flag or $env.VISUAL_CROSSING_WEATHER_API_TOKEN

const BASE_URL = "https://weather.visualcrossing.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VISUAL_CROSSING_WEATHER_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://weather.visualcrossing.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "visual-crossing-web-services-rest-services-timeline get-by-location" } } | get name | first)
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

# Historical and Forecast Weather API
#
# GET /VisualCrossingWebServices/rest/services/timeline/{location}
export def "visual-crossing-web-services-rest-services-timeline get-by-location" [
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentType: string # data format of the output either json or CSV (e.g. json)
  --unitGroup: string # e.g. us
  --include: string # data to include in the output (required for CSV format - days,hours,alerts,current,events ) (e.g. days)
  --lang: string # Language to use for weather descriptions (e.g. us)
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  let qp = [(serialize-qp "contentType" $contentType "scalar") (serialize-qp "unitGroup" $unitGroup "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/VisualCrossingWebServices/rest/services/timeline/($location)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Historical and Forecast Weather API
#
# GET /VisualCrossingWebServices/rest/services/timeline/{location}/{startdate}
export def "visual-crossing-web-services-rest-services-timeline get-by-location-startdate" [
  location: string
  startdate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentType: string # data format of the output either json or CSV (e.g. json)
  --unitGroup: string # e.g. us
  --include: string # data to include in the output (required for CSV format - days,hours,alerts,current,events ) (e.g. days)
  --lang: string # Language to use for weather descriptions (e.g. us)
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  let qp = [(serialize-qp "contentType" $contentType "scalar") (serialize-qp "unitGroup" $unitGroup "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/VisualCrossingWebServices/rest/services/timeline/($location)/($startdate)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Historical and Forecast Weather API
#
# GET /VisualCrossingWebServices/rest/services/timeline/{location}/{startdate}/{enddate}
export def "visual-crossing-web-services-rest-services-timeline get-by-location-startdate-enddate" [
  location: string
  startdate: string
  enddate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentType: string # data format of the output either json or CSV (e.g. json)
  --unitGroup: string # e.g. us
  --include: string # data to include in the output (required for CSV format - days,hours,alerts,current,events ) (e.g. days)
  --lang: string # Language to use for weather descriptions (e.g. us)
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  let qp = [(serialize-qp "contentType" $contentType "scalar") (serialize-qp "unitGroup" $unitGroup "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/VisualCrossingWebServices/rest/services/timeline/($location)/($startdate)/($enddate)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Weather Forecast API
#
# GET /VisualCrossingWebServices/rest/services/weatherdata/forecast
export def "visual-crossing-web-services-rest-services-weatherdata-forecast get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sendAsDatasource: string@bool-completer # e.g. false
  --allowAsynch: string@bool-completer # e.g. false
  --shortColumnNames: string@bool-completer # e.g. false
  --locations: string # e.g. Sterling%2C%20VA%2C%20US
  --aggregateHours: string # e.g. 24
  --contentType: string # e.g. json
  --unitGroup: string # e.g. us
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  let qp = [(serialize-qp "sendAsDatasource" $sendAsDatasource "scalar") (serialize-qp "allowAsynch" $allowAsynch "scalar") (serialize-qp "shortColumnNames" $shortColumnNames "scalar") (serialize-qp "locations" $locations "scalar") (serialize-qp "aggregateHours" $aggregateHours "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "unitGroup" $unitGroup "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/VisualCrossingWebServices/rest/services/weatherdata/forecast" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves hourly or daily historical weather records.
#
# GET /VisualCrossingWebServices/rest/services/weatherdata/history
export def "visual-crossing-web-services-rest-services-weatherdata-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxDistance: string # e.g. -1
  --shortColumnNames: string@bool-completer # e.g. false
  --endDateTime: string # e.g. 2020-02-04T00%3A00%3A00
  --aggregateHours: string # e.g. 24
  --collectStationContributions: string@bool-completer # e.g. false
  --startDateTime: string # e.g. 2020-01-28T00%3A00%3A00
  --maxStations: string # e.g. -1
  --allowAsynch: string@bool-completer # e.g. false
  --locations: string # e.g. Sterling%2C%20VA%2C%20US
  --includeNormals: string@bool-completer # e.g. false
  --contentType: string # e.g. json
  --unitGroup: string # e.g. us
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  let qp = [(serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "shortColumnNames" $shortColumnNames "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "aggregateHours" $aggregateHours "scalar") (serialize-qp "collectStationContributions" $collectStationContributions "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "maxStations" $maxStations "scalar") (serialize-qp "allowAsynch" $allowAsynch "scalar") (serialize-qp "locations" $locations "scalar") (serialize-qp "includeNormals" $includeNormals "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "unitGroup" $unitGroup "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/VisualCrossingWebServices/rest/services/weatherdata/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
