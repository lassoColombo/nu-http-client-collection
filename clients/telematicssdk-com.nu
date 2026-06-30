# Auto-generated client for Quick start - Telematics SDK v1.0.0
# Source: https://api.apis.guru/v2/specs/telematicssdk.com/1.0.0/openapi.json
# Auth: --token flag or $env.QUICK_START_TELEMATICS_SDK_TOKEN

const BASE_URL = "https://api.telematicssdk.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o QUICK_START_TELEMATICS_SDK_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
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
  let full_url = (build-url $base "/mobilesdk/stage/track/get_track/v1" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"trackToken": $track_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/statistics/v1/Scorings/consolidated" $qp $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DeviceToken": $device_token, "StartDate": $start_date, "EndDate": $end_date, "Tag": $tag, "InstanceId": $instance_id, "AppId": $app_id, "CompanyId": $company_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/statistics/v1/Scorings/consolidated/daily" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DeviceToken": $device_token, "StartDate": $start_date, "EndDate": $end_date, "Tag": $tag, "InstanceId": $instance_id, "AppId": $app_id, "CompanyId": $company_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/statistics/v1/Scorings/individual/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/statistics/v1/Scorings/individual/daily" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Tag": $tag, "StartDate": $start_date, "EndDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/statistics/v1/Statistics/consolidated" $qp $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DeviceToken": $device_token, "StartDate": $start_date, "EndDate": $end_date, "Tag": $tag, "InstanceId": $instance_id, "AppId": $app_id, "CompanyId": $company_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/statistics/v1/Statistics/consolidated/daily" $qp $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DeviceToken": $device_token, "StartDate": $start_date, "EndDate": $end_date, "Tag": $tag, "InstanceId": $instance_id, "AppId": $app_id, "CompanyId": $company_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/statistics/v1/Statistics/individual/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/statistics/v1/Statistics/individual/daily/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
