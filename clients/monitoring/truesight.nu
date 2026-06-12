# Auto-generated client for Hardware Sentry TrueSight Presentation Server REST API v11.1.00
# Source: https://api.apis.guru/v2/specs/truesight.local/11.1.00/openapi.json
# Auth: --token flag or $env.HARDWARE_SENTRY_TRUESIGHT_PRESENTATION_SERVER_REST_API_TOKEN

const BASE_URL = "http://truesight.local"
const DEFAULT_AUTH = "cookie"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HARDWARE_SENTRY_TRUESIGHT_PRESENTATION_SERVER_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "cookie" => { {headers: {Cookie: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://truesight.local" "http://localhost/tsws/10.0/api" "https://localhost:8043/tsws/10.0/api"] }
def auth-scheme-completer [] { ["cookie"] }

# Completers for enum parameters
def resetAlertActions-completer [] { ["0" "1"] }
def resetAlertAfterNTimes-completer [] { ["0" "1"] }
def resetDebugMode-completer [] { ["0" "1"] }
def resetDiscoveryAndPollingIntervals-completer [] { ["0" "1"] }
def resetJavaSettings-completer [] { ["0" "1"] }
def resetOtherAlertSettings-completer [] { ["0" "1"] }
def resetRemovedPausedObjectList-completer [] { ["0" "1"] }
def resetReportSettings-completer [] { ["0" "1"] }
def resetThresholds-completer [] { ["0" "1"] }
def direction-completer [] { ["asc" "desc"] }
def rollPeriod-completer [] { ["ONE_DAY" "ONE_MONTH" "ONE_WEEK" "ONE_YEAR" "SIX_MONTHS"] }
def basis-completer [] { ["DAILY" "HOURLY" "MONTHLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "hardware-actions-collect-now collectNow" } } | get name | first)
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

# Triggers a new collect on a specific device.
#
# POST /hardware/actions/{deviceId}/collect-now
# operationId: collectNow
export def "hardware-actions-collect-now collectNow" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitorClass: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "monitorClass" $monitorClass "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hardware/actions/($deviceId)/collect-now" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Triggers a new discovery on a specific device.
#
# POST /hardware/actions/{deviceId}/rediscover
# operationId: rediscover
export def "hardware-actions-rediscover rediscover" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/actions/($deviceId)/rediscover")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a 'Reinitialize KM' command.
#
# POST /hardware/actions/{deviceId}/reinitialize
# operationId: reinitialize
export def "hardware-actions-reinitialize reinitialize" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resetAlertActions: int@resetAlertActions-completer # When set to <em>1</em>, removes all manually set Alert Actions and reverts to basic default actions i.e. trigger a PATROL event and annotate a parameter graph. (format: int32, e.g. 1)
  --resetAlertAfterNTimes: int@resetAlertAfterNTimes-completer # When set to <em>1</em>, resets the number of times thresholds can be breached before triggering an alert to their default values (1 time) for numeric, discrete, connector status and present parameters. (format: int32, e.g. 1)
  --resetDebugMode: int@resetDebugMode-completer # When set to <em>1</em>, deactivates the debug mode when it was manually enabled. (format: int32, e.g. 1)
  --resetDiscoveryAndPollingIntervals: int@resetDiscoveryAndPollingIntervals-completer # When set to <em>1</em>, removes all user-defined frequencies for discovery and polling processes to their default values (respectively 1 hour and 2 minutes). (format: int32, e.g. 1)
  --resetJavaSettings: int@resetJavaSettings-completer # When set to <em>1</em>, removes the custom Java settings (path and credentials). The KM will try to automatically find a suitable JRE. (format: int32, e.g. 1)
  --resetOtherAlertSettings: int@resetOtherAlertSettings-completer # When set to <em>1</em>, reverts any manually performed configuration changes to the default Hardware Sentry values. (format: int32, e.g. 1)
  --resetRemovedPausedObjectList: int@resetRemovedPausedObjectList-completer # When set to <em>1</em>, reactivates the monitoring of all paused or removed objects. (format: int32, e.g. 1)
  --resetReportSettings: int@resetReportSettings-completer # When set to <em>1</em>, clears the report schedule. (format: int32, e.g. 1)
  --resetThresholds: int@resetThresholds-completer # When set to <em>1</em>, resets all thresholds. (format: int32, e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/actions/($deviceId)/reinitialize")
  let body = {resetAlertActions: $resetAlertActions, resetAlertAfterNTimes: $resetAlertAfterNTimes, resetDebugMode: $resetDebugMode, resetDiscoveryAndPollingIntervals: $resetDiscoveryAndPollingIntervals, resetJavaSettings: $resetJavaSettings, resetOtherAlertSettings: $resetOtherAlertSettings, resetRemovedPausedObjectList: $resetRemovedPausedObjectList, resetReportSettings: $resetReportSettings, resetThresholds: $resetThresholds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a specific instance from the monitoring environment.
#
# POST /hardware/actions/{deviceId}/remove
# operationId: remove
export def "hardware-actions-remove remove" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitorClass: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
  --monitorSid: string # The Monitor SID of the device. (e.g. cisco-c240-imc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "monitorClass" $monitorClass "scalar") (serialize-qp "monitorSid" $monitorSid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hardware/actions/($deviceId)/remove" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resets the Error Count parameter.
#
# POST /hardware/actions/{deviceId}/reset-error-count
# operationId: reset
export def "hardware-actions-reset-error-count reset" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitorClass: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
  --monitorSid: string # The Monitor SID of the device. (e.g. cisco-c240-imc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "monitorClass" $monitorClass "scalar") (serialize-qp "monitorSid" $monitorSid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hardware/actions/($deviceId)/reset-error-count" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets summarized information about all monitored applications.
#
# GET /hardware/applications
# operationId: getApplications
export def "hardware-applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/applications" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets detailed information for a specific application.
#
# GET /hardware/applications/{applicationId}
# operationId: getOneApplication
export def "hardware-applications get" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/applications/($applicationId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Monitors for a specific device.
#
# GET /hardware/device-monitors/{deviceId}
# operationId: getDeviceMonitors
export def "hardware-device-monitors get" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/device-monitors/($deviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets summarized information about all monitored devices.
#
# GET /hardware/devices
# operationId: getDevices
export def "hardware-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
  --groupId: string # The ID of the group. (e.g. 0)
  --applicationId: string # The ID of the application. (e.g. 0)
  --serviceId: string # The ID of the service. (e.g. 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "serviceId" $serviceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/devices" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets overall information for all devices.
#
# GET /hardware/devices-summary
# operationId: getDevicesSummary
export def "hardware-devices-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hardware/devices-summary")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets detailed information about a specific device.
#
# GET /hardware/devices/{deviceId}
# operationId: getDevice
export def "hardware-devices get" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/devices/($deviceId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets detailed information about an Agent.
#
# GET /hardware/devices/{deviceId}/agent
# operationId: getDeviceAgent
export def "hardware-devices-agent get" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/devices/($deviceId)/agent")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all the devices monitored by an Agent.
#
# GET /hardware/devices/{deviceId}/agent-devices
# operationId: getAgentDevices
export def "hardware-devices-agent-devices get" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/devices/($deviceId)/agent-devices")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets data history for a parameter of a specific device over a given period.
#
# GET /hardware/devices/{deviceId}/parameter-history
# operationId: getDeviceParameterHistory
export def "hardware-devices-parameter-history get" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameterName: string # The name of the parameter. (e.g. Power Consumption)
  --monitorType: string # The unique name of the Monitor type. (e.g. _PATROL__MS_HW_REPORT)
  --qp-from: int # Beginning of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --qp-to: int # End of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --monitorSid: string # The Monitor SID (to filter the list of Monitors). (e.g. cisco-c240-imc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameterName" $parameterName "scalar") (serialize-qp "monitorType" $monitorType "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "monitorSid" $monitorSid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hardware/devices/($deviceId)/parameter-history" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the energy usage for a specific device and a given period.
#
# GET /hardware/energy-usage/{deviceId}
# operationId: getDeviceEnergyUsage
export def "hardware-energy-usage get" [
  deviceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rollPeriod: string@rollPeriod-completer # The period for which you wish to retrieve energy usage data. (default: ONE_DAY)
  --basis: string@basis-completer # Subdivision of the period for which you wish to retrieve energy usage data. (default: HOURLY)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rollPeriod" $rollPeriod "scalar") (serialize-qp "basis" $basis "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hardware/energy-usage/($deviceId)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all group summaries.
#
# GET /hardware/groups
# operationId: getGroups
export def "hardware-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/groups" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets detailed information about a specific group.
#
# GET /hardware/groups/{groupId}
# operationId: getOneGroup
export def "hardware-groups get" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/groups/($groupId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the values of the energy footprint parameter for a specific group.
#
# PUT /hardware/groups/{groupId}
# operationId: updateEnergyCost
export def "hardware-groups updateEnergyCost" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --co2Emission: float # Updates the CO<sub>2</sub> emission (unit: kg/kWh). (format: double, e.g. 0.3)
  --energyCost: float # Updates the electricity rate (unit: $/kWh). (format: double, e.g. 0.3)
  --groupNameFilter: string # Updates the regular expression used to filter the groups for which the power consumption should be reported. (e.g. Group [0-9]+)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/groups/($groupId)")
  let body = {co2Emission: $co2Emission, energyCost: $energyCost, groupNameFilter: $groupNameFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the heating margin values for each monitored device, when available.
#
# GET /hardware/heating-margin-devices
# operationId: getHeatingMarginCoverage
export def "hardware-heating-margin-devices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --covered: oneof<nothing, bool> # If set to <em>true</em>, only gets devices whose heating margin information is available.<br>Otherwise, gets any other devices. (default: true)
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
  --groupId: string # The ID of the group. (e.g. 0)
  --applicationId: string # The ID of the application. (e.g. 0)
  --serviceId: string # The ID of the service. (e.g. 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "covered" $covered "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "serviceId" $serviceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/heating-margin-devices" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets historical data for a specific group, application or service.
#
# GET /hardware/history
# operationId: getHistory
export def "hardware-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupId: string # The ID of the group. (e.g. 0)
  --applicationId: string # The ID of the application. (e.g. 0)
  --serviceId: string # The ID of the service. (e.g. 0)
  --qp-from: int # Beginning of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --qp-to: int # End of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar") (serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "serviceId" $serviceId "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/history" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches devices by name, model, manufacturer or serial number.
#
# GET /hardware/search-devices
# operationId: searchDevices
export def "hardware-search-devices searchDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --searchTerms: string # Space-separated search criteria. (e.g. EMC Unity)
  --groupId: string # The ID of the group. (e.g. 0)
  --applicationId: string # The ID of the application. (e.g. 0)
  --serviceId: string # The ID of the service. (e.g. 0)
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerms" $searchTerms "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "serviceId" $serviceId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/search-devices" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets summarized information about all monitored services.
#
# GET /hardware/services
# operationId: getServices
export def "hardware-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/services" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets detailed information about a specific service.
#
# GET /hardware/services/{serviceId}
# operationId: getOneService
export def "hardware-services get" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hardware/services/($serviceId)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
