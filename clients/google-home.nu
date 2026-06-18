# Auto-generated client for Google Home v2.0
# Source: https://api.apis.guru/v2/specs/google.home/2.0/openapi.json
# Auth: --token flag or $env.GOOGLE_HOME_TOKEN

const BASE_URL = "http://example.com/setup"
const DEFAULT_AUTH = "cast-local-authorization-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_HOME_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "cast-local-authorization-token" => { {headers: {cast-local-authorization-token: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://example.com/setup"] }
def auth-scheme-completer [] { ["cast-local-authorization-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "notice-html-gz get-legal" } } | get name | first)
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

# Legal Notice
#
# GET /NOTICE.html.gz
# operationId: LegalNotice
export def "notice-html-gz get-legal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/NOTICE.html.gz")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accessibility
#
# POST /assistant/a11y_mode
# operationId: Accessibility
export def "assistant-a11y-mode create-accessibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoint-enabled: oneof<nothing, bool>
  --hotword-enabled: oneof<nothing, bool>
]: any -> record<endpoint_enabled: bool, hotword_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assistant/a11y_mode")
  let req_body = {"endpoint_enabled": $endpoint_enabled, "hotword_enabled": $hotword_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Alarms and Timers
#
# GET /assistant/alarms
# operationId: GetAlarmsandTimers
export def "assistant-alarms get-alarmsand-timers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alarm: table<date_pattern: record, fire_time: float, id: string, status: int, time_pattern: record>, timer: table<fire_time: int, id: string, original_duration: int, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assistant/alarms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Alarms and Timers
#
# POST /assistant/alarms/delete
# operationId: DeleteAlarmsandTimers
export def "assistant-alarms-delete delete-alarmsand-timers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string>
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assistant/alarms/delete")
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Alarm Volume
#
# POST /assistant/alarms/volume
# operationId: AlarmVolume
export def "assistant-alarms-volume create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  volume: int # format: int32
]: any -> record<volume: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assistant/alarms/volume")
  let req_body = {"volume": $volume} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Check Ready Status
#
# POST /assistant/check_ready_status
# operationId: CheckReadyStatus
export def "assistant-check-ready-status check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --play-ready-message: oneof<nothing, bool>
  user_id: string
]: any -> record<can_enroll: bool, enrollment_state: int, error_code: int, ready: bool, retryable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assistant/check_ready_status")
  let req_body = {"play_ready_message": $play_ready_message, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Do Not Disturb
#
# POST /assistant/notifications
# operationId: DoNotDisturb
export def "assistant-notifications create-do-not-disturb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # e.g. application/json
]: nothing -> record<notifications_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assistant/notifications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Night Mode settings
#
# POST /assistant/set_night_mode_params
# operationId: NightModesettings
# --windows item shape: {days: list<int>, length_hours: int, start_hour: int}
export def "assistant-set-night-mode-params create-modesettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --demo-to-user: oneof<nothing, bool>
  --do-not-disturb: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  led_brightness: float
  volume: float
  windows: list # item shape: {days: list<int>, length_hours: int, start_hour: int}
]: any -> record<do_not_disturb: bool, enabled: bool, led_brightness: float, volume: float, windows: table<days: list, length_hours: float, start_hour: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assistant/set_night_mode_params")
  let req_body = {"demo_to_user": $demo_to_user, "do_not_disturb": $do_not_disturb, "enabled": $enabled, "led_brightness": $led_brightness, "volume": $volume, "windows": $windows} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Forget paired device
#
# POST /bluetooth/bond
# operationId: Forgetpaireddevice
export def "bluetooth-bond create-forgetpaireddevice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bond: oneof<nothing, bool>
  mac_address: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bluetooth/bond")
  let req_body = {"bond": $bond, "mac_address": $mac_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Pair with Speaker
#
# POST /bluetooth/connect
# operationId: PairwithSpeaker
export def "bluetooth-connect create-pairwith-speaker" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --connect: oneof<nothing, bool>
  mac_address: string
  profile: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bluetooth/connect")
  let req_body = {"connect": $connect, "mac_address": $mac_address, "profile": $profile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Change Discoverability
#
# POST /bluetooth/discovery
# operationId: ChangeDiscoverability
export def "bluetooth-discovery create-change-discoverability" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enable-discovery: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bluetooth/discovery")
  let req_body = {"enable_discovery": $enable_discovery} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Paired Devices
#
# GET /bluetooth/get_bonded
# operationId: GetPairedDevices
export def "bluetooth-get-bonded get-paired-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<bond_date: float, device_class: int, device_type: int, last_connect_date: float, mac_address: string, name: string, rssi: int, service_uuids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bluetooth/get_bonded")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Scan for devices
#
# POST /bluetooth/scan
# operationId: Scanfordevices
export def "bluetooth-scan create-scanfordevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-results: oneof<nothing, bool>
  --enable: oneof<nothing, bool>
  timeout: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bluetooth/scan")
  let req_body = {"clear_results": $clear_results, "enable": $enable, "timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Scan Results
#
# GET /bluetooth/scan_results
# operationId: GetScanResults
export def "bluetooth-scan-results get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<device_class: int, device_type: int, expected_profiles: int, mac_address: string, name: string, rssi: int> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bluetooth/scan_results")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Status
#
# GET /bluetooth/status
# operationId: Status
export def "bluetooth-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<audio_mode: int, connected_devices: table<device: record, enabled_profiles: int>, connecting_devices: list<string>, discovery_enabled: bool, remote_sink: record<bond_date: float, device_class: int, device_type: int, last_connect_date: int, mac_address: string, name: string, rssi: int, service_uuids: list<string>>, scanning_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bluetooth/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Saved Networks
#
# GET /configured_networks
# operationId: GetSavedNetworks
export def "configured-networks get-saved" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ssid: string, wpa_auth: int, wpa_cipher: int, wpa_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configured_networks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Connect to Wi-Fi Network
#
# POST /connect_wifi
# operationId: ConnecttoWi-FiNetwork
export def "connect-wifi create-connectto-wi-fi-network" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bssid: string
  enc_passwd: string
  signal_level: int # format: int32
  ssid: string
  wpa_auth: int # format: int32
  wpa_cipher: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connect_wifi")
  let req_body = {"bssid": $bssid, "enc_passwd": $enc_passwd, "signal_level": $signal_level, "ssid": $ssid, "wpa_auth": $wpa_auth, "wpa_cipher": $wpa_cipher} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Eureka Info
#
# GET /eureka_info
# operationId: EurekaInfo
export def "eureka-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # e.g. version,audio,name,build_info,detail,device_info,net,wifi,setup,settings,opt_in,opencast,multizone,proxy,night_mode_params,user_eq,room_equalizer,sign,aogh,ultrasound,mesh
  --options: string # e.g. detail,sign
  --nonce: int # format: int32, e.g. 1234512345
]: nothing -> record<aogh: record<aogh_api_version: string>, audio: record<digital: bool>, build_info: record<build_type: int, cast_build_revision: string, cast_control_version: int, preview_channel_state: int, release_track: string, system_build_number: string>, detail: record<icon_list: list<record>, locale: record<display_string: string>, timezone: record<display_string: string, offset: int>>, device_info: record<4k_blocked: int, capabilities: record<aogh_supported: bool, assistant_supported: bool, audio_hdr_supported: bool, audio_surround_mode_supported: bool, ble_supported: bool, bluetooth_audio_sink_supported: bool, bluetooth_audio_source_supported: bool, bluetooth_supported: bool, cloudcast_supported: bool, content_filters_supported: bool, display_supported: bool, fdr_supported: bool, hdmi_prefer_50hz_supported: bool, hdmi_prefer_high_fps_supported: bool, hotspot_supported: bool, https_setup_supported: bool, input_management_supported: bool, keep_hotspot_until_connected_supported: bool, multi_user_supported: bool, multichannel_group_supported: bool, multizone_supported: bool, night_mode_supported: bool, night_mode_supported_v2: bool, opencast_supported: bool, preview_channel_supported: bool, reboot_supported: bool, remote_ducking_supported: bool, separate_tts_volume_supported: bool, setup_supported: bool, sleep_mode_supported: bool, stats_supported: bool, system_sound_effects_supported: bool, user_eq_supported: bool, wifi_auto_save_supported: bool, wifi_regulatory_domain_locked: bool, wifi_supported: bool>, cloud_device_id: string, factory_country_code: string, hotspot_bssid: string, local_authorization_token_hash: string, mac_address: string, manufacturer: string, model_name: string, product_name: string, public_key: string, ssdp_udn: string, uma_client_id: string, uptime: float, weave_device_id: string>, multizone: record<audio_output_delay: int, audio_output_delay_hdmi: int, audio_output_delay_oem: int, aux_in_group: string, dynamic_groups: list<string>, groups: list<string>, multichannel_status: int>, name: string, net: record<ethernet_connected: bool, ip_address: string, online: bool>, night_mode_params: record<device_override_do_not_disturb: int, do_not_disturb: bool, enabled: bool, led_brightness: float, volume: float, windows: list<record>>, opencast: record<pin_code: string>, opt_in: record<audio_hdr: bool, audio_surround_mode: int, autoplay_on_signal: bool, cloud_ipc: bool, hdmi_prefer_50hz: bool, hdmi_prefer_high_fps: bool, managed_mode: bool, opencast: bool, preview_channel: bool, remote_ducking: bool, stats: bool, ui_flipped: bool, wpa3_support_enabled: bool>, proxy: record<mode: string>, settings: record<closed_caption: record, control_notifications: int, country_code: string, locale: string, network_standby: int, system_sound_effects: bool, time_format: int, timezone: string, wake_on_cast: int>, setup: record<qr_ssid_suffix: string, setup_state: int, ssid_suffix: string, stats: record<num_check_connectivity: int, num_connect_wifi: int, num_connected_wifi_not_saved: int, num_initial_eureka_info: int, num_obtain_ip: int>, tos_accepted: bool>, sign: record<certificate: string, intermediate_certs: list<string>, nonce: string, signed_data: string>, user_eq: record<high_shelf: record<frequency: int, gain_db: int, quality: float>, low_shelf: record<frequency: int, gain_db: int, quality: float>, max_peaking_eqs: int, peaking_eqs: list<string>>, version: int, wifi: record<bssid: string, has_changes: bool, noise_level: int, signal_level: int, ssid: string, wpa_configured: bool, wpa_id: int, wpa_state: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "params" $params "scalar") (serialize-qp "options" $options "scalar") (serialize-qp "nonce" $nonce "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eureka_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Forget Wi-Fi Network
#
# POST /forget_wifi
# operationId: ForgetWi-FiNetwork
export def "forget-wifi create-wi-fi-network" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  wpa_id: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/forget_wifi")
  let req_body = {"wpa_id": $wpa_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# App Device ID
#
# POST /get_app_device_id
# operationId: AppDeviceID
export def "get-app-device-id create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  app_id: string
]: any -> record<app_device_id: string, certificate: string, signed_data: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/get_app_device_id")
  let req_body = {"app_id": $app_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Chromecast Icon
#
# GET /icon.png
# operationId: ChromecastIcon
export def "icon-png get-chromecast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/icon.png")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Offer
#
# GET /offer
# operationId: Offer
export def "offer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/offer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reboot and Factory Reset
#
# POST /reboot
# operationId: RebootandFactoryReset
export def "reboot reset-rebootand-factory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  params: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reboot")
  let req_body = {"params": $params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Wi-Fi Scan Results
#
# GET /scan_results
# operationId: GetWi-FiScanResults
export def "scan-results get-wi-fi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<bssid: string, signal_level: int, ssid: string, wpa_auth: int, wpa_cipher: int, wpa_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scan_results")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Scan for Networks
#
# POST /scan_wifi
# operationId: ScanforNetworks
export def "scan-wifi create-scanfor-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scan_wifi")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Eureka Info
#
# POST /set_eureka_info
# operationId: SetEurekaInfo
# --opt_in shape: {opencast: bool, preview_channel: bool, remote_ducking: bool, stats: bool}
# --settings shape: {control_notifications: int}
export def "set-eureka-info update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  opt_in: record # e.g. {opencast: true, preview_channel: true, remote_ducking: true, stats: true} — shape: {opencast: bool, preview_channel: bool, remote_ducking: bool, stats: bool}
  settings: record # e.g. {control_notifications: 2} — shape: {control_notifications: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/set_eureka_info")
  let req_body = {"name": $name, "opt_in": $opt_in, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Locales
#
# GET /supported_locales
# operationId: Locales
export def "supported-locales get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<display_string: string, locale: string> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/supported_locales")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Timezones
#
# GET /supported_timezones
# operationId: Timezones
export def "supported-timezones get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<display_string: string, offset: int, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/supported_timezones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test Internet Download Speed
#
# POST /test_internet_download_speed
# operationId: TestInternetDownloadSpeed
export def "test-internet-download-speed test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string
]: any -> record<bytes_received: int, response_code: int, time_for_data_fetch: int, time_for_http_response: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test_internet_download_speed")
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Set Equalizer Values
#
# POST /user_eq/set_equalizer
# operationId: SetEqualizerValues
# --high_shelf shape: {gain_db: int}
# --low_shelf shape: {gain_db: int}
export def "user-eq-set-equalizer update-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  high_shelf: record # e.g. {gain_db: 0} — shape: {gain_db: int}
  low_shelf: record # e.g. {gain_db: 0} — shape: {gain_db: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cast-local-authorization-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_eq/set_equalizer")
  let req_body = {"high_shelf": $high_shelf, "low_shelf": $low_shelf} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
