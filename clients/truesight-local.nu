# Auto-generated client for Hardware Sentry TrueSight Presentation Server REST API v11.1.00
# Source: https://api.apis.guru/v2/specs/truesight.local/11.1.00/openapi.json
# Auth: --token flag or $env.HARDWARE_SENTRY_TRUESIGHT_PRESENTATION_SERVER_REST_API_TOKEN

const BASE_URL = "http://truesight.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o HARDWARE_SENTRY_TRUESIGHT_PRESENTATION_SERVER_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "cookie" => { {scheme: $scheme, headers: {Cookie: $token_val}, query: "", location: "header"} }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor-class: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
]: nothing -> record<pslOutput: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "monitorClass" $monitor_class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/collect-now") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"monitorClass": $monitor_class} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pslOutput: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/rediscover") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: any -> record<pslOutput: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/reinitialize") $auth.query)
  let req_body = {"resetAlertActions": $reset_alert_actions, "resetAlertAfterNTimes": $reset_alert_after_n_times, "resetDebugMode": $reset_debug_mode, "resetDiscoveryAndPollingIntervals": $reset_discovery_and_polling_intervals, "resetJavaSettings": $reset_java_settings, "resetOtherAlertSettings": $reset_other_alert_settings, "resetRemovedPausedObjectList": $reset_removed_paused_object_list, "resetReportSettings": $reset_report_settings, "resetThresholds": $reset_thresholds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor-class: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
  --monitor-sid: string # The Monitor SID of the device. (e.g. cisco-c240-imc)
]: nothing -> record<pslOutput: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "monitorClass" $monitor_class "scalar") (serialize-qp "monitorSid" $monitor_sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/remove") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"monitorClass": $monitor_class, "monitorSid": $monitor_sid} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor-class: string # The Monitor Class of the device. (e.g. MS_HW_FAN)
  --monitor-sid: string # The Monitor SID of the device. (e.g. cisco-c240-imc)
]: nothing -> record<pslOutput: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "monitorClass" $monitor_class "scalar") (serialize-qp "monitorSid" $monitor_sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/actions/{device_id}/reset-error-count") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"monitorClass": $monitor_class, "monitorSid": $monitor_sid} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/applications" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit, "direction": $direction, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<costUnit: string, deviceSummaries: table<agentId: int, agentName: string, ambientTemperature: float, collectTime: string, deviceTSMOKey: string, deviceUrl: string, heatingMargin: float, heatingMarginUnit: string, id: int, name: string, powerConsumption: float, powerConsumptionUnit: string, productVersion: string, serverId: int, serverName: string, sid: string, type: string, updateTimestamp: int>, emittedCo2Unit: string, energyConsumptionUnit: string, heatingMargin: float, heatingMarginCoverage: float, heatingMarginDeviceName: string, heatingMarginDeviceUrl: string, heatingMarginUnit: string, historyParentIdKey: string, id: string, name: string, numberOfDevices: int, oneDayConfidence: float, oneDayCost: float, oneDayEmittedCo2: float, oneDayEnergyConsumption: float, oneMonthConfidence: float, oneMonthCost: float, oneMonthEmittedCo2: float, oneMonthEnergyConsumption: float, oneYearConfidence: float, oneYearCost: float, oneYearEmittedCo2: float, oneYearEnergyConsumption: float, totalPowerConsumption: float, totalPowerConsumptionUnit: string, updateTimestamp: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/hardware/applications/{application_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/device-monitors/{device_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
  --group-id: string # The ID of the group. (e.g. 0)
  --application-id: string # The ID of the application. (e.g. 0)
  --service-id: string # The ID of the service. (e.g. 0)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "applicationId" $application_id "scalar") (serialize-qp "serviceId" $service_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/devices" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit, "direction": $direction, "sort": $qp_sort, "groupId": $group_id, "applicationId": $application_id, "serviceId": $service_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<co2Emission: float, co2EmissionUnit: string, editable: bool, energyCost: float, energyCostUnit: string, groupNameFilter: string, heatingMargin: float, heatingMarginCoverage: float, heatingMarginDeviceName: string, heatingMarginDeviceUrl: string, heatingMarginUnit: string, id: string, totalPowerConsumption: float, totalPowerConsumptionUnit: string, updateTimestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hardware/devices-summary" $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<agentId: int, agentName: string, ambientTemperature: float, collectTime: string, deviceTSMOKey: string, deviceUrl: string, heatingMargin: float, heatingMarginUnit: string, id: int, name: string, powerConsumption: float, powerConsumptionUnit: string, productVersion: string, serverId: int, serverName: string, sid: string, type: string, updateTimestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/devices/{device_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connectionStatus: string, id: string, name: string, os: string, port: string, url: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/devices/{device_id}/agent") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/devices/{device_id}/agent-devices") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameter-name: string # The name of the parameter. (e.g. Power Consumption)
  --monitor-type: string # The unique name of the Monitor type. (e.g. _PATROL__MS_HW_REPORT)
  --qp-from: int # Beginning of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --qp-to: int # End of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --monitor-sid: string # The Monitor SID (to filter the list of Monitors). (e.g. cisco-c240-imc)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "parameterName" $parameter_name "scalar") (serialize-qp "monitorType" $monitor_type "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "monitorSid" $monitor_sid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/devices/{device_id}/parameter-history") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"parameterName": $parameter_name, "monitorType": $monitor_type, "from": $qp_from, "to": $qp_to, "monitorSid": $monitor_sid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --roll-period: string@roll-period-completer # The period for which you wish to retrieve energy usage data. (default: ONE_DAY)
  --basis: string@basis-completer # Subdivision of the period for which you wish to retrieve energy usage data. (default: HOURLY)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "rollPeriod" $roll_period "scalar") (serialize-qp "basis" $basis "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/hardware/energy-usage/{device_id}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rollPeriod": $roll_period, "basis": $basis} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/groups" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit, "direction": $direction, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ambientTemperature: float, ambientTemperatureUnit: string, co2Emission: float, co2EmissionUnit: string, costUnit: string, deviceSummaries: table<agentId: int, agentName: string, ambientTemperature: float, collectTime: string, deviceTSMOKey: string, deviceUrl: string, heatingMargin: float, heatingMarginUnit: string, id: int, name: string, powerConsumption: float, powerConsumptionUnit: string, productVersion: string, serverId: int, serverName: string, sid: string, type: string, updateTimestamp: int>, editable: bool, emittedCo2Unit: string, energyConsumptionUnit: string, energyCost: float, energyCostUnit: string, heatingMargin: float, heatingMarginCoverage: float, heatingMarginDeviceName: string, heatingMarginDeviceUrl: string, heatingMarginUnit: string, historyParentIdKey: string, id: string, name: string, numberOfDevices: int, oneDayConfidence: float, oneDayCost: float, oneDayEmittedCo2: float, oneDayEnergyConsumption: float, oneMonthConfidence: float, oneMonthCost: float, oneMonthEmittedCo2: float, oneMonthEnergyConsumption: float, oneYearConfidence: float, oneYearCost: float, oneYearEmittedCo2: float, oneYearEnergyConsumption: float, serverId: int, totalPowerConsumption: float, totalPowerConsumptionUnit: string, updateTimestamp: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/hardware/groups/{group_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --co2-emission: float # Updates the CO2 emission (unit: kg/kWh). (format: double, e.g. 0.3)
  --energy-cost: float # Updates the electricity rate (unit: $/kWh). (format: double, e.g. 0.3)
  --group-name-filter: string # Updates the regular expression used to filter the groups for which the power consumption should be reported. (e.g. Group [0-9]+)
]: any -> record<co2Emission: float, co2EmissionUnit: string, editable: bool, energyCost: float, energyCostUnit: string, groupNameFilter: string, heatingMargin: float, heatingMarginCoverage: float, heatingMarginDeviceName: string, heatingMarginDeviceUrl: string, heatingMarginUnit: string, id: string, totalPowerConsumption: float, totalPowerConsumptionUnit: string, updateTimestamp: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/hardware/groups/{group_id}") $auth.query)
  let req_body = {"co2Emission": $co2_emission, "energyCost": $energy_cost, "groupNameFilter": $group_name_filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --covered: oneof<nothing, bool> # If set to true, only gets devices whose heating margin information is available.Otherwise, gets any other devices. (default: true)
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
  --group-id: string # The ID of the group. (e.g. 0)
  --application-id: string # The ID of the application. (e.g. 0)
  --service-id: string # The ID of the service. (e.g. 0)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "covered" $covered "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "applicationId" $application_id "scalar") (serialize-qp "serviceId" $service_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/heating-margin-devices" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"covered": $covered, "page": $page, "limit": $limit, "direction": $direction, "sort": $qp_sort, "groupId": $group_id, "applicationId": $application_id, "serviceId": $service_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string # The ID of the group. (e.g. 0)
  --application-id: string # The ID of the application. (e.g. 0)
  --service-id: string # The ID of the service. (e.g. 0)
  --qp-from: int # Beginning of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
  --qp-to: int # End of the period (Epoch time, in seconds). (format: int64, e.g. 1608850800)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $group_id "scalar") (serialize-qp "applicationId" $application_id "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/history" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"groupId": $group_id, "applicationId": $application_id, "serviceId": $service_id, "from": $qp_from, "to": $qp_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-terms: string # Space-separated search criteria. (e.g. EMC Unity)
  --group-id: string # The ID of the group. (e.g. 0)
  --application-id: string # The ID of the application. (e.g. 0)
  --service-id: string # The ID of the service. (e.g. 0)
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerms" $search_terms "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "applicationId" $application_id "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/search-devices" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"searchTerms": $search_terms, "groupId": $group_id, "applicationId": $application_id, "serviceId": $service_id, "page": $page, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page number to retrieve (first page is 0). (format: int32, default: 0)
  --limit: int # The maximum number of entries per page. (format: int32, default: 100)
  --direction: string@direction-completer # The sorting order (case insensitive). (default: asc)
  --qp-sort: string # The column to sort by (case insensitive). (default: name)
]: nothing -> record<items: list<record>, restrictedRights: bool, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hardware/services" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "limit": $limit, "direction": $direction, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<costUnit: string, deviceSummaries: table<agentId: int, agentName: string, ambientTemperature: float, collectTime: string, deviceTSMOKey: string, deviceUrl: string, heatingMargin: float, heatingMarginUnit: string, id: int, name: string, powerConsumption: float, powerConsumptionUnit: string, productVersion: string, serverId: int, serverName: string, sid: string, type: string, updateTimestamp: int>, emittedCo2Unit: string, energyConsumptionUnit: string, heatingMargin: float, heatingMarginCoverage: float, heatingMarginDeviceName: string, heatingMarginDeviceUrl: string, heatingMarginUnit: string, historyParentIdKey: string, id: string, name: string, numberOfDevices: int, oneDayConfidence: float, oneDayCost: float, oneDayEmittedCo2: float, oneDayEnergyConsumption: float, oneMonthConfidence: float, oneMonthCost: float, oneMonthEmittedCo2: float, oneMonthEnergyConsumption: float, oneYearConfidence: float, oneYearCost: float, oneYearEmittedCo2: float, oneYearEnergyConsumption: float, providerId: string, totalPowerConsumption: float, totalPowerConsumptionUnit: string, updateTimestamp: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/hardware/services/{service_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
