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

def base-url-completer [] { ["https://api.telematicssdk.com" "https://mobilesdk.telematicssdk.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "mobilesdk-stage-track-get-track tripsTripDetails" } } | get name | first)
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
export def "mobilesdk-stage-track-get-track tripsTripDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trackToken: string # e.g. 
]: nothing -> record<Result: record<Code: float, Track: record<AccelerationCount: float, AddressEnd: string, AddressFinishParts: record, AddressStart: string, AddressStartParts: record, BeaconId: float, CityFinish: string, CityStart: string, DecelerationCount: float, Distance: float, DrivingTips: string, Duration: float, EcoScore: float, EcoScoreBrakes: float, EcoScoreDepreciation: float, EcoScoreFuel: float, EcoScoreTyres: float, EndDate: string, HighOverSpeedMileage: float, MidOverSpeedMileage: float, OriginChanged: bool, PhoneUsage: float, Points: list, Rating: float, Rating100: float, RatingAcceleration: float, RatingAcceleration100: float, RatingBraking: float, RatingBraking100: float, RatingCornering: float, RatingCornering100: float, RatingPhoneDistraction100: float, RatingPhoneUsage: float, RatingSpeeding: float, RatingSpeeding100: float, RatingTimeOfDay: float, ShareType: string, StartDate: string, Status: string, TrackOriginCode: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trackToken" $trackToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mobilesdk/stage/track/get_track/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /v1/Scorings/consolidated
#
# GET /statistics/v1/Scorings/consolidated
# operationId: /v1/scorings/consolidated
export def "statistics-scorings-consolidated /v1/scorings/consolidated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceToken: string # e.g. 
  --StartDate: string # e.g. 2021-01-17T01:04:22.840Z
  --EndDate: string # e.g. 2021-01-18T01:04:22.840Z
  --Tag: string # e.g. 
  --InstanceId: string # e.g. 
  --AppId: string # e.g. 
  --CompanyId: string # e.g. 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeviceToken" $DeviceToken "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Tag" $Tag "scalar") (serialize-qp "InstanceId" $InstanceId "scalar") (serialize-qp "AppId" $AppId "scalar") (serialize-qp "CompanyId" $CompanyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Scorings/consolidated" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /v1/Scorings/consolidated/daily
#
# GET /statistics/v1/Scorings/consolidated/daily
# operationId: /v1/scorings/consolidated/daily
export def "statistics-scorings-consolidated-daily /v1/scorings/consolidated/daily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceToken: string # e.g. 
  --StartDate: string # e.g. 2021-01-17T01:04:22.840Z
  --EndDate: string # e.g. 2021-01-18T01:04:22.840Z
  --Tag: string # e.g. 
  --InstanceId: string # e.g. 
  --AppId: string # e.g. 
  --CompanyId: string # e.g. 
]: nothing -> record<Errors: list<any>, Result: table<AccelerationScore: float, AppId: string, BrakingScore: float, CompanyId: string, CorneringScore: float, DeviceToken: string, DistractedScore: float, InstanceId: string, OverallScore: float, ReportDate: string, SpeedingScore: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeviceToken" $DeviceToken "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Tag" $Tag "scalar") (serialize-qp "InstanceId" $InstanceId "scalar") (serialize-qp "AppId" $AppId "scalar") (serialize-qp "CompanyId" $CompanyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Scorings/consolidated/daily" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User safe scoring - Accumulated value - v1/Scorings/individual
#
# GET /statistics/v1/Scorings/individual/
# operationId: userSafeScoringAccumulatedValueV1/scorings/individual
export def "statistics-scorings-individual userSafeScoringAccumulatedValueV1/scorings/individual" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # e.g. 2021-01-01
  --endDate: string # e.g. 2021-01-30
]: nothing -> record<Errors: list<any>, Result: record<AccelerationScore: float, AppId: string, BrakingScore: float, CompanyId: string, CorneringScore: float, DeviceToken: string, DistractedScore: float, InstanceId: string, OverallScore: float, SpeedingScore: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Scorings/individual/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User safe scoring - daily value - /v1/Scorings/individual/daily
#
# GET /statistics/v1/Scorings/individual/daily
# operationId: userSafeScoringDailyValue/v1/scorings/individual/daily
export def "statistics-scorings-individual-daily userSafeScoringDailyValue/v1/scorings/individual/daily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Tag: string # Optional (e.g. )
  --StartDate: string # (Required)  (e.g. 2021-01-01)
  --EndDate: string # (Required)  (e.g. 2021-01-20)
]: nothing -> record<Errors: list<any>, Result: table<AccelerationScore: float, AppId: string, BrakingScore: float, CalcDate: string, CompanyId: string, CorneringScore: float, DeviceToken: string, DistractedScore: float, InstanceId: string, OverallScore: float, SpeedingScore: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Tag" $Tag "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Scorings/individual/daily" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /v1/Statistics/consolidated
#
# GET /statistics/v1/Statistics/consolidated
# operationId: /v1/statistics/consolidated
export def "statistics-statistics-consolidated /v1/statistics/consolidated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceToken: string # e.g. 
  --StartDate: string # e.g. 2021-01-18
  --EndDate: string # e.g. 2021-03-18
  --Tag: string # e.g. 
  --InstanceId: string # e.g. 
  --AppId: string # e.g. 
  --CompanyId: string # e.g. 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeviceToken" $DeviceToken "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Tag" $Tag "scalar") (serialize-qp "InstanceId" $InstanceId "scalar") (serialize-qp "AppId" $AppId "scalar") (serialize-qp "CompanyId" $CompanyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Statistics/consolidated" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# /v1/Statistics/consolidated/daily
#
# GET /statistics/v1/Statistics/consolidated/daily
# operationId: /v1/statistics/consolidated/daily
export def "statistics-statistics-consolidated-daily /v1/statistics/consolidated/daily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DeviceToken: string # e.g. 
  --StartDate: string # e.g. 2021-01-17
  --EndDate: string # e.g. 2021-01-18
  --Tag: string # e.g. 
  --InstanceId: string # e.g. 
  --AppId: string # e.g. 
  --CompanyId: string # e.g. 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DeviceToken" $DeviceToken "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "Tag" $Tag "scalar") (serialize-qp "InstanceId" $InstanceId "scalar") (serialize-qp "AppId" $AppId "scalar") (serialize-qp "CompanyId" $CompanyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Statistics/consolidated/daily" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User statistics - Accumulated value - /v1/Statistics/individual
#
# GET /statistics/v1/Statistics/individual/
# operationId: userStatisticsAccumulatedValue/v1/statistics/individual
export def "statistics-statistics-individual userStatisticsAccumulatedValue/v1/statistics/individual" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # e.g. 2021-01-01
  --endDate: string # e.g. 2021-01-30
]: nothing -> record<Errors: list<any>, Result: record<AccelerationCount: float, AppId: string, AverageSpeedKmh: float, AverageSpeedMileh: float, BreakingCount: float, CompanyId: string, CorneringCount: float, DayDrivingTime: float, DeviceToken: string, DriverTripsCount: float, DrivingTime: float, InstanceId: string, MaxSpeedKmh: float, MaxSpeedMileh: float, MileageKm: float, MileageMile: float, NightDrivingTime: float, OtherTripsCount: float, PhoneUsageDistanceKm: float, PhoneUsageDistanceMile: float, PhoneUsageDurationMin: float, PhoneUsageOverSpeedDistanceKm: float, PhoneUsageOverSpeedDistanceMile: float, PhoneUsageOverSpeedDurationMin: float, RushHoursDrivingTime: float, TotalSpeedingKm: float, TotalSpeedingMile: float, TripsCount: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Statistics/individual/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User statistice - Daily value - v1/Statistics/individual/daily
#
# GET /statistics/v1/Statistics/individual/daily/
# operationId: userStatisticeDailyValueV1/statistics/individual/daily
export def "statistics-statistics-individual-daily userStatisticeDailyValueV1/statistics/individual/daily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # e.g. 2021-03-30
  --endDate: string # e.g. 2021-03-30
]: nothing -> record<Errors: list<any>, Result: table<AccelerationCount: float, AppId: string, AverageSpeedKmh: float, AverageSpeedMileh: float, BreakingCount: float, CompanyId: string, CorneringCount: float, DayDrivingTime: float, DeviceToken: string, DriverTripsCount: float, DrivingTime: float, InstanceId: string, MaxSpeedKmh: float, MaxSpeedMileh: float, MileageKm: float, MileageMile: float, NightDrivingTime: float, OtherTripsCount: float, PhoneUsageDistanceKm: float, PhoneUsageDistanceMile: float, PhoneUsageDurationMin: float, PhoneUsageOverSpeedDistanceKm: float, PhoneUsageOverSpeedDistanceMile: float, PhoneUsageOverSpeedDurationMin: float, ReportDate: string, RushHoursDrivingTime: float, TotalSpeedingKm: float, TotalSpeedingMile: float, TripsCount: float>, Status: float, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/v1/Statistics/individual/daily/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
