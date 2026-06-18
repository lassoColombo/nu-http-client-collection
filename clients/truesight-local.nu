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
def reset-alert-actions-completer [] { ["0" "1"] }
def reset-alert-after-n-times-completer [] { ["0" "1"] }
def reset-debug-mode-completer [] { ["0" "1"] }
def reset-discovery-and-polling-intervals-completer [] { ["0" "1"] }
def reset-java-settings-completer [] { ["0" "1"] }
def reset-other-alert-settings-completer [] { ["0" "1"] }
def reset-removed-paused-object-list-completer [] { ["0" "1"] }
def reset-report-settings-completer [] { ["0" "1"] }
def reset-thresholds-completer [] { ["0" "1"] }
def direction-completer [] { ["asc" "desc"] }
def roll-period-completer [] { ["ONE_DAY" "ONE_MONTH" "ONE_WEEK" "ONE_YEAR" "SIX_MONTHS"] }
def basis-completer [] { ["DAILY" "HOURLY" "MONTHLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "hardware-actions-collect-now create" } } | get name | first)
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
export def "hardware-actions-collect-now create" [
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor-class: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "monitorClass" $monitor_class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/collect-now") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Triggers a new discovery on a specific device.
#
# POST /hardware/actions/{deviceId}/rediscover
# operationId: rediscover
export def "hardware-actions-rediscover create" [
  device_id: int
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
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/rediscover"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a 'Reinitialize KM' command.
#
# POST /hardware/actions/{deviceId}/reinitialize
# operationId: reinitialize
export def "hardware-actions-reinitialize create" [
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reset-alert-actions: int@reset-alert-actions-completer # When set to 1, removes all manually set Alert Actions and reverts to basic default actions i.e. trigger a PATROL event and annotate a parameter graph. (format: int32, e.g. 1)
  --reset-alert-after-n-times: int@reset-alert-after-n-times-completer # When set to 1, resets the number of times thresholds can be breached before triggering an alert to their default values (1 time) for numeric, discrete, connector status and present parameters. (format: int32, e.g. 1)
  --reset-debug-mode: int@reset-debug-mode-completer # When set to 1, deactivates the debug mode when it was manually enabled. (format: int32, e.g. 1)
  --reset-discovery-and-polling-intervals: int@reset-discovery-and-polling-intervals-completer # When set to 1, removes all user-defined frequencies for discovery and polling processes to their default values (respectively 1 hour and 2 minutes). (format: int32, e.g. 1)
  --reset-java-settings: int@reset-java-settings-completer # When set to 1, removes the custom Java settings (path and credentials). The KM will try to automatically find a suitable JRE. (format: int32, e.g. 1)
  --reset-other-alert-settings: int@reset-other-alert-settings-completer # When set to 1, reverts any manually performed configuration changes to the default Hardware Sentry values. (format: int32, e.g. 1)
  --reset-removed-paused-object-list: int@reset-removed-paused-object-list-completer # When set to 1, reactivates the monitoring of all paused or removed objects. (format: int32, e.g. 1)
  --reset-report-settings: int@reset-report-settings-completer # When set to 1, clears the report schedule. (format: int32, e.g. 1)
  --reset-thresholds: int@reset-thresholds-completer # When set to 1, resets all thresholds. (format: int32, e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/reinitialize"))
  let req_body = {"resetAlertActions": $reset_alert_actions, "resetAlertAfterNTimes": $reset_alert_after_n_times, "resetDebugMode": $reset_debug_mode, "resetDiscoveryAndPollingIntervals": $reset_discovery_and_polling_intervals, "resetJavaSettings": $reset_java_settings, "resetOtherAlertSettings": $reset_other_alert_settings, "resetRemovedPausedObjectList": $reset_removed_paused_object_list, "resetReportSettings": $reset_report_settings, "resetThresholds": $reset_thresholds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes a specific instance from the monitoring environment.
#
# POST /hardware/actions/{deviceId}/remove
# operationId: remove
export def "hardware-actions-remove delete" [
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor-class: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
  --monitor-sid: string # The Monitor SID of the device. (e.g. cisco-c240-imc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "monitorClass" $monitor_class "scalar") (serialize-qp "monitorSid" $monitor_sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/remove") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resets the Error Count parameter.
#
# POST /hardware/actions/{deviceId}/reset-error-count
# operationId: reset
export def "hardware-actions-reset-error-count reset" [
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor-class: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
  --monitor-sid: string # The Monitor SID of the device. (e.g. cisco-c240-imc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "monitorClass" $monitor_class "scalar") (serialize-qp "monitorSid" $monitor_sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/reset-error-count") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets summarized information about all monitored applications.
#
# GET /hardware/applications
# operationId: getApplications
export def "hardware-applications get" [
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
export def "hardware-applications get-one" [
  application_id: string
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
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/hardware/applications/{application_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Monitors for a specific device.
#
# GET /hardware/device-monitors/{deviceId}
# operationId: getDeviceMonitors
export def "hardware-device-monitors get" [
  device_id: int
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
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/device-monitors/{device_id}"))
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
  --group-id: string # The ID of the group. (e.g. 0)
  --application-id: string # The ID of the application. (e.g. 0)
  --service-id: string # The ID of the service. (e.g. 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "applicationId" $application_id "scalar") (serialize-qp "serviceId" $service_id "scalar")] | flatten | str join "&"
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
  device_id: int
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
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/devices/{device_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets detailed information about an Agent.
#
# GET /hardware/devices/{deviceId}/agent
# operationId: getDeviceAgent
export def "hardware-devices-agent get" [
  device_id: int
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
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/devices/{device_id}/agent"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all the devices monitored by an Agent.
#
# GET /hardware/devices/{deviceId}/agent-devices
# operationId: getAgentDevices
export def "hardware-devices-agent-devices get" [
  device_id: int
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
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/devices/{device_id}/agent-devices"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets data history for a parameter of a specific device over a given period.
#
# GET /hardware/devices/{deviceId}/parameter-history
# operationId: getDeviceParameterHistory
export def "hardware-devices-parameter-history get" [
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-name: string # The name of the parameter. (e.g. Power Consumption)
  --monitor-type: string # The unique name of the Monitor type. (e.g. _PATROL__MS_HW_REPORT)
  --qp-from: int # Beginning of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --qp-to: int # End of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --monitor-sid: string # The Monitor SID (to filter the list of Monitors). (e.g. cisco-c240-imc)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameterName" $parameter_name "scalar") (serialize-qp "monitorType" $monitor_type "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "monitorSid" $monitor_sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/devices/{device_id}/parameter-history") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the energy usage for a specific device and a given period.
#
# GET /hardware/energy-usage/{deviceId}
# operationId: getDeviceEnergyUsage
export def "hardware-energy-usage get-device" [
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --roll-period: string@roll-period-completer # The period for which you wish to retrieve energy usage data. (default: ONE_DAY)
  --basis: string@basis-completer # Subdivision of the period for which you wish to retrieve energy usage data. (default: HOURLY)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rollPeriod" $roll_period "scalar") (serialize-qp "basis" $basis "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/energy-usage/{device_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all group summaries.
#
# GET /hardware/groups
# operationId: getGroups
export def "hardware-groups get" [
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
export def "hardware-groups get-one" [
  group_id: string
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
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/hardware/groups/{group_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the values of the energy footprint parameter for a specific group.
#
# PUT /hardware/groups/{groupId}
# operationId: updateEnergyCost
export def "hardware-groups update-energy-cost" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --co2-emission: float # Updates the CO2 emission (unit: kg/kWh). (format: double, e.g. 0.3)
  --energy-cost: float # Updates the electricity rate (unit: $/kWh). (format: double, e.g. 0.3)
  --group-name-filter: string # Updates the regular expression used to filter the groups for which the power consumption should be reported. (e.g. Group [0-9]+)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/hardware/groups/{group_id}"))
  let req_body = {"co2Emission": $co2_emission, "energyCost": $energy_cost, "groupNameFilter": $group_name_filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the heating margin values for each monitored device, when available.
#
# GET /hardware/heating-margin-devices
# operationId: getHeatingMarginCoverage
export def "hardware-heating-margin-devices get-coverage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --covered: oneof<nothing, bool> # If set to true, only gets devices whose heating margin information is available.Otherwise, gets any other devices. (default: true)
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
  --group-id: string # The ID of the group. (e.g. 0)
  --application-id: string # The ID of the application. (e.g. 0)
  --service-id: string # The ID of the service. (e.g. 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "covered" $covered "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "applicationId" $application_id "scalar") (serialize-qp "serviceId" $service_id "scalar")] | flatten | str join "&"
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
  --group-id: string # The ID of the group. (e.g. 0)
  --application-id: string # The ID of the application. (e.g. 0)
  --service-id: string # The ID of the service. (e.g. 0)
  --qp-from: int # Beginning of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --qp-to: int # End of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $group_id "scalar") (serialize-qp "applicationId" $application_id "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/history" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches devices by name, model, manufacturer or serial number.
#
# GET /hardware/search-devices
# operationId: searchDevices
export def "hardware-search-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-terms: string # Space-separated search criteria. (e.g. EMC Unity)
  --group-id: string # The ID of the group. (e.g. 0)
  --application-id: string # The ID of the application. (e.g. 0)
  --service-id: string # The ID of the service. (e.g. 0)
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerms" $search_terms "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "applicationId" $application_id "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/search-devices" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets summarized information about all monitored services.
#
# GET /hardware/services
# operationId: getServices
export def "hardware-services get" [
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
export def "hardware-services get-one" [
  service_id: string
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
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/hardware/services/{service_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
