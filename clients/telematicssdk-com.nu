# Auto-generated client for Quick start - Telematics SDK v1.0.0
# Source: https://api.apis.guru/v2/specs/telematicssdk.com/1.0.0/openapi.json
# Auth: --token flag or $env.QUICK_START_TELEMATICS_SDK_TOKEN

const BASE_URL = "https://api.telematicssdk.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o QUICK_START_TELEMATICS_SDK_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.telematicssdk.com" "https://mobilesdk.telematicssdk.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "mobilesdk-stage-track-get-track get-trips-trip-details" } } | get name | first)
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

# Trips - trip details
#
# GET /mobilesdk/stage/track/get_track/v1
# operationId: tripsTripDetails
export def "mobilesdk-stage-track-get-track get-trips-trip-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --track-token: string # e.g. 
]: nothing -> record<Result: record<Code: float, Track: record<AccelerationCount: float, AddressEnd: string, AddressFinishParts: record, AddressStart: string, AddressStartParts: record, BeaconId: float, CityFinish: string, CityStart: string, DecelerationCount: float, Distance: float, DrivingTips: string, Duration: float, EcoScore: float, EcoScoreBrakes: float, EcoScoreDepreciation: float, EcoScoreFuel: float, EcoScoreTyres: float, EndDate: string, HighOverSpeedMileage: float, MidOverSpeedMileage: float, OriginChanged: bool, PhoneUsage: float, Points: list, Rating: float, Rating100: float, RatingAcceleration: float, RatingAcceleration100: float, RatingBraking: float, RatingBraking100: float, RatingCornering: float, RatingCornering100: float, RatingPhoneDistraction100: float, RatingPhoneUsage: float, RatingSpeeding: float, RatingSpeeding100: float, RatingTimeOfDay: float, ShareType: string, StartDate: string, Status: string, TrackOriginCode: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trackToken" $track_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mobilesdk/stage/track/get_track/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# /v1/Scorings/consolidated
#
# GET /statistics/v1/Scorings/consolidated
# operationId: /v1/scorings/consolidated
export def "statistics-scorings-consolidated get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-token: string # e.g. 
  --start-date: string # e.g. 2021-01-17T01:04:22.840Z
  --end-date: string # e.g. 2021-01-18T01:04:22.840Z
  --tag: string # e.g. 
  --instance-id: string # e.g. 
  --app-id: string # e.g. 
  --company-id: string # e.g. 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeviceToken" $device_token "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Tag" $tag "scalar") (serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "AppId" $app_id "scalar") (serialize-qp "CompanyId" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Scorings/consolidated" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# /v1/Scorings/consolidated/daily
#
# GET /statistics/v1/Scorings/consolidated/daily
# operationId: /v1/scorings/consolidated/daily
export def "statistics-scorings-consolidated-daily get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-token: string # e.g. 
  --start-date: string # e.g. 2021-01-17T01:04:22.840Z
  --end-date: string # e.g. 2021-01-18T01:04:22.840Z
  --tag: string # e.g. 
  --instance-id: string # e.g. 
  --app-id: string # e.g. 
  --company-id: string # e.g. 
]: nothing -> record<Errors: list<any>, Result: table<AccelerationScore: float, AppId: string, BrakingScore: float, CompanyId: string, CorneringScore: float, DeviceToken: string, DistractedScore: float, InstanceId: string, OverallScore: float, ReportDate: string, SpeedingScore: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeviceToken" $device_token "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Tag" $tag "scalar") (serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "AppId" $app_id "scalar") (serialize-qp "CompanyId" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Scorings/consolidated/daily" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# User safe scoring - Accumulated value - v1/Scorings/individual
#
# GET /statistics/v1/Scorings/individual/
# operationId: userSafeScoringAccumulatedValueV1/scorings/individual
export def "statistics-scorings-individual get-user-safe-accumulated-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # e.g. 2021-01-01
  --end-date: string # e.g. 2021-01-30
]: nothing -> record<Errors: list<any>, Result: record<AccelerationScore: float, AppId: string, BrakingScore: float, CompanyId: string, CorneringScore: float, DeviceToken: string, DistractedScore: float, InstanceId: string, OverallScore: float, SpeedingScore: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Scorings/individual/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# User safe scoring - daily value - /v1/Scorings/individual/daily
#
# GET /statistics/v1/Scorings/individual/daily
# operationId: userSafeScoringDailyValue/v1/scorings/individual/daily
export def "statistics-scorings-individual-daily get-user-safe-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Optional (e.g. )
  --start-date: string # (Required) (e.g. 2021-01-01)
  --end-date: string # (Required) (e.g. 2021-01-20)
]: nothing -> record<Errors: list<any>, Result: table<AccelerationScore: float, AppId: string, BrakingScore: float, CalcDate: string, CompanyId: string, CorneringScore: float, DeviceToken: string, DistractedScore: float, InstanceId: string, OverallScore: float, SpeedingScore: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Tag" $tag "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Scorings/individual/daily" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# /v1/Statistics/consolidated
#
# GET /statistics/v1/Statistics/consolidated
# operationId: /v1/statistics/consolidated
export def "statistics-statistics-consolidated get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-token: string # e.g. 
  --start-date: string # e.g. 2021-01-18
  --end-date: string # e.g. 2021-03-18
  --tag: string # e.g. 
  --instance-id: string # e.g. 
  --app-id: string # e.g. 
  --company-id: string # e.g. 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeviceToken" $device_token "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Tag" $tag "scalar") (serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "AppId" $app_id "scalar") (serialize-qp "CompanyId" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Statistics/consolidated" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# /v1/Statistics/consolidated/daily
#
# GET /statistics/v1/Statistics/consolidated/daily
# operationId: /v1/statistics/consolidated/daily
export def "statistics-statistics-consolidated-daily get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-token: string # e.g. 
  --start-date: string # e.g. 2021-01-17
  --end-date: string # e.g. 2021-01-18
  --tag: string # e.g. 
  --instance-id: string # e.g. 
  --app-id: string # e.g. 
  --company-id: string # e.g. 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeviceToken" $device_token "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "Tag" $tag "scalar") (serialize-qp "InstanceId" $instance_id "scalar") (serialize-qp "AppId" $app_id "scalar") (serialize-qp "CompanyId" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Statistics/consolidated/daily" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# User statistics - Accumulated value - /v1/Statistics/individual
#
# GET /statistics/v1/Statistics/individual/
# operationId: userStatisticsAccumulatedValue/v1/statistics/individual
export def "statistics-statistics-individual get-user-accumulated-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # e.g. 2021-01-01
  --end-date: string # e.g. 2021-01-30
]: nothing -> record<Errors: list<any>, Result: record<AccelerationCount: float, AppId: string, AverageSpeedKmh: float, AverageSpeedMileh: float, BreakingCount: float, CompanyId: string, CorneringCount: float, DayDrivingTime: float, DeviceToken: string, DriverTripsCount: float, DrivingTime: float, InstanceId: string, MaxSpeedKmh: float, MaxSpeedMileh: float, MileageKm: float, MileageMile: float, NightDrivingTime: float, OtherTripsCount: float, PhoneUsageDistanceKm: float, PhoneUsageDistanceMile: float, PhoneUsageDurationMin: float, PhoneUsageOverSpeedDistanceKm: float, PhoneUsageOverSpeedDistanceMile: float, PhoneUsageOverSpeedDurationMin: float, RushHoursDrivingTime: float, TotalSpeedingKm: float, TotalSpeedingMile: float, TripsCount: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Statistics/individual/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# User statistice - Daily value - v1/Statistics/individual/daily
#
# GET /statistics/v1/Statistics/individual/daily/
# operationId: userStatisticeDailyValueV1/statistics/individual/daily
export def "statistics-statistics-individual-daily get-user-statistice-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # e.g. 2021-03-30
  --end-date: string # e.g. 2021-03-30
]: nothing -> record<Errors: list<any>, Result: table<AccelerationCount: float, AppId: string, AverageSpeedKmh: float, AverageSpeedMileh: float, BreakingCount: float, CompanyId: string, CorneringCount: float, DayDrivingTime: float, DeviceToken: string, DriverTripsCount: float, DrivingTime: float, InstanceId: string, MaxSpeedKmh: float, MaxSpeedMileh: float, MileageKm: float, MileageMile: float, NightDrivingTime: float, OtherTripsCount: float, PhoneUsageDistanceKm: float, PhoneUsageDistanceMile: float, PhoneUsageDurationMin: float, PhoneUsageOverSpeedDistanceKm: float, PhoneUsageOverSpeedDistanceMile: float, PhoneUsageOverSpeedDurationMin: float, ReportDate: string, RushHoursDrivingTime: float, TotalSpeedingKm: float, TotalSpeedingMile: float, TripsCount: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Statistics/individual/daily/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
