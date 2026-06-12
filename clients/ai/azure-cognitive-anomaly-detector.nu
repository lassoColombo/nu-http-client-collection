# Auto-generated client for Anomaly Detector Client v1.0
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-AnomalyDetector/1.0/swagger.json
# Auth: --token flag or $env.ANOMALY_DETECTOR_CLIENT_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ANOMALY_DETECTOR_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def granularity-completer [] { ["daily" "hourly" "minutely" "monthly" "weekly" "yearly"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "timeseries-change-point-detect ChangePointDetect" } } | get name | first)
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

# Detect change point for the entire series
#
# POST /timeseries/changePoint/detect
# operationId: ChangePointDetect
# --series item shape: {timestamp: string, value: float}
export def "timeseries-change-point-detect ChangePointDetect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customInterval: int # Custom Interval is used to set non-standard time interval, for example, if the series is 5 minutes, request can be set as {"granularity":"minutely", "customInterval":5}. (format: int32)
  granularity: string@granularity-completer # Can only be one of yearly, monthly, weekly, daily, hourly or minutely. Granularity is used for verify whether input series is valid.
  --period: int # Optional argument, periodic value of a time series. If the value is null or does not present, the API will determine the period automatically. (format: int32)
  series: list # Time series data points. Points should be sorted by timestamp in ascending order to match the change point detection result. — item shape: {timestamp: string, value: float}
  --stableTrendWindow: int # Optional argument, advanced model parameter, a default stableTrendWindow will be used in detection. (format: int32)
  --threshold: float # Optional argument, advanced model parameter, between 0.0-1.0, the lower the value is, the larger the trend error will be which means less change point will be accepted. (format: float)
]: any -> record<confidenceScores: list<float>, isChangePoint: list<bool>, period: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timeseries/changePoint/detect")
  let body = {customInterval: $customInterval, granularity: $granularity, period: $period, series: $series, stableTrendWindow: $stableTrendWindow, threshold: $threshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Detect anomalies for the entire series in batch.
#
# POST /timeseries/entire/detect
# operationId: EntireDetect
# --series item shape: {timestamp: string, value: float}
export def "timeseries-entire-detect EntireDetect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customInterval: int # Custom Interval is used to set non-standard time interval, for example, if the series is 5 minutes, request can be set as {"granularity":"minutely", "customInterval":5}. (format: int32)
  granularity: string@granularity-completer # Can only be one of yearly, monthly, weekly, daily, hourly or minutely. Granularity is used for verify whether input series is valid.
  --maxAnomalyRatio: float # Optional argument, advanced model parameter, max anomaly ratio in a time series. (format: float)
  --period: int # Optional argument, periodic value of a time series. If the value is null or does not present, the API will determine the period automatically. (format: int32)
  --sensitivity: int # Optional argument, advanced model parameter, between 0-99, the lower the value is, the larger the margin value will be which means less anomalies will be accepted. (format: int32)
  series: list # Time series data points. Points should be sorted by timestamp in ascending order to match the anomaly detection result. If the data is not sorted correctly or there is duplicated timestamp, the API will not work. In such case, an error message will be returned. — item shape: {timestamp: string, value: float}
]: any -> record<expectedValues: list<float>, isAnomaly: list<bool>, isNegativeAnomaly: list<bool>, isPositiveAnomaly: list<bool>, lowerMargins: list<float>, period: int, upperMargins: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timeseries/entire/detect")
  let body = {customInterval: $customInterval, granularity: $granularity, maxAnomalyRatio: $maxAnomalyRatio, period: $period, sensitivity: $sensitivity, series: $series} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Detect anomaly status of the latest point in time series.
#
# POST /timeseries/last/detect
# operationId: LastDetect
# --series item shape: {timestamp: string, value: float}
export def "timeseries-last-detect LastDetect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customInterval: int # Custom Interval is used to set non-standard time interval, for example, if the series is 5 minutes, request can be set as {"granularity":"minutely", "customInterval":5}. (format: int32)
  granularity: string@granularity-completer # Can only be one of yearly, monthly, weekly, daily, hourly or minutely. Granularity is used for verify whether input series is valid.
  --maxAnomalyRatio: float # Optional argument, advanced model parameter, max anomaly ratio in a time series. (format: float)
  --period: int # Optional argument, periodic value of a time series. If the value is null or does not present, the API will determine the period automatically. (format: int32)
  --sensitivity: int # Optional argument, advanced model parameter, between 0-99, the lower the value is, the larger the margin value will be which means less anomalies will be accepted. (format: int32)
  series: list # Time series data points. Points should be sorted by timestamp in ascending order to match the anomaly detection result. If the data is not sorted correctly or there is duplicated timestamp, the API will not work. In such case, an error message will be returned. — item shape: {timestamp: string, value: float}
]: any -> record<expectedValue: float, isAnomaly: bool, isNegativeAnomaly: bool, isPositiveAnomaly: bool, lowerMargin: float, period: int, suggestedWindow: int, upperMargin: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/timeseries/last/detect")
  let body = {customInterval: $customInterval, granularity: $granularity, maxAnomalyRatio: $maxAnomalyRatio, period: $period, sensitivity: $sensitivity, series: $series} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
