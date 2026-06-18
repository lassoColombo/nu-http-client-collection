# Auto-generated client for Meraki Dashboard API v0.0.0-streaming
# Source: https://api.apis.guru/v2/specs/meraki.com/0.0.0-streaming/openapi.json
# Auth: --token flag or $env.MERAKI_DASHBOARD_API_TOKEN

const BASE_URL = "https://api.meraki.com/api/v0"
const DEFAULT_AUTH = "x-cisco-meraki-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MERAKI_DASHBOARD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-cisco-meraki-api-key" => { {headers: {X-Cisco-Meraki-API-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.meraki.com/api/v0"] }
def auth-scheme-completer [] { ["x-cisco-meraki-api-key"] }

# Completers for enum parameters
def object-type-completer [] { ["person" "vehicle"] }
def motion-detector-version-completer [] { ["1" "2"] }
def quality-completer [] { ["Enhanced" "High" "Standard"] }
def resolution-completer [] { ["1080x1080" "1280x720" "1920x1080" "2058x2058"] }
def major-minor-assignment-mode-completer [] { ["Non-unique" "Unique"] }
def band-completer [] { ["2.4" "5"] }
def device-policy-completer [] { ["Allowed" "Blocked" "Group policy" "Normal" "Per connection" "Whitelisted"] }
def url-category-list-size-completer [] { ["fullList" "topSites"] }
def uplink-completer [] { ["cellular" "wan1" "wan2"] }
def access-completer [] { ["blocked" "restricted" "unrestricted"] }
def type-completer [] { ["delete" "restrict processing"] }
def ids-rulesets-completer [] { ["balanced" "connectivity" "security"] }
def mode-completer [] { ["detection" "disabled" "prevention"] }
def mode-completer-1 [] { ["disabled" "enabled"] }
def mode-completer-2 [] { ["hub" "none" "spoke"] }
def ssid-number-completer [] { ["0" "1" "10" "11" "12" "13" "14" "2" "3" "4" "5" "6" "7" "8" "9"] }
def auth-mode-completer [] { ["8021x-google" "8021x-localradius" "8021x-meraki" "8021x-nac" "8021x-radius" "ipsk-with-radius" "ipsk-without-radius" "open" "open-enhanced" "open-with-nac" "open-with-radius" "psk"] }
def encryption-mode-completer [] { ["wep" "wpa"] }
def enterprise-admin-access-completer [] { ["access disabled" "access enabled"] }
def radius-failover-policy-completer [] { ["Allow access" "Deny access"] }
def radius-load-balancing-policy-completer [] { ["Round robin" "Strict priority order"] }
def splash-page-completer [] { ["Billing" "Cisco ISE" "Click-through splash page" "Facebook Wi-Fi" "Google Apps domain" "Google OAuth" "None" "Password-protected with Active Directory" "Password-protected with LDAP" "Password-protected with Meraki RADIUS" "Password-protected with custom RADIUS" "SMS authentication" "Sponsored guest" "Systems Manager Sentry"] }
def wpa-encryption-mode-completer [] { ["WPA1 and WPA2" "WPA1 only" "WPA2 only" "WPA3 Transition Mode" "WPA3 only"] }
def protocol-completer [] { ["ANY" "TCP" "UDP"] }
def device-type-completer [] { ["appliance" "combined" "switch" "wireless"] }
def dhcp-handling-completer [] { ["Do not respond to DHCP requests" "Relay DHCP to another server" "Run a DHCP server"] }
def dhcp-lease-time-completer [] { ["1 day" "1 hour" "1 week" "12 hours" "30 minutes" "4 hours"] }
def band-selection-type-completer [] { ["ap" "ssid"] }
def min-bitrate-type-completer [] { ["band" "ssid"] }
def upgrade-strategy-completer [] { ["minimizeClientDowntime" "minimizeUpgradeTime"] }
def status-completer [] { ["completed" "failed" "pending"] }
def authentication-method-completer [] { ["Cisco SecureX Sign-On" "Email"] }
def org-access-completer [] { ["enterprise" "full" "none" "read-only"] }
def state-completer [] { ["active" "expired" "expiring" "recentlyQueued" "unused" "unusedActive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "devices-camera-analytics-live get" } } | get name | first)
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

# Returns live state from camera of analytics zones
#
# GET /devices/{serial}/camera/analytics/live
# operationId: getDeviceCameraAnalyticsLive
export def "devices-camera-analytics-live get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/camera/analytics/live"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an overview of aggregate analytics data for a timespan
#
# GET /devices/{serial}/camera/analytics/overview
# operationId: getDeviceCameraAnalyticsOverview
export def "devices-camera-analytics-overview get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. The default is 1 hour. (format: float)
  --object-type: string@object-type-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "objectType" $object_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/camera/analytics/overview") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns most recent record for analytics zones
#
# GET /devices/{serial}/camera/analytics/recent
# operationId: getDeviceCameraAnalyticsRecent
export def "devices-camera-analytics-recent get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --object-type: string@object-type-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "objectType" $object_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/camera/analytics/recent") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all configured analytic zones for this camera
#
# GET /devices/{serial}/camera/analytics/zones
# operationId: getDeviceCameraAnalyticsZones
export def "devices-camera-analytics-zones get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/camera/analytics/zones"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return historical records for analytic zones
#
# GET /devices/{serial}/camera/analytics/zones/{zoneId}/history
# operationId: getDeviceCameraAnalyticsZoneHistory
export def "devices-camera-analytics-zones-history get" [
  serial: string
  zone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 14 hours after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 14 hours. The default is 1 hour. (format: float)
  --resolution: int # The time resolution in seconds for returned data. The valid resolutions are: 60. The default is 60.
  --object-type: string@object-type-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "objectType" $object_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial: (encode-path-segment $serial), zone_id: (encode-path-segment $zone_id)} | format pattern "/devices/{serial}/camera/analytics/zones/{zone_id}/history") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns quality and retention settings for the given camera
#
# GET /devices/{serial}/camera/qualityAndRetentionSettings
# operationId: getDeviceCameraQualityAndRetentionSettings
export def "devices-camera-quality-and-retention-settings get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/camera/qualityAndRetentionSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update quality and retention settings for the given camera
#
# PUT /devices/{serial}/camera/qualityAndRetentionSettings
# operationId: updateDeviceCameraQualityAndRetentionSettings
export def "devices-camera-quality-and-retention-settings update" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-recording-enabled: oneof<nothing, bool> # Boolean indicating if audio recording is enabled(true) or disabled(false) on the camera
  --motion-based-retention-enabled: oneof<nothing, bool> # Boolean indicating if motion-based retention is enabled(true) or disabled(false) on the camera
  --motion-detector-version: int@motion-detector-version-completer # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  --profile-id: string # The ID of a quality and retention profile to assign to the camera. The profile's settings will override all of the per-camera quality and retention settings. If the value of this parameter is null, any existing profile will be unassigned from the camera.
  --quality: string@quality-completer # Quality of the camera. Can be one of 'Standard', 'High' or 'Enhanced'. Not all qualities are supported by every camera model.
  --resolution: string@resolution-completer # Resolution of the camera. Can be one of '1280x720', '1920x1080', '1080x1080' or '2058x2058'. Not all resolutions are supported by every camera model.
  --restricted-bandwidth-mode-enabled: oneof<nothing, bool> # Boolean indicating if restricted bandwidth is enabled(true) or disabled(false) on the camera. This setting does not apply to MV2 cameras.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/camera/qualityAndRetentionSettings"))
  let req_body = {"audioRecordingEnabled": $audio_recording_enabled, "motionBasedRetentionEnabled": $motion_based_retention_enabled, "motionDetectorVersion": $motion_detector_version, "profileId": $profile_id, "quality": $quality, "resolution": $resolution, "restrictedBandwidthModeEnabled": $restricted_bandwidth_mode_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns video settings for the given camera
#
# GET /devices/{serial}/camera/video/settings
# operationId: getDeviceCameraVideoSettings
export def "devices-camera-video-settings get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/camera/video/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update video settings for the given camera
#
# PUT /devices/{serial}/camera/video/settings
# operationId: updateDeviceCameraVideoSettings
export def "devices-camera-video-settings update" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-rtsp-enabled: oneof<nothing, bool> # Boolean indicating if external rtsp stream is exposed
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/camera/video/settings"))
  let req_body = {"externalRtspEnabled": $external_rtsp_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Show the LAN Settings of a MG
#
# GET /devices/{serial}/cellularGateway/settings
# operationId: getDeviceCellularGatewaySettings
export def "devices-cellular-gateway-settings get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/cellularGateway/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the LAN Settings for a single MG.
#
# PUT /devices/{serial}/cellularGateway/settings
# operationId: updateDeviceCellularGatewaySettings
# --fixedIpAssignments item shape: {ip: string, mac: string, name?: string}
# --reservedIpRanges item shape: {comment: string, end: string, start: string}
export def "devices-cellular-gateway-settings update" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fixed-ip-assignments: list # list of all fixed IP assignments for a single MG — item shape: {ip: string, mac: string, name?: string}
  --reserved-ip-ranges: list # list of all reserved IP ranges for a single MG — item shape: {comment: string, end: string, start: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/cellularGateway/settings"))
  let req_body = {"fixedIpAssignments": $fixed_ip_assignments, "reservedIpRanges": $reserved_ip_ranges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the port forwarding rules for a single MG.
#
# GET /devices/{serial}/cellularGateway/settings/portForwardingRules
# operationId: getDeviceCellularGatewaySettingsPortForwardingRules
export def "devices-cellular-gateway-settings-port-forwarding-rules get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/cellularGateway/settings/portForwardingRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the port forwarding rules for a single MG.
#
# PUT /devices/{serial}/cellularGateway/settings/portForwardingRules
# operationId: updateDeviceCellularGatewaySettingsPortForwardingRules
# --rules item shape: {access: string, allowedIps?: list<string>, lanIp: string, localPort: string, name?: string, protocol: string, publicPort: string}
export def "devices-cellular-gateway-settings-port-forwarding-rules update" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An array of port forwarding params — item shape: {access: string, allowedIps?: list<string>, lanIp: string, localPort: string, name?: string, protocol: string, publicPort: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/cellularGateway/settings/portForwardingRules"))
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the clients of a device, up to a maximum of a month ago
#
# GET /devices/{serial}/clients
# operationId: getDeviceClients
export def "devices-clients get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 31 days. The default is 1 day. (format: float)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/clients") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cycle a set of switch ports
#
# POST /devices/{serial}/switch/ports/cycle
# operationId: cycleDeviceSwitchPorts
export def "devices-switch-ports-cycle create" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ports: list<string> # List of switch ports. Example: [1, 2-5, 1_MA-MOD-8X10G_1, 1_MA-MOD-8X10G_2-1_MA-MOD-8X10G_8]
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/switch/ports/cycle"))
  let req_body = {"ports": $ports} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the status for all the ports of a switch
#
# GET /devices/{serial}/switchPortStatuses
# operationId: getDeviceSwitchPortStatuses
export def "devices-switch-port-statuses get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 31 days. The default is 1 day. (format: float)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/switchPortStatuses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the packet counters for all the ports of a switch
#
# GET /devices/{serial}/switchPortStatuses/packets
# operationId: getDeviceSwitchPortStatusesPackets
export def "devices-switch-port-statuses-packets get" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 1 day from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 1 day. The default is 1 day. (format: float)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/switchPortStatuses/packets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the bluetooth settings for a wireless device
#
# PUT /devices/{serial}/wireless/bluetooth/settings
# operationId: updateDeviceWirelessBluetoothSettings
export def "devices-wireless-bluetooth-settings update" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --major: int # Desired major value of the beacon. If the value is set to null it will reset to Dashboard's automatically generated value.
  --minor: int # Desired minor value of the beacon. If the value is set to null it will reset to Dashboard's automatically generated value.
  --uuid: string # Desired UUID of the beacon. If the value is set to null it will reset to Dashboard's automatically generated value.
]: any -> record<major: int, minor: int, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({serial: (encode-path-segment $serial)} | format pattern "/devices/{serial}/wireless/bluetooth/settings"))
  let req_body = {"major": $major, "minor": $minor, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a network
#
# DELETE /networks/{networkId}
# operationId: deleteNetwork
export def "networks delete" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a network
#
# GET /networks/{networkId}
# operationId: getNetwork
export def "networks get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a network
#
# PUT /networks/{networkId}
# operationId: updateNetwork
export def "networks update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disable-my-meraki-com: oneof<nothing, bool> # Disables the local device status pages (my.meraki.com, ap.meraki.com, switch.meraki.com, wired.meraki.com). Optional (defaults to false)
  --disable-remote-status-page: oneof<nothing, bool> # Disables access to the device status page (http://[device's LAN IP]). Optional. Can only be set if disableMyMerakiCom is set to false
  --enrollment-string: string # A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. Please note that changing this field may cause existing bookmarks to break.
  --name: string # The name of the network
  --tags: string # A space-separated list of tags to be applied to the network
  --time-zone: string # The timezone of the network. For a list of allowed timezones, please see the 'TZ' column in the table in this article.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}"))
  let req_body = {"disableMyMerakiCom": $disable_my_meraki_com, "disableRemoteStatusPage": $disable_remote_status_page, "enrollmentString": $enrollment_string, "name": $name, "tags": $tags, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the access policies for this network
#
# GET /networks/{networkId}/accessPolicies
# operationId: getNetworkAccessPolicies
export def "networks-access-policies get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/accessPolicies"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Air Marshal scan results from a network
#
# GET /networks/{networkId}/airMarshal
# operationId: getNetworkAirMarshal
export def "networks-air-marshal get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 31 days. The default is 7 days. (format: float)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/airMarshal") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the alert configuration for this network
#
# GET /networks/{networkId}/alertSettings
# operationId: getNetworkAlertSettings
export def "networks-alert-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/alertSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the alert configuration for this network
#
# PUT /networks/{networkId}/alertSettings
# operationId: updateNetworkAlertSettings
# --alerts item shape: {alertDestinations?: record, enabled?: bool, filters?: record, type: string}
# --defaultDestinations shape: {allAdmins?: bool, emails?: list<string>, httpServerIds?: list<string>, snmp?: bool}
export def "networks-alert-settings update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alerts: list # Alert-specific configuration for each type. Only alerts that pertain to the network can be updated. — item shape: {alertDestinations?: record, enabled?: bool, filters?: record, type: string}
  --default-destinations: record # The network-wide destinations for all alerts on the network. — shape: {allAdmins?: bool, emails?: list<string>, httpServerIds?: list<string>, snmp?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/alertSettings"))
  let req_body = {"alerts": $alerts, "defaultDestinations": $default_destinations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the inbound firewall rules for an MX network
#
# GET /networks/{networkId}/appliance/firewall/inboundFirewallRules
# operationId: getNetworkApplianceFirewallInboundFirewallRules
export def "networks-appliance-firewall-inbound-firewall-rules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/appliance/firewall/inboundFirewallRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the inbound firewall rules of an MX network
#
# PUT /networks/{networkId}/appliance/firewall/inboundFirewallRules
# operationId: updateNetworkApplianceFirewallInboundFirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
export def "networks-appliance-firewall-inbound-firewall-rules update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslog-default-rule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/appliance/firewall/inboundFirewallRules"))
  let req_body = {"rules": $rules, "syslogDefaultRule": $syslog_default_rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List per-port VLAN settings for all ports of a MX.
#
# GET /networks/{networkId}/appliancePorts
# operationId: getNetworkAppliancePorts
export def "networks-appliance-ports list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/appliancePorts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return per-port VLAN settings for a single MX port.
#
# GET /networks/{networkId}/appliancePorts/{appliancePortId}
# operationId: getNetworkAppliancePort
export def "networks-appliance-ports get" [
  network_id: string
  appliance_port_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), appliance_port_id: (encode-path-segment $appliance_port_id)} | format pattern "/networks/{network_id}/appliancePorts/{appliance_port_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the per-port VLAN settings for a single MX port.
#
# PUT /networks/{networkId}/appliancePorts/{appliancePortId}
# operationId: updateNetworkAppliancePort
export def "networks-appliance-ports update" [
  network_id: string
  appliance_port_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-policy: string # The name of the policy. Only applicable to Access ports. Valid values are: 'open', '8021x-radius', 'mac-radius', 'hybris-radius' for MX64 or Z3 or any MX supporting the per port authentication feature. Otherwise, 'open' is the only valid value and 'open' is the default value if the field is missing.
  --allowed-vlans: string # Comma-delimited list of the VLAN ID's allowed on the port, or 'all' to permit all VLAN's on the port.
  --drop-untagged-traffic: oneof<nothing, bool> # Trunk port can Drop all Untagged traffic. When true, no VLAN is required. Access ports cannot have dropUntaggedTraffic set to true.
  --enabled: oneof<nothing, bool> # The status of the port
  --type: string # The type of the port: 'access' or 'trunk'.
  --vlan: int # Native VLAN when the port is in Trunk mode. Access VLAN when the port is in Access mode.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), appliance_port_id: (encode-path-segment $appliance_port_id)} | format pattern "/networks/{network_id}/appliancePorts/{appliance_port_id}"))
  let req_body = {"accessPolicy": $access_policy, "allowedVlans": $allowed_vlans, "dropUntaggedTraffic": $drop_untagged_traffic, "enabled": $enabled, "type": $type, "vlan": $vlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bind a network to a template.
#
# POST /networks/{networkId}/bind
# operationId: bindNetwork
export def "networks-bind create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-bind: oneof<nothing, bool> # Optional boolean indicating whether the network's switches should automatically bind to profiles of the same model. Defaults to false if left unspecified. This option only affects switch networks and switch templates. Auto-bind is not valid unless the switch template has at least one profile and has at most one profile per switch model.
  config_template_id: string # The ID of the template to which the network should be bound.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/bind"))
  let req_body = {"autoBind": $auto_bind, "configTemplateId": $config_template_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the Bluetooth clients seen by APs in this network
#
# GET /networks/{networkId}/bluetoothClients
# operationId: getNetworkBluetoothClients
export def "networks-bluetooth-clients list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 7 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 7 days. The default is 1 day. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 5 - 1000. Default is 10.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --include-connectivity-history: oneof<nothing, bool> # Include the connectivity history for this client
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar") (serialize-qp "includeConnectivityHistory" $include_connectivity_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/bluetoothClients") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a Bluetooth client
#
# GET /networks/{networkId}/bluetoothClients/{bluetoothClientId}
# operationId: getNetworkBluetoothClient
export def "networks-bluetooth-clients get" [
  network_id: string
  bluetooth_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-connectivity-history: oneof<nothing, bool> # Include the connectivity history for this client
  --connectivity-history-timespan: int # The timespan, in seconds, for the connectivityHistory data. By default 1 day, 86400, will be used.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeConnectivityHistory" $include_connectivity_history "scalar") (serialize-qp "connectivityHistoryTimespan" $connectivity_history_timespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), bluetooth_client_id: (encode-path-segment $bluetooth_client_id)} | format pattern "/networks/{network_id}/bluetoothClients/{bluetooth_client_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the Bluetooth settings for a network. Bluetooth settings (https://documentation.meraki.com/MR/Bluetooth/Bluetooth_Low_Energy_(BLE)) must be enabled on the network.
#
# GET /networks/{networkId}/bluetoothSettings
# operationId: getNetworkBluetoothSettings
export def "networks-bluetooth-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<advertisingEnabled: bool, major: int, majorMinorAssignmentMode: string, minor: int, scanningEnabled: bool, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/bluetoothSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Bluetooth settings for a network
#
# PUT /networks/{networkId}/bluetoothSettings
# operationId: updateNetworkBluetoothSettings
export def "networks-bluetooth-settings update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertising-enabled: oneof<nothing, bool> # Whether APs will advertise beacons.
  --major: int # The major number to be used in the beacon identifier. Only valid in 'Non-unique' mode.
  --major-minor-assignment-mode: string@major-minor-assignment-mode-completer # The way major and minor number should be assigned to nodes in the network. ('Unique', 'Non-unique')
  --minor: int # The minor number to be used in the beacon identifier. Only valid in 'Non-unique' mode.
  --scanning-enabled: oneof<nothing, bool> # Whether APs will scan for Bluetooth enabled clients.
  --uuid: string # The UUID to be used in the beacon identifier.
]: any -> record<advertisingEnabled: bool, major: int, majorMinorAssignmentMode: string, minor: int, scanningEnabled: bool, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/bluetoothSettings"))
  let req_body = {"advertisingEnabled": $advertising_enabled, "major": $major, "majorMinorAssignmentMode": $major_minor_assignment_mode, "minor": $minor, "scanningEnabled": $scanning_enabled, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the quality retention profiles for this network
#
# GET /networks/{networkId}/camera/qualityRetentionProfiles
# operationId: getNetworkCameraQualityRetentionProfiles
export def "networks-camera-quality-retention-profiles list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/camera/qualityRetentionProfiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates new quality retention profile for this network.
#
# POST /networks/{networkId}/camera/qualityRetentionProfiles
# operationId: createNetworkCameraQualityRetentionProfile
# --videoSettings shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
export def "networks-camera-quality-retention-profiles create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-recording-enabled: oneof<nothing, bool> # Whether or not to record audio. Can be either true or false. Defaults to false.
  --cloud-archive-enabled: oneof<nothing, bool> # Create redundant video backup using Cloud Archive. Can be either true or false. Defaults to false.
  --max-retention-days: int # The maximum number of days for which the data will be stored, or 'null' to keep data until storage space runs out. If the former, it can be one of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 30, 60, 90] days.
  --motion-based-retention-enabled: oneof<nothing, bool> # Deletes footage older than 3 days in which no motion was detected. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --motion-detector-version: int # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  name: string # The name of the new profile. Must be unique. This parameter is required.
  --restricted-bandwidth-mode-enabled: oneof<nothing, bool> # Disable features that require additional bandwidth such as Motion Recap. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --schedule-id: string # Schedule for which this camera will record video, or 'null' to always record.
  --video-settings: record # Video quality and resolution settings for all the camera models. — shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/camera/qualityRetentionProfiles"))
  let req_body = {"audioRecordingEnabled": $audio_recording_enabled, "cloudArchiveEnabled": $cloud_archive_enabled, "maxRetentionDays": $max_retention_days, "motionBasedRetentionEnabled": $motion_based_retention_enabled, "motionDetectorVersion": $motion_detector_version, "name": $name, "restrictedBandwidthModeEnabled": $restricted_bandwidth_mode_enabled, "scheduleId": $schedule_id, "videoSettings": $video_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an existing quality retention profile for this network.
#
# DELETE /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# operationId: deleteNetworkCameraQualityRetentionProfile
export def "networks-camera-quality-retention-profiles delete" [
  network_id: string
  quality_retention_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), quality_retention_profile_id: (encode-path-segment $quality_retention_profile_id)} | format pattern "/networks/{network_id}/camera/qualityRetentionProfiles/{quality_retention_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single quality retention profile
#
# GET /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# operationId: getNetworkCameraQualityRetentionProfile
export def "networks-camera-quality-retention-profiles get" [
  network_id: string
  quality_retention_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), quality_retention_profile_id: (encode-path-segment $quality_retention_profile_id)} | format pattern "/networks/{network_id}/camera/qualityRetentionProfiles/{quality_retention_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing quality retention profile for this network.
#
# PUT /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# operationId: updateNetworkCameraQualityRetentionProfile
# --videoSettings shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
export def "networks-camera-quality-retention-profiles update" [
  network_id: string
  quality_retention_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-recording-enabled: oneof<nothing, bool> # Whether or not to record audio. Can be either true or false. Defaults to false.
  --cloud-archive-enabled: oneof<nothing, bool> # Create redundant video backup using Cloud Archive. Can be either true or false. Defaults to false.
  --max-retention-days: int # The maximum number of days for which the data will be stored, or 'null' to keep data until storage space runs out. If the former, it can be one of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 30, 60, 90] days.
  --motion-based-retention-enabled: oneof<nothing, bool> # Deletes footage older than 3 days in which no motion was detected. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --motion-detector-version: int # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  --name: string # The name of the new profile. Must be unique.
  --restricted-bandwidth-mode-enabled: oneof<nothing, bool> # Disable features that require additional bandwidth such as Motion Recap. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --schedule-id: string # Schedule for which this camera will record video, or 'null' to always record.
  --video-settings: record # Video quality and resolution settings for all the camera models. — shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), quality_retention_profile_id: (encode-path-segment $quality_retention_profile_id)} | format pattern "/networks/{network_id}/camera/qualityRetentionProfiles/{quality_retention_profile_id}"))
  let req_body = {"audioRecordingEnabled": $audio_recording_enabled, "cloudArchiveEnabled": $cloud_archive_enabled, "maxRetentionDays": $max_retention_days, "motionBasedRetentionEnabled": $motion_based_retention_enabled, "motionDetectorVersion": $motion_detector_version, "name": $name, "restrictedBandwidthModeEnabled": $restricted_bandwidth_mode_enabled, "scheduleId": $schedule_id, "videoSettings": $video_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of all camera recording schedules.
#
# GET /networks/{networkId}/camera/schedules
# operationId: getNetworkCameraSchedules
export def "networks-camera-schedules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/camera/schedules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a snapshot of what the camera sees at the specified time and return a link to that image.
#
# POST /networks/{networkId}/cameras/{serial}/snapshot
# operationId: generateNetworkCameraSnapshot
export def "networks-cameras-snapshot generate" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fullframe: oneof<nothing, bool> # [optional] If set to "true" the snapshot will be taken at full sensor resolution. This will error if used with timestamp.
  --timestamp: string # [optional] The snapshot will be taken from this time on the camera. The timestamp is expected to be in ISO 8601 format. If no timestamp is specified, we will assume current time. (format: date-time)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/cameras/{serial}/snapshot"))
  let req_body = {"fullframe": $fullframe, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns video link to the specified camera
#
# GET /networks/{networkId}/cameras/{serial}/videoLink
# operationId: getNetworkCameraVideoLink
export def "networks-cameras-video-link get" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # [optional] The video link will start at this timestamp. The timestamp is in UNIX Epoch time (milliseconds). If no timestamp is specified, we will assume current time.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/cameras/{serial}/videoLink") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the cellular firewall rules for an MX network
#
# GET /networks/{networkId}/cellularFirewallRules
# operationId: getNetworkCellularFirewallRules
export def "networks-cellular-firewall-rules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/cellularFirewallRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the cellular firewall rules of an MX network
#
# PUT /networks/{networkId}/cellularFirewallRules
# operationId: updateNetworkCellularFirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
export def "networks-cellular-firewall-rules update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/cellularFirewallRules"))
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the clients that have used this network in the timespan
#
# GET /networks/{networkId}/clients
# operationId: getNetworkClients
export def "networks-clients list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 31 days. The default is 1 day. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 10.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> record<description: string, firstSeen: int, groupPolicy8021x: string, id: string, ip: string, ip6: string, ip6Local: string, lastSeen: int, mac: string, manufacturer: string, notes: string, os: string, recentDeviceMac: string, recentDeviceName: string, recentDeviceSerial: string, smInstalled: bool, ssid: string, status: string, switchport: string, usage: record<recv: float, sent: float>, user: string, vlan: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/clients") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated connectivity info for this network, grouped by clients
#
# GET /networks/{networkId}/clients/connectionStats
# operationId: getNetworkClientsConnectionStats
export def "networks-clients-connection-stats list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/clients/connectionStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for this network, grouped by clients
#
# GET /networks/{networkId}/clients/latencyStats
# operationId: getNetworkClientsLatencyStats
export def "networks-clients-latency-stats list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/clients/latencyStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provisions a client with a name and policy
#
# POST /networks/{networkId}/clients/provision
# operationId: provisionNetworkClients
# --policiesBySecurityAppliance shape: {devicePolicy?: "Blocked"|"Normal"|"Whitelisted"}
# --policiesBySsid shape: {0?: record, 1?: record, 2?: record, 3?: record, 4?: record, 5?: record, 6?: record, 7?: record, 8?: record, 9?: record, 10?: record, 11?: record, 12?: record, 13?: record, 14?: record}
export def "networks-clients-provision create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_policy: string@device-policy-completer # The policy to apply to the specified client. Can be 'Group policy', 'Whitelisted', 'Allowed', 'Blocked', 'Per connection' or 'Normal'. Required.
  --group-policy-id: string # The ID of the desired group policy to apply to the client. Required if 'devicePolicy' is set to "Group policy". Otherwise this is ignored.
  mac: string # The MAC address of the client. Required.
  --name: string # The display name for the client. Optional. Limited to 255 bytes.
  --policies-by-security-appliance: record # An object, describing what the policy-connection association is for the security appliance. (Only relevant if the security appliance is actually within the network) — shape: {devicePolicy?: "Blocked"|"Normal"|"Whitelisted"}
  --policies-by-ssid: record # An object, describing the policy-connection associations for each active SSID within the network. Keys should be the number of enabled SSIDs, mapping to an object describing the client's policy — shape: {0?: record, 1?: record, 2?: record, 3?: record, 4?: record, 5?: record, 6?: record, 7?: record, 8?: record, 9?: record, 10?: record, 11?: record, 12?: record, 13?: record, 14?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/clients/provision"))
  let req_body = {"devicePolicy": $device_policy, "groupPolicyId": $group_policy_id, "mac": $mac, "name": $name, "policiesBySecurityAppliance": $policies_by_security_appliance, "policiesBySsid": $policies_by_ssid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the client associated with the given identifier
#
# GET /networks/{networkId}/clients/{clientId}
# operationId: getNetworkClient
export def "networks-clients get" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated connectivity info for a given client on this network
#
# GET /networks/{networkId}/clients/{clientId}/connectionStats
# operationId: getNetworkClientConnectionStats
export def "networks-clients-connection-stats get" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/connectionStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the events associated with this client
#
# GET /networks/{networkId}/clients/{clientId}/events
# operationId: getNetworkClientEvents
export def "networks-clients-events get" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 100. Default is 100.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the latency history for a client
#
# GET /networks/{networkId}/clients/{clientId}/latencyHistory
# operationId: getNetworkClientLatencyHistory
export def "networks-clients-latency-history get" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 791 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 791 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 791 days. The default is 1 day. (format: float)
  --resolution: int # The time resolution in seconds for returned data. The valid resolutions are: 86400. The default is 86400.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "resolution" $resolution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/latencyHistory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for a given client on this network
#
# GET /networks/{networkId}/clients/{clientId}/latencyStats
# operationId: getNetworkClientLatencyStats
export def "networks-clients-latency-stats get" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/latencyStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the policy assigned to a client on the network
#
# GET /networks/{networkId}/clients/{clientId}/policy
# operationId: getNetworkClientPolicy
export def "networks-clients-policy get" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/policy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the policy assigned to a client on the network
#
# PUT /networks/{networkId}/clients/{clientId}/policy
# operationId: updateNetworkClientPolicy
export def "networks-clients-policy update" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_policy: string # The policy to assign. Can be 'Whitelisted', 'Blocked', 'Normal' or 'Group policy'. Required.
  --group-policy-id: string # [optional] If 'devicePolicy' is set to 'Group policy' this param is used to specify the group policy ID.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/policy"))
  let req_body = {"devicePolicy": $device_policy, "groupPolicyId": $group_policy_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the splash authorization for a client, for each SSID they've associated with through splash
#
# GET /networks/{networkId}/clients/{clientId}/splashAuthorizationStatus
# operationId: getNetworkClientSplashAuthorizationStatus
export def "networks-clients-splash-authorization-status get" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/splashAuthorizationStatus"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a client's splash authorization
#
# PUT /networks/{networkId}/clients/{clientId}/splashAuthorizationStatus
# operationId: updateNetworkClientSplashAuthorizationStatus
# --ssids shape: {0?: record, 1?: record, 2?: record, 3?: record, 4?: record, 5?: record, 6?: record, 7?: record, 8?: record, 9?: record, 10?: record, 11?: record, 12?: record, 13?: record, 14?: record}
export def "networks-clients-splash-authorization-status update" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ssids: record # The target SSIDs. Each SSID must be enabled and must have Click-through splash enabled. For each SSID where isAuthorized is true, the expiration time will automatically be set according to the SSID's splash frequency. Not all networks support configuring all SSIDs — shape: {0?: record, 1?: record, 2?: record, 3?: record, 4?: record, 5?: record, 6?: record, 7?: record, 8?: record, 9?: record, 10?: record, 11?: record, 12?: record, 13?: record, 14?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/splashAuthorizationStatus"))
  let req_body = {"ssids": $ssids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the client's daily usage history
#
# GET /networks/{networkId}/clients/{clientId}/usageHistory
# operationId: getNetworkClientUsageHistory
export def "networks-clients-usage-history get" [
  network_id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), client_id: (encode-path-segment $client_id)} | format pattern "/networks/{network_id}/clients/{client_id}/usageHistory"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated connectivity info for this network
#
# GET /networks/{networkId}/connectionStats
# operationId: getNetworkConnectionStats
export def "networks-connection-stats get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/connectionStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the content filtering settings for an MX network
#
# GET /networks/{networkId}/contentFiltering
# operationId: getNetworkContentFiltering
export def "networks-content-filtering get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/contentFiltering"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the content filtering settings for an MX network
#
# PUT /networks/{networkId}/contentFiltering
# operationId: updateNetworkContentFiltering
export def "networks-content-filtering update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-url-patterns: list<string> # A list of URL patterns that are allowed
  --blocked-url-categories: list<string> # A list of URL categories to block
  --blocked-url-patterns: list<string> # A list of URL patterns that are blocked
  --url-category-list-size: string@url-category-list-size-completer # URL category list size which is either 'topSites' or 'fullList'
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/contentFiltering"))
  let req_body = {"allowedUrlPatterns": $allowed_url_patterns, "blockedUrlCategories": $blocked_url_categories, "blockedUrlPatterns": $blocked_url_patterns, "urlCategoryListSize": $url_category_list_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all available content filtering categories for an MX network
#
# GET /networks/{networkId}/contentFiltering/categories
# operationId: getNetworkContentFilteringCategories
export def "networks-content-filtering-categories get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/contentFiltering/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the devices in a network
#
# GET /networks/{networkId}/devices
# operationId: getNetworkDevices
export def "networks-devices list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/devices"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Claim devices into a network. (Note: for recently claimed devices, it may take a few minutes for API requests against that device to succeed)
#
# POST /networks/{networkId}/devices/claim
# operationId: claimNetworkDevices
export def "networks-devices-claim create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --serial: string # [DEPRECATED] The serial of a device to claim
  --serials: list<string> # A list of serials of devices to claim
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/devices/claim"))
  let req_body = {"serial": $serial, "serials": $serials} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Aggregated connectivity info for this network, grouped by node
#
# GET /networks/{networkId}/devices/connectionStats
# operationId: getNetworkDevicesConnectionStats
export def "networks-devices-connection-stats list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/devices/connectionStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for this network, grouped by node
#
# GET /networks/{networkId}/devices/latencyStats
# operationId: getNetworkDevicesLatencyStats
export def "networks-devices-latency-stats list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/devices/latencyStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a single device
#
# GET /networks/{networkId}/devices/{serial}
# operationId: getNetworkDevice
export def "networks-devices get" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the attributes of a device
#
# PUT /networks/{networkId}/devices/{serial}
# operationId: updateNetworkDevice
export def "networks-devices update" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The address of a device
  --floor-plan-id: string # The floor plan to associate to this device. null disassociates the device from the floorplan.
  --lat: float # The latitude of a device (format: float)
  --lng: float # The longitude of a device (format: float)
  --move-map-marker: oneof<nothing, bool> # Whether or not to set the latitude and longitude of a device based on the new address. Only applies when lat and lng are not specified.
  --name: string # The name of a device
  --notes: string # The notes for the device. String. Limited to 255 characters.
  --switch-profile-id: string # The ID of a switch profile to bind to the device (for available switch profiles, see the 'Switch Profiles' endpoint). Use null to unbind the switch device from the current profile. For a device to be bindable to a switch profile, it must (1) be a switch, and (2) belong to a network that is bound to a configuration template.
  --tags: string # The tags of a device
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}"))
  let req_body = {"address": $address, "floorPlanId": $floor_plan_id, "lat": $lat, "lng": $lng, "moveMapMarker": $move_map_marker, "name": $name, "notes": $notes, "switchProfileId": $switch_profile_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Aggregated connectivity info for a given AP on this network
#
# GET /networks/{networkId}/devices/{serial}/connectionStats
# operationId: getNetworkDeviceConnectionStats
export def "networks-devices-connection-stats get" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}/connectionStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for a given AP on this network
#
# GET /networks/{networkId}/devices/{serial}/latencyStats
# operationId: getNetworkDeviceLatencyStats
export def "networks-devices-latency-stats get" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}/latencyStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the uplink loss percentage and latency in milliseconds for a wired network device.
#
# GET /networks/{networkId}/devices/{serial}/lossAndLatencyHistory
# operationId: getNetworkDeviceLossAndLatencyHistory
export def "networks-devices-loss-and-latency-history get" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 60 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 31 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 31 days. The default is 1 day. (format: float)
  --resolution: int # The time resolution in seconds for returned data. The valid resolutions are: 60, 600, 3600, 86400. The default is 60.
  --uplink: string@uplink-completer # The WAN uplink used to obtain the requested stats. Valid uplinks are wan1, wan2, cellular. The default is wan1.
  --ip: string # The destination IP used to obtain the requested stats. This is required.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "uplink" $uplink "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}/lossAndLatencyHistory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the performance score for a single MX
#
# GET /networks/{networkId}/devices/{serial}/performance
# operationId: getNetworkDevicePerformance
export def "networks-devices-performance get" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}/performance"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reboot a device
#
# POST /networks/{networkId}/devices/{serial}/reboot
# operationId: rebootNetworkDevice
export def "networks-devices-reboot create" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}/reboot"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a single device
#
# POST /networks/{networkId}/devices/{serial}/remove
# operationId: removeNetworkDevice
export def "networks-devices-remove delete" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}/remove"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the uplink information for a device.
#
# GET /networks/{networkId}/devices/{serial}/uplink
# operationId: getNetworkDeviceUplink
export def "networks-devices-uplink get" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}/uplink"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the SSID statuses of an access point
#
# GET /networks/{networkId}/devices/{serial}/wireless/status
# operationId: getNetworkDeviceWirelessStatus
export def "networks-devices-wireless-status get" [
  network_id: string
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), serial: (encode-path-segment $serial)} | format pattern "/networks/{network_id}/devices/{serial}/wireless/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the events for the network
#
# GET /networks/{networkId}/events
# operationId: getNetworkEvents
export def "networks-events get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-type: string # The product type to fetch events for. This parameter is required for networks with multiple device types. Valid types are wireless, appliance, switch, systemsManager, camera, cellularGateway, and environmental
  --included-event-types: list<string> # A list of event types. The returned events will be filtered to only include events with these types.
  --excluded-event-types: list<string> # A list of event types. The returned events will be filtered to exclude events with these types.
  --device-mac: string # The MAC address of the Meraki device which the list of events will be filtered with
  --device-serial: string # The serial of the Meraki device which the list of events will be filtered with
  --device-name: string # The name of the Meraki device which the list of events will be filtered with
  --client-ip: string # The IP of the client which the list of events will be filtered with. Only supported for track-by-IP networks.
  --client-mac: string # The MAC address of the client which the list of events will be filtered with. Only supported for track-by-MAC networks.
  --client-name: string # The name, or partial name, of the client which the list of events will be filtered with
  --sm-device-mac: string # The MAC address of the Systems Manager device which the list of events will be filtered with
  --sm-device-name: string # The name of the Systems Manager device which the list of events will be filtered with
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 10.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productType" $product_type "scalar") (serialize-qp "includedEventTypes" $included_event_types "csv") (serialize-qp "excludedEventTypes" $excluded_event_types "csv") (serialize-qp "deviceMac" $device_mac "scalar") (serialize-qp "deviceSerial" $device_serial "scalar") (serialize-qp "deviceName" $device_name "scalar") (serialize-qp "clientIp" $client_ip "scalar") (serialize-qp "clientMac" $client_mac "scalar") (serialize-qp "clientName" $client_name "scalar") (serialize-qp "smDeviceMac" $sm_device_mac "scalar") (serialize-qp "smDeviceName" $sm_device_name "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the event type to human-readable description
#
# GET /networks/{networkId}/events/eventTypes
# operationId: getNetworkEventsEventTypes
export def "networks-events-event-types get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/events/eventTypes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all failed client connection events on this network in a given time range
#
# GET /networks/{networkId}/failedConnections
# operationId: getNetworkFailedConnections
export def "networks-failed-connections get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --serial: string # Filter by AP
  --client-id: string # Filter by client MAC
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "clientId" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/failedConnections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the appliance services and their accessibility rules
#
# GET /networks/{networkId}/firewalledServices
# operationId: getNetworkFirewalledServices
export def "networks-firewalled-services list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/firewalledServices"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the accessibility settings of the given service ('ICMP', 'web', or 'SNMP')
#
# GET /networks/{networkId}/firewalledServices/{service}
# operationId: getNetworkFirewalledService
export def "networks-firewalled-services get" [
  network_id: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), service: (encode-path-segment $service)} | format pattern "/networks/{network_id}/firewalledServices/{service}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the accessibility settings for the given service ('ICMP', 'web', or 'SNMP')
#
# PUT /networks/{networkId}/firewalledServices/{service}
# operationId: updateNetworkFirewalledService
export def "networks-firewalled-services update" [
  network_id: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access: string@access-completer # A string indicating the rule for which IPs are allowed to use the specified service. Acceptable values are "blocked" (no remote IPs can access the service), "restricted" (only whitelisted IPs can access the service), and "unrestriced" (any remote IP can access the service). This field is required
  --allowed-ips: list<string> # An array of whitelisted IPs that can access the service. This field is required if "access" is set to "restricted". Otherwise this field is ignored
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), service: (encode-path-segment $service)} | format pattern "/networks/{network_id}/firewalledServices/{service}"))
  let req_body = {"access": $access, "allowedIps": $allowed_ips} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the floor plans that belong to your network
#
# GET /networks/{networkId}/floorPlans
# operationId: getNetworkFloorPlans
export def "networks-floor-plans list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/floorPlans"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a floor plan
#
# POST /networks/{networkId}/floorPlans
# operationId: createNetworkFloorPlan
# --bottomLeftCorner shape: {lat?: float, lng?: float}
# --bottomRightCorner shape: {lat?: float, lng?: float}
# --center shape: {lat?: float, lng?: float}
# --topLeftCorner shape: {lat?: float, lng?: float}
# --topRightCorner shape: {lat?: float, lng?: float}
export def "networks-floor-plans create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bottom-left-corner: record # The longitude and latitude of the bottom left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --bottom-right-corner: record # The longitude and latitude of the bottom right corner of your floor plan. — shape: {lat?: float, lng?: float}
  --center: record # The longitude and latitude of the center of your floor plan. The 'center' or two adjacent corners (e.g. 'topLeftCorner' and 'bottomLeftCorner') must be specified. If 'center' is specified, the floor plan is placed over that point with no rotation. If two adjacent corners are specified, the floor plan is rotated to line up with the two specified points. The aspect ratio of the floor plan's image is preserved regardless of which corners/center are specified. (This means if that more than two corners are specified, only two corners may be used to preserve the floor plan's aspect ratio.). No two points can have the same latitude, longitude pair. — shape: {lat?: float, lng?: float}
  image_contents: string # The file contents (a base 64 encoded string) of your image. Supported formats are PNG, GIF, and JPG. Note that all images are saved as PNG files, regardless of the format they are uploaded in. (format: byte)
  name: string # The name of your floor plan.
  --top-left-corner: record # The longitude and latitude of the top left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --top-right-corner: record # The longitude and latitude of the top right corner of your floor plan. — shape: {lat?: float, lng?: float}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/floorPlans"))
  let req_body = {"bottomLeftCorner": $bottom_left_corner, "bottomRightCorner": $bottom_right_corner, "center": $center, "imageContents": $image_contents, "name": $name, "topLeftCorner": $top_left_corner, "topRightCorner": $top_right_corner} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Destroy a floor plan
#
# DELETE /networks/{networkId}/floorPlans/{floorPlanId}
# operationId: deleteNetworkFloorPlan
export def "networks-floor-plans delete" [
  network_id: string
  floor_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), floor_plan_id: (encode-path-segment $floor_plan_id)} | format pattern "/networks/{network_id}/floorPlans/{floor_plan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a floor plan by ID
#
# GET /networks/{networkId}/floorPlans/{floorPlanId}
# operationId: getNetworkFloorPlan
export def "networks-floor-plans get" [
  network_id: string
  floor_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), floor_plan_id: (encode-path-segment $floor_plan_id)} | format pattern "/networks/{network_id}/floorPlans/{floor_plan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a floor plan's geolocation and other meta data
#
# PUT /networks/{networkId}/floorPlans/{floorPlanId}
# operationId: updateNetworkFloorPlan
# --bottomLeftCorner shape: {lat?: float, lng?: float}
# --bottomRightCorner shape: {lat?: float, lng?: float}
# --center shape: {lat?: float, lng?: float}
# --topLeftCorner shape: {lat?: float, lng?: float}
# --topRightCorner shape: {lat?: float, lng?: float}
export def "networks-floor-plans update" [
  network_id: string
  floor_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bottom-left-corner: record # The longitude and latitude of the bottom left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --bottom-right-corner: record # The longitude and latitude of the bottom right corner of your floor plan. — shape: {lat?: float, lng?: float}
  --center: record # The longitude and latitude of the center of your floor plan. If you want to change the geolocation data of your floor plan, either the 'center' or two adjacent corners (e.g. 'topLeftCorner' and 'bottomLeftCorner') must be specified. If 'center' is specified, the floor plan is placed over that point with no rotation. If two adjacent corners are specified, the floor plan is rotated to line up with the two specified points. The aspect ratio of the floor plan's image is preserved regardless of which corners/center are specified. (This means if that more than two corners are specified, only two corners may be used to preserve the floor plan's aspect ratio.). No two points can have the same latitude, longitude pair. — shape: {lat?: float, lng?: float}
  --image-contents: string # The file contents (a base 64 encoded string) of your new image. Supported formats are PNG, GIF, and JPG. Note that all images are saved as PNG files, regardless of the format they are uploaded in. If you upload a new image, and you do NOT specify any new geolocation fields ('center, 'topLeftCorner', etc), the floor plan will be recentered with no rotation in order to maintain the aspect ratio of your new image. (format: byte)
  --name: string # The name of your floor plan.
  --top-left-corner: record # The longitude and latitude of the top left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --top-right-corner: record # The longitude and latitude of the top right corner of your floor plan. — shape: {lat?: float, lng?: float}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), floor_plan_id: (encode-path-segment $floor_plan_id)} | format pattern "/networks/{network_id}/floorPlans/{floor_plan_id}"))
  let req_body = {"bottomLeftCorner": $bottom_left_corner, "bottomRightCorner": $bottom_right_corner, "center": $center, "imageContents": $image_contents, "name": $name, "topLeftCorner": $top_left_corner, "topRightCorner": $top_right_corner} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the L3 firewall rules for an MX network
#
# GET /networks/{networkId}/l3FirewallRules
# operationId: getNetworkL3FirewallRules
export def "networks-l3-firewall-rules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/l3FirewallRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the L3 firewall rules of an MX network
#
# PUT /networks/{networkId}/l3FirewallRules
# operationId: updateNetworkL3FirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
export def "networks-l3-firewall-rules update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslog-default-rule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/l3FirewallRules"))
  let req_body = {"rules": $rules, "syslogDefaultRule": $syslog_default_rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the MX L7 firewall rules for an MX network
#
# GET /networks/{networkId}/l7FirewallRules
# operationId: getNetworkL7FirewallRules
export def "networks-l7-firewall-rules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/l7FirewallRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the MX L7 firewall rules for an MX network
#
# PUT /networks/{networkId}/l7FirewallRules
# operationId: updateNetworkL7FirewallRules
# --rules item shape: {policy?: "deny", type?: "application"|"applicationCategory"|"host"|"ipRange"|"port", value?: string}
export def "networks-l7-firewall-rules update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the MX L7 firewall rules — item shape: {policy?: "deny", type?: "application"|"applicationCategory"|"host"|"ipRange"|"port", value?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/l7FirewallRules"))
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the L7 firewall application categories and their associated applications for an MX network
#
# GET /networks/{networkId}/l7FirewallRules/applicationCategories
# operationId: getNetworkL7FirewallRulesApplicationCategories
export def "networks-l7-firewall-rules-application-categories get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/l7FirewallRules/applicationCategories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for this network
#
# GET /networks/{networkId}/latencyStats
# operationId: getNetworkLatencyStats
export def "networks-latency-stats get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 180 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 7 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 7 days. (format: float)
  --band: string@band-completer # Filter results by band (either '2.4' or '5'). Note that data prior to February 2020 will not have band information.
  --ssid: int # Filter results by SSID
  --vlan: int # Filter results by VLAN
  --ap-tag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $ap_tag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/latencyStats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the splash or RADIUS users configured under Meraki Authentication for a network
#
# GET /networks/{networkId}/merakiAuthUsers
# operationId: getNetworkMerakiAuthUsers
export def "networks-meraki-auth-users list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/merakiAuthUsers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the Meraki Auth splash or RADIUS user
#
# GET /networks/{networkId}/merakiAuthUsers/{merakiAuthUserId}
# operationId: getNetworkMerakiAuthUser
export def "networks-meraki-auth-users get" [
  network_id: string
  meraki_auth_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), meraki_auth_user_id: (encode-path-segment $meraki_auth_user_id)} | format pattern "/networks/{network_id}/merakiAuthUsers/{meraki_auth_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the 1:Many NAT mapping rules for an MX network
#
# GET /networks/{networkId}/oneToManyNatRules
# operationId: getNetworkOneToManyNatRules
export def "networks-one-to-many-nat-rules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/oneToManyNatRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the 1:Many NAT mapping rules for an MX network
#
# PUT /networks/{networkId}/oneToManyNatRules
# operationId: updateNetworkOneToManyNatRules
# --rules item shape: {portRules: list, publicIp: string, uplink: "internet1"|"internet2"}
export def "networks-one-to-many-nat-rules update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rules: list # An array of 1:Many nat rules — item shape: {portRules: list, publicIp: string, uplink: "internet1"|"internet2"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/oneToManyNatRules"))
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the 1:1 NAT mapping rules for an MX network
#
# GET /networks/{networkId}/oneToOneNatRules
# operationId: getNetworkOneToOneNatRules
export def "networks-one-to-one-nat-rules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/oneToOneNatRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the 1:1 NAT mapping rules for an MX network
#
# PUT /networks/{networkId}/oneToOneNatRules
# operationId: updateNetworkOneToOneNatRules
# --rules item shape: {allowedInbound?: list, lanIp: string, name?: string, publicIp?: string, uplink?: "internet1"|"internet2"}
export def "networks-one-to-one-nat-rules update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rules: list # An array of 1:1 nat rules — item shape: {allowedInbound?: list, lanIp: string, name?: string, publicIp?: string, uplink?: "internet1"|"internet2"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/oneToOneNatRules"))
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the keys required to access Personally Identifiable Information (PII) for a given identifier
#
# GET /networks/{networkId}/pii/piiKeys
# operationId: getNetworkPiiPiiKeys
export def "networks-pii-pii-keys get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of a Systems Manager user
  --email: string # The email of a network user account or a Systems Manager device
  --mac: string # The MAC of a network client device or a Systems Manager device
  --serial: string # The serial of a Systems Manager device
  --imei: string # The IMEI of a Systems Manager device
  --bluetooth-mac: string # The MAC of a Bluetooth client
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "mac" $mac "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "imei" $imei "scalar") (serialize-qp "bluetoothMac" $bluetooth_mac "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/pii/piiKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the PII requests for this network or organization
#
# GET /networks/{networkId}/pii/requests
# operationId: getNetworkPiiRequests
export def "networks-pii-requests list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/pii/requests"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a new delete or restrict processing PII request
#
# POST /networks/{networkId}/pii/requests
# operationId: createNetworkPiiRequest
export def "networks-pii-requests create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasets: list<string> # The datasets related to the provided key that should be deleted. Only applies to "delete" requests. The value "all" will be expanded to all datasets applicable to this type. The datasets by applicable to each type are: mac (usage, events, traffic), email (users, loginAttempts), username (users, loginAttempts), bluetoothMac (client, connectivity), smDeviceId (device), smUserId (user)
  --email: string # The email of a network user account. Only applies to "delete" requests.
  --mac: string # The MAC of a network client device. Applies to both "restrict processing" and "delete" requests.
  --sm-device-id: string # The sm_device_id of a Systems Manager device. The only way to "restrict processing" or "delete" a Systems Manager device. Must include "device" in the dataset for a "delete" request to destroy the device.
  --sm-user-id: string # The sm_user_id of a Systems Manager user. The only way to "restrict processing" or "delete" a Systems Manager user. Must include "user" in the dataset for a "delete" request to destroy the user.
  --type: string@type-completer # One of "delete" or "restrict processing"
  --username: string # The username of a network log in. Only applies to "delete" requests.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/pii/requests"))
  let req_body = {"datasets": $datasets, "email": $email, "mac": $mac, "smDeviceId": $sm_device_id, "smUserId": $sm_user_id, "type": $type, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a restrict processing PII request
#
# DELETE /networks/{networkId}/pii/requests/{requestId}
# operationId: deleteNetworkPiiRequest
export def "networks-pii-requests delete" [
  network_id: string
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), request_id: (encode-path-segment $request_id)} | format pattern "/networks/{network_id}/pii/requests/{request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a PII request
#
# GET /networks/{networkId}/pii/requests/{requestId}
# operationId: getNetworkPiiRequest
export def "networks-pii-requests get" [
  network_id: string
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), request_id: (encode-path-segment $request_id)} | format pattern "/networks/{network_id}/pii/requests/{request_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Given a piece of Personally Identifiable Information (PII), return the Systems Manager device ID(s) associated with that identifier
#
# GET /networks/{networkId}/pii/smDevicesForKey
# operationId: getNetworkPiiSmDevicesForKey
export def "networks-pii-sm-devices-for-key get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of a Systems Manager user
  --email: string # The email of a network user account or a Systems Manager device
  --mac: string # The MAC of a network client device or a Systems Manager device
  --serial: string # The serial of a Systems Manager device
  --imei: string # The IMEI of a Systems Manager device
  --bluetooth-mac: string # The MAC of a Bluetooth client
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "mac" $mac "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "imei" $imei "scalar") (serialize-qp "bluetoothMac" $bluetooth_mac "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/pii/smDevicesForKey") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Given a piece of Personally Identifiable Information (PII), return the Systems Manager owner ID(s) associated with that identifier
#
# GET /networks/{networkId}/pii/smOwnersForKey
# operationId: getNetworkPiiSmOwnersForKey
export def "networks-pii-sm-owners-for-key get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of a Systems Manager user
  --email: string # The email of a network user account or a Systems Manager device
  --mac: string # The MAC of a network client device or a Systems Manager device
  --serial: string # The serial of a Systems Manager device
  --imei: string # The IMEI of a Systems Manager device
  --bluetooth-mac: string # The MAC of a Bluetooth client
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "mac" $mac "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "imei" $imei "scalar") (serialize-qp "bluetoothMac" $bluetooth_mac "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/pii/smOwnersForKey") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the port forwarding rules for an MX network
#
# GET /networks/{networkId}/portForwardingRules
# operationId: getNetworkPortForwardingRules
export def "networks-port-forwarding-rules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/portForwardingRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the port forwarding rules for an MX network
#
# PUT /networks/{networkId}/portForwardingRules
# operationId: updateNetworkPortForwardingRules
# --rules item shape: {allowedIps: list<string>, lanIp: string, localPort: string, name?: string, protocol: "tcp"|"udp", publicPort: string, uplink?: "both"|"internet1"|"internet2"}
export def "networks-port-forwarding-rules update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rules: list # An array of port forwarding params — item shape: {allowedIps: list<string>, lanIp: string, localPort: string, name?: string, protocol: "tcp"|"udp", publicPort: string, uplink?: "both"|"internet1"|"internet2"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/portForwardingRules"))
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all supported intrusion settings for an MX network
#
# GET /networks/{networkId}/security/intrusionSettings
# operationId: getNetworkSecurityIntrusionSettings
export def "networks-security-intrusion-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/security/intrusionSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the supported intrusion settings for an MX network
#
# PUT /networks/{networkId}/security/intrusionSettings
# operationId: updateNetworkSecurityIntrusionSettings
# --protectedNetworks shape: {excludedCidr?: list<string>, includedCidr?: list<string>, useDefault?: bool}
export def "networks-security-intrusion-settings update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids-rulesets: string@ids-rulesets-completer # Set the detection ruleset 'connectivity'/'balanced'/'security' (optional - omitting will leave current config unchanged). Default value is 'balanced' if none currently saved
  --mode: string@mode-completer # Set mode to 'disabled'/'detection'/'prevention' (optional - omitting will leave current config unchanged)
  --protected-networks: record # Set the included/excluded networks from the intrusion engine (optional - omitting will leave current config unchanged). This is available only in 'passthrough' mode — shape: {excludedCidr?: list<string>, includedCidr?: list<string>, useDefault?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/security/intrusionSettings"))
  let req_body = {"idsRulesets": $ids_rulesets, "mode": $mode, "protectedNetworks": $protected_networks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all supported malware settings for an MX network
#
# GET /networks/{networkId}/security/malwareSettings
# operationId: getNetworkSecurityMalwareSettings
export def "networks-security-malware-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/security/malwareSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the supported malware settings for an MX network
#
# PUT /networks/{networkId}/security/malwareSettings
# operationId: updateNetworkSecurityMalwareSettings
# --allowedFiles item shape: {comment: string, sha256: string}
# --allowedUrls item shape: {comment: string, url: string}
export def "networks-security-malware-settings update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-files: list # The sha256 digests of files that should be permitted by the malware detection engine. If omitted, the current config will remain unchanged. This is available only if your network supports AMP allow listing — item shape: {comment: string, sha256: string}
  --allowed-urls: list # The urls that should be permitted by the malware detection engine. If omitted, the current config will remain unchanged. This is available only if your network supports AMP allow listing — item shape: {comment: string, url: string}
  mode: string@mode-completer-1 # Set mode to 'enabled' to enable malware prevention, otherwise 'disabled'
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/security/malwareSettings"))
  let req_body = {"allowedFiles": $allowed_files, "allowedUrls": $allowed_urls, "mode": $mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the security events (intrusion detection only) for a network
#
# GET /networks/{networkId}/securityEvents
# operationId: getNetworkSecurityEvents
export def "networks-security-events get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. Data is gathered after the specified t0 value. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 365 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 365 days. The default is 31 days. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 100.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/securityEvents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the site-to-site VPN settings of a network
#
# GET /networks/{networkId}/siteToSiteVpn
# operationId: getNetworkSiteToSiteVpn
export def "networks-site-to-site-vpn get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/siteToSiteVpn"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the site-to-site VPN settings of a network
#
# PUT /networks/{networkId}/siteToSiteVpn
# operationId: updateNetworkSiteToSiteVpn
# --hubs item shape: {hubId: string, useDefaultRoute?: bool}
# --subnets item shape: {localSubnet: string, useVpn?: bool}
export def "networks-site-to-site-vpn update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hubs: list # The list of VPN hubs, in order of preference. In spoke mode, at least 1 hub is required. — item shape: {hubId: string, useDefaultRoute?: bool}
  mode: string@mode-completer-2 # The site-to-site VPN mode. Can be one of 'none', 'spoke' or 'hub'
  --subnets: list # The list of subnets and their VPN presence. — item shape: {localSubnet: string, useVpn?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/siteToSiteVpn"))
  let req_body = {"hubs": $hubs, "mode": $mode, "subnets": $subnets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bypass activation lock attempt
#
# POST /networks/{networkId}/sm/bypassActivationLockAttempts
# operationId: createNetworkSmBypassActivationLockAttempt
export def "networks-sm-bypass-activation-lock-attempts create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string> # The ids of the devices to attempt activation lock bypass.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/bypassActivationLockAttempts"))
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bypass activation lock attempt status
#
# GET /networks/{networkId}/sm/bypassActivationLockAttempts/{attemptId}
# operationId: getNetworkSmBypassActivationLockAttempt
export def "networks-sm-bypass-activation-lock-attempts get" [
  network_id: string
  attempt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), attempt_id: (encode-path-segment $attempt_id)} | format pattern "/networks/{network_id}/sm/bypassActivationLockAttempts/{attempt_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the fields of a device
#
# PUT /networks/{networkId}/sm/device/fields
# operationId: updateNetworkSmDeviceFields
# --deviceFields shape: {name?: string, notes?: string}
export def "networks-sm-device-fields update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_fields: record # The new fields of the device. Each field of this object is optional. — shape: {name?: string, notes?: string}
  --id: string # The id of the device to be modified.
  --serial: string # The serial of the device to be modified.
  --wifi-mac: string # The wifiMac of the device to be modified.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/device/fields"))
  let req_body = {"deviceFields": $device_fields, "id": $id, "serial": $serial, "wifiMac": $wifi_mac} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Wipe a device
#
# PUT /networks/{networkId}/sm/device/wipe
# operationId: wipeNetworkSmDevice
export def "networks-sm-device-wipe update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The id of the device to be wiped.
  --pin: int # The pin number (a six digit value) for wiping a macOS device. Required only for macOS devices.
  --serial: string # The serial of the device to be wiped.
  --wifi-mac: string # The wifiMac of the device to be wiped.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/device/wipe"))
  let req_body = {"id": $id, "pin": $pin, "serial": $serial, "wifiMac": $wifi_mac} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Refresh the details of a device
#
# POST /networks/{networkId}/sm/device/{deviceId}/refreshDetails
# operationId: refreshNetworkSmDeviceDetails
export def "networks-sm-device-refresh-details refresh" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/device/{device_id}/refreshDetails"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the devices enrolled in an SM network with various specified fields and filters
#
# GET /networks/{networkId}/sm/devices
# operationId: getNetworkSmDevices
export def "networks-sm-devices get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Additional fields that will be displayed for each device. Multiple fields can be passed in as comma separated values. The default fields are: id, name, tags, ssid, wifiMac, osName, systemModel, uuid, and serialNumber. The additional fields are: ip, systemType, availableDeviceCapacity, kioskAppName, biosVersion, lastConnected, missingAppsCount, userSuppliedAddress, location, lastUser, ownerEmail, ownerUsername, publicIp, phoneNumber, diskInfoJson, deviceCapacity, isManaged, hadMdm, isSupervised, meid, imei, iccid, simCarrierNetwork, cellularDataUsed, isHotspotEnabled, createdAt, batteryEstCharge, quarantined, avName, avRunning, asName, fwName, isRooted, loginRequired, screenLockEnabled, screenLockDelay, autoLoginDisabled, autoTags, hasMdm, hasDesktopAgent, diskEncryptionEnabled, hardwareEncryptionCaps, passCodeLock, usesHardwareKeystore, and androidSecurityPatchVersion.
  --wifi-macs: string # Filter devices by wifi mac(s). Multiple wifi macs can be passed in as comma separated values.
  --serials: string # Filter devices by serial(s). Multiple serials can be passed in as comma separated values.
  --ids: string # Filter devices by id(s). Multiple ids can be passed in as comma separated values.
  --scope: string # Specify a scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags as comma separated values.
  --batch-size: int # Number of devices to return, 1000 is the default as well as the max.
  --batch-token: string # If the network has more devices than the batch size, a batch token will be returned as a part of the device list. To see the remainder of the devices, pass in the batchToken as a parameter in the next request. Requests made with the batchToken do not require additional parameters as the batchToken includes the parameters passed in with the original request. Additional parameters passed in with the batchToken will be ignored.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "wifiMacs" $wifi_macs "scalar") (serialize-qp "serials" $serials "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "batchSize" $batch_size "scalar") (serialize-qp "batchToken" $batch_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force check-in a set of devices
#
# PUT /networks/{networkId}/sm/devices/checkin
# operationId: checkinNetworkSmDevices
export def "networks-sm-devices-checkin update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # The ids of the devices to be checked-in.
  --scope: string # The scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags of the devices to be checked-in.
  --serials: string # The serials of the devices to be checked-in.
  --wifi-macs: string # The wifiMacs of the devices to be checked-in.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/devices/checkin"))
  let req_body = {"ids": $ids, "scope": $scope, "serials": $serials, "wifiMacs": $wifi_macs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add, delete, or update the tags of a set of devices
#
# PUT /networks/{networkId}/sm/devices/tags
# operationId: updateNetworkSmDevicesTags
export def "networks-sm-devices-tags update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # The ids of the devices to be modified.
  --scope: string # The scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags of the devices to be modified.
  --serials: string # The serials of the devices to be modified.
  tags: string # The tags to be added, deleted, or updated.
  update_action: string # One of add, delete, or update. Only devices that have been modified will be returned.
  --wifi-macs: string # The wifiMacs of the devices to be modified.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/devices/tags"))
  let req_body = {"ids": $ids, "scope": $scope, "serials": $serials, "tags": $tags, "updateAction": $update_action, "wifiMacs": $wifi_macs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Unenroll a device
#
# POST /networks/{networkId}/sm/devices/{deviceId}/unenroll
# operationId: unenrollNetworkSmDevice
export def "networks-sm-devices-unenroll create" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/devices/{device_id}/unenroll"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the profiles in the network
#
# GET /networks/{networkId}/sm/profiles
# operationId: getNetworkSmProfiles
export def "networks-sm-profiles get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/profiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the target groups in this network
#
# GET /networks/{networkId}/sm/targetGroups
# operationId: getNetworkSmTargetGroups
export def "networks-sm-target-groups list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-details: oneof<nothing, bool> # Boolean indicating if the the ids of the devices or users scoped by the target group should be included in the response
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withDetails" $with_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/targetGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a target group
#
# POST /networks/{networkId}/sm/targetGroups
# operationId: createNetworkSmTargetGroup
export def "networks-sm-target-groups create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of this target group
  --scope: string # The scope and tag options of the target group. Comma separated values beginning with one of withAny, withAll, withoutAny, withoutAll, all, none, followed by tags. Default to none if empty.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/targetGroups"))
  let req_body = {"name": $name, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a target group from a network
#
# DELETE /networks/{networkId}/sm/targetGroups/{targetGroupId}
# operationId: deleteNetworkSmTargetGroup
export def "networks-sm-target-groups delete" [
  network_id: string
  target_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), target_group_id: (encode-path-segment $target_group_id)} | format pattern "/networks/{network_id}/sm/targetGroups/{target_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a target group
#
# GET /networks/{networkId}/sm/targetGroups/{targetGroupId}
# operationId: getNetworkSmTargetGroup
export def "networks-sm-target-groups get" [
  network_id: string
  target_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-details: oneof<nothing, bool> # Boolean indicating if the the ids of the devices or users scoped by the target group should be included in the response
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withDetails" $with_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), target_group_id: (encode-path-segment $target_group_id)} | format pattern "/networks/{network_id}/sm/targetGroups/{target_group_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a target group
#
# PUT /networks/{networkId}/sm/targetGroups/{targetGroupId}
# operationId: updateNetworkSmTargetGroup
export def "networks-sm-target-groups update" [
  network_id: string
  target_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of this target group
  --scope: string # The scope and tag options of the target group. Comma separated values beginning with one of withAny, withAll, withoutAny, withoutAll, all, none, followed by tags. Default to none if empty.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), target_group_id: (encode-path-segment $target_group_id)} | format pattern "/networks/{network_id}/sm/targetGroups/{target_group_id}"))
  let req_body = {"name": $name, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the profiles associated with a user
#
# GET /networks/{networkId}/sm/user/{userId}/deviceProfiles
# operationId: getNetworkSmUserDeviceProfiles
export def "networks-sm-user-device-profiles get" [
  network_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), user_id: (encode-path-segment $user_id)} | format pattern "/networks/{network_id}/sm/user/{user_id}/deviceProfiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of softwares associated with a user
#
# GET /networks/{networkId}/sm/user/{userId}/softwares
# operationId: getNetworkSmUserSoftwares
export def "networks-sm-user-softwares get" [
  network_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), user_id: (encode-path-segment $user_id)} | format pattern "/networks/{network_id}/sm/user/{user_id}/softwares"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the owners in an SM network with various specified fields and filters
#
# GET /networks/{networkId}/sm/users
# operationId: getNetworkSmUsers
export def "networks-sm-users get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Filter users by id(s). Multiple ids can be passed in as comma separated values.
  --usernames: string # Filter users by username(s). Multiple usernames can be passed in as comma separated values.
  --emails: string # Filter users by email(s). Multiple emails can be passed in as comma separated values.
  --scope: string # Specifiy a scope (one of all, none, withAny, withAll, withoutAny, withoutAll) and a set of tags as comma separated values.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "usernames" $usernames "scalar") (serialize-qp "emails" $emails "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the client's daily cellular data usage history
#
# GET /networks/{networkId}/sm/{deviceId}/cellularUsageHistory
# operationId: getNetworkSmCellularUsageHistory
export def "networks-sm-cellular-usage-history get" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/{device_id}/cellularUsageHistory"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the certs on a device
#
# GET /networks/{networkId}/sm/{deviceId}/certs
# operationId: getNetworkSmCerts
export def "networks-sm-certs get" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/{device_id}/certs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the profiles associated with a device
#
# GET /networks/{networkId}/sm/{deviceId}/deviceProfiles
# operationId: getNetworkSmDeviceProfiles
export def "networks-sm-device-profiles get" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/{device_id}/deviceProfiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the network adapters of a device
#
# GET /networks/{networkId}/sm/{deviceId}/networkAdapters
# operationId: getNetworkSmNetworkAdapters
export def "networks-sm-network-adapters get" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/{device_id}/networkAdapters"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the restrictions on a device
#
# GET /networks/{networkId}/sm/{deviceId}/restrictions
# operationId: getNetworkSmRestrictions
export def "networks-sm-restrictions get" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/{device_id}/restrictions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the security centers on a device
#
# GET /networks/{networkId}/sm/{deviceId}/securityCenters
# operationId: getNetworkSmSecurityCenters
export def "networks-sm-security-centers get" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/{device_id}/securityCenters"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of softwares associated with a device
#
# GET /networks/{networkId}/sm/{deviceId}/softwares
# operationId: getNetworkSmSoftwares
export def "networks-sm-softwares get" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/{device_id}/softwares"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the saved SSID names on a device
#
# GET /networks/{networkId}/sm/{deviceId}/wlanLists
# operationId: getNetworkSmWlanLists
export def "networks-sm-wlan-lists get" [
  network_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), device_id: (encode-path-segment $device_id)} | format pattern "/networks/{network_id}/sm/{device_id}/wlanLists"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the SNMP settings for a network
#
# GET /networks/{networkId}/snmpSettings
# operationId: getNetworkSnmpSettings
export def "networks-snmp-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/snmpSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the splash login attempts for a network
#
# GET /networks/{networkId}/splashLoginAttempts
# operationId: getNetworkSplashLoginAttempts
export def "networks-splash-login-attempts get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ssid-number: int@ssid-number-completer # Only return the login attempts for the specified SSID
  --login-identifier: string # The username, email, or phone number used during login
  --timespan: int # The timespan, in seconds, for the login attempts. The period will be from [timespan] seconds ago until now. The maximum timespan is 3 months
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ssidNumber" $ssid_number "scalar") (serialize-qp "loginIdentifier" $login_identifier "scalar") (serialize-qp "timespan" $timespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/splashLoginAttempts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Split a combined network into individual networks for each type of device
#
# POST /networks/{networkId}/split
# operationId: splitNetwork
export def "networks-split create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/split"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the SSIDs in a network
#
# GET /networks/{networkId}/ssids
# operationId: getNetworkSsids
export def "networks-ssids list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/ssids"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a single SSID
#
# GET /networks/{networkId}/ssids/{number}
# operationId: getNetworkSsid
export def "networks-ssids get" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), number: (encode-path-segment $number)} | format pattern "/networks/{network_id}/ssids/{number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the attributes of an SSID
#
# PUT /networks/{networkId}/ssids/{number}
# operationId: updateNetworkSsid
# --apTagsAndVlanIds item shape: {tags?: string, vlanId?: int}
# --radiusAccountingServers item shape: {host: string, port?: int, secret?: string}
# --radiusServers item shape: {host: string, port?: int, secret?: string}
export def "networks-ssids update" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ap-tags-and-vlan-ids: list # The list of tags and VLAN IDs used for VLAN tagging. This param is only valid when the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming' — item shape: {tags?: string, vlanId?: int}
  --auth-mode: string@auth-mode-completer # The association control method for the SSID ('open', 'open-enhanced', 'psk', 'open-with-radius', 'open-with-nac', '8021x-meraki', '8021x-nac', '8021x-radius', '8021x-google', '8021x-localradius', 'ipsk-with-radius' or 'ipsk-without-radius')
  --availability-tags: list<string> # Accepts a list of tags for this SSID. If availableOnAllAps is false, then the SSID will only be broadcast by APs with tags matching any of the tags in this list.
  --available-on-all-aps: oneof<nothing, bool> # Boolean indicating whether all APs should broadcast the SSID or if it should be restricted to APs matching any availability tags. Can only be false if the SSID has availability tags.
  --band-selection: string # The client-serving radio frequencies of this SSID in the default indoor RF profile. ('Dual band operation', '5 GHz band only' or 'Dual band operation with Band Steering')
  --concentrator-network-id: string # The concentrator to use when the ipAssignmentMode is 'Layer 3 roaming with a concentrator' or 'VPN'.
  --default-vlan-id: int # The default VLAN ID used for 'all other APs'. This param is only valid when the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
  --disassociate-clients-on-vpn-failover: oneof<nothing, bool> # Disassociate clients when 'VPN' concentrator failover occurs in order to trigger clients to re-associate and generate new DHCP requests. This param is only valid if ipAssignmentMode is 'VPN'.
  --enabled: oneof<nothing, bool> # Whether or not the SSID is enabled
  --encryption-mode: string@encryption-mode-completer # The psk encryption mode for the SSID ('wep' or 'wpa'). This param is only valid if the authMode is 'psk'
  --enterprise-admin-access: string@enterprise-admin-access-completer # Whether or not an SSID is accessible by 'enterprise' administrators ('access disabled' or 'access enabled')
  --ip-assignment-mode: string # The client IP assignment mode ('NAT mode', 'Bridge mode', 'Layer 3 roaming', 'Ethernet over GRE', 'Layer 3 roaming with a concentrator' or 'VPN')
  --lan-isolation-enabled: oneof<nothing, bool> # Boolean indicating whether Layer 2 LAN isolation should be enabled or disabled. Only configurable when ipAssignmentMode is 'Bridge mode'.
  --min-bitrate: float # The minimum bitrate in Mbps of this SSID in the default indoor RF profile. ('1', '2', '5.5', '6', '9', '11', '12', '18', '24', '36', '48' or '54') (format: float)
  --name: string # The name of the SSID
  --per-client-bandwidth-limit-down: int # The download bandwidth limit in Kbps. (0 represents no limit.)
  --per-client-bandwidth-limit-up: int # The upload bandwidth limit in Kbps. (0 represents no limit.)
  --psk: string # The passkey for the SSID. This param is only valid if the authMode is 'psk'
  --radius-accounting-enabled: oneof<nothing, bool> # Whether or not RADIUS accounting is enabled. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius'
  --radius-accounting-servers: list # The RADIUS accounting 802.1X servers to be used for authentication. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius' and radiusAccountingEnabled is 'true' — item shape: {host: string, port?: int, secret?: string}
  --radius-attribute-for-group-policies: string # Specify the RADIUS attribute used to look up group policies ('Filter-Id', 'Reply-Message', 'Airespace-ACL-Name' or 'Aruba-User-Role'). Access points must receive this attribute in the RADIUS Access-Accept message
  --radius-coa-enabled: oneof<nothing, bool> # If true, Meraki devices will act as a RADIUS Dynamic Authorization Server and will respond to RADIUS Change-of-Authorization and Disconnect messages sent by the RADIUS server.
  --radius-failover-policy: string@radius-failover-policy-completer # This policy determines how authentication requests should be handled in the event that all of the configured RADIUS servers are unreachable ('Deny access' or 'Allow access')
  --radius-load-balancing-policy: string@radius-load-balancing-policy-completer # This policy determines which RADIUS server will be contacted first in an authentication attempt and the ordering of any necessary retry attempts ('Strict priority order' or 'Round robin')
  --radius-override: oneof<nothing, bool> # If true, the RADIUS response can override VLAN tag. This is not valid when ipAssignmentMode is 'NAT mode'.
  --radius-servers: list # The RADIUS 802.1X servers to be used for authentication. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius' — item shape: {host: string, port?: int, secret?: string}
  --secondary-concentrator-network-id: string # The secondary concentrator to use when the ipAssignmentMode is 'VPN'. If configured, the APs will switch to using this concentrator if the primary concentrator is unreachable. This param is optional. ('disabled' represents no secondary concentrator.)
  --splash-page: string@splash-page-completer # The type of splash page for the SSID ('None', 'Click-through splash page', 'Billing', 'Password-protected with Meraki RADIUS', 'Password-protected with custom RADIUS', 'Password-protected with Active Directory', 'Password-protected with LDAP', 'SMS authentication', 'Systems Manager Sentry', 'Facebook Wi-Fi', 'Google OAuth', 'Sponsored guest', 'Cisco ISE' or 'Google Apps domain'). This attribute is not supported for template children.
  --use-vlan-tagging: oneof<nothing, bool> # Whether or not traffic should be directed to use specific VLANs. This param is only valid if the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
  --visible: oneof<nothing, bool> # Boolean indicating whether APs should advertise or hide this SSID. APs will only broadcast this SSID if set to true
  --vlan-id: int # The VLAN ID used for VLAN tagging. This param is only valid when the ipAssignmentMode is 'Layer 3 roaming with a concentrator' or 'VPN'
  --walled-garden-enabled: oneof<nothing, bool> # Allow access to a configurable list of IP ranges, which users may access prior to sign-on.
  --walled-garden-ranges: string # Specify your walled garden by entering space-separated addresses, ranges using CIDR notation, domain names, and domain wildcards (e.g. 192.168.1.1/24 192.168.37.10/32 www.yahoo.com *.google.com). Meraki's splash page is automatically included in your walled garden.
  --wpa-encryption-mode: string@wpa-encryption-mode-completer # The types of WPA encryption. ('WPA1 only', 'WPA1 and WPA2', 'WPA2 only', 'WPA3 Transition Mode' or 'WPA3 only')
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), number: (encode-path-segment $number)} | format pattern "/networks/{network_id}/ssids/{number}"))
  let req_body = {"apTagsAndVlanIds": $ap_tags_and_vlan_ids, "authMode": $auth_mode, "availabilityTags": $availability_tags, "availableOnAllAps": $available_on_all_aps, "bandSelection": $band_selection, "concentratorNetworkId": $concentrator_network_id, "defaultVlanId": $default_vlan_id, "disassociateClientsOnVpnFailover": $disassociate_clients_on_vpn_failover, "enabled": $enabled, "encryptionMode": $encryption_mode, "enterpriseAdminAccess": $enterprise_admin_access, "ipAssignmentMode": $ip_assignment_mode, "lanIsolationEnabled": $lan_isolation_enabled, "minBitrate": $min_bitrate, "name": $name, "perClientBandwidthLimitDown": $per_client_bandwidth_limit_down, "perClientBandwidthLimitUp": $per_client_bandwidth_limit_up, "psk": $psk, "radiusAccountingEnabled": $radius_accounting_enabled, "radiusAccountingServers": $radius_accounting_servers, "radiusAttributeForGroupPolicies": $radius_attribute_for_group_policies, "radiusCoaEnabled": $radius_coa_enabled, "radiusFailoverPolicy": $radius_failover_policy, "radiusLoadBalancingPolicy": $radius_load_balancing_policy, "radiusOverride": $radius_override, "radiusServers": $radius_servers, "secondaryConcentratorNetworkId": $secondary_concentrator_network_id, "splashPage": $splash_page, "useVlanTagging": $use_vlan_tagging, "visible": $visible, "vlanId": $vlan_id, "walledGardenEnabled": $walled_garden_enabled, "walledGardenRanges": $walled_garden_ranges, "wpaEncryptionMode": $wpa_encryption_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the L3 firewall rules for an SSID on an MR network
#
# GET /networks/{networkId}/ssids/{number}/l3FirewallRules
# operationId: getNetworkSsidL3FirewallRules
export def "networks-ssids-l3-firewall-rules get" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), number: (encode-path-segment $number)} | format pattern "/networks/{network_id}/ssids/{number}/l3FirewallRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the L3 firewall rules of an SSID on an MR network
#
# PUT /networks/{networkId}/ssids/{number}/l3FirewallRules
# operationId: updateNetworkSsidL3FirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp"}
export def "networks-ssids-l3-firewall-rules update" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-lan-access: oneof<nothing, bool> # Allow wireless client access to local LAN (boolean value - true allows access and false denies access) (optional)
  --rules: list # An ordered array of the firewall rules for this SSID (not including the local LAN access rule or the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp"}
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), number: (encode-path-segment $number)} | format pattern "/networks/{network_id}/ssids/{number}/l3FirewallRules"))
  let req_body = {"allowLanAccess": $allow_lan_access, "rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Display the splash page settings for the given SSID
#
# GET /networks/{networkId}/ssids/{number}/splashSettings
# operationId: getNetworkSsidSplashSettings
export def "networks-ssids-splash-settings get" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), number: (encode-path-segment $number)} | format pattern "/networks/{network_id}/ssids/{number}/splashSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the splash page settings for the given SSID
#
# PUT /networks/{networkId}/ssids/{number}/splashSettings
# operationId: updateNetworkSsidSplashSettings
export def "networks-ssids-splash-settings update" [
  network_id: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --splash-url: string # [optional] The custom splash URL of the click-through splash page. Note that the URL can be configured without necessarily being used. In order to enable the custom URL, see 'useSplashUrl'
  --use-splash-url: oneof<nothing, bool> # [optional] Boolean indicating whether the user will be redirected to the custom splash url. A custom splash URL must be set if this is true. Note that depending on your SSID's access control settings, it may not be possible to use the custom splash URL.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), number: (encode-path-segment $number)} | format pattern "/networks/{network_id}/ssids/{number}/splashSettings"))
  let req_body = {"splashUrl": $splash_url, "useSplashUrl": $use_splash_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the static routes for an MX or teleworker network
#
# GET /networks/{networkId}/staticRoutes
# operationId: getNetworkStaticRoutes
export def "networks-static-routes list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/staticRoutes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a static route for an MX or teleworker network
#
# POST /networks/{networkId}/staticRoutes
# operationId: createNetworkStaticRoute
export def "networks-static-routes create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gateway_ip: string # The gateway IP (next hop) of the static route
  name: string # The name of the new static route
  subnet: string # The subnet of the static route
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/staticRoutes"))
  let req_body = {"gatewayIp": $gateway_ip, "name": $name, "subnet": $subnet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a static route from an MX or teleworker network
#
# DELETE /networks/{networkId}/staticRoutes/{staticRouteId}
# operationId: deleteNetworkStaticRoute
export def "networks-static-routes delete" [
  network_id: string
  static_route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), static_route_id: (encode-path-segment $static_route_id)} | format pattern "/networks/{network_id}/staticRoutes/{static_route_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a static route for an MX or teleworker network
#
# GET /networks/{networkId}/staticRoutes/{staticRouteId}
# operationId: getNetworkStaticRoute
export def "networks-static-routes get" [
  network_id: string
  static_route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), static_route_id: (encode-path-segment $static_route_id)} | format pattern "/networks/{network_id}/staticRoutes/{static_route_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a static route for an MX or teleworker network
#
# PUT /networks/{networkId}/staticRoutes/{staticRouteId}
# operationId: updateNetworkStaticRoute
# --reservedIpRanges item shape: {comment: string, end: string, start: string}
export def "networks-static-routes update" [
  network_id: string
  static_route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # The enabled state of the static route
  --fixed-ip-assignments: record # The DHCP fixed IP assignments on the static route. This should be an object that contains mappings from MAC addresses to objects that themselves each contain "ip" and "name" string fields. See the sample request/response for more details.
  --gateway-ip: string # The gateway IP (next hop) of the static route
  --name: string # The name of the static route
  --reserved-ip-ranges: list # The DHCP reserved IP ranges on the static route — item shape: {comment: string, end: string, start: string}
  --subnet: string # The subnet of the static route
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), static_route_id: (encode-path-segment $static_route_id)} | format pattern "/networks/{network_id}/staticRoutes/{static_route_id}"))
  let req_body = {"enabled": $enabled, "fixedIpAssignments": $fixed_ip_assignments, "gatewayIp": $gateway_ip, "name": $name, "reservedIpRanges": $reserved_ip_ranges, "subnet": $subnet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Swap MX primary and warm spare appliances
#
# POST /networks/{networkId}/swapWarmSpare
# operationId: swapNetworkWarmSpare
export def "networks-swap-warm-spare create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/swapWarmSpare"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List link aggregation groups
#
# GET /networks/{networkId}/switch/linkAggregations
# operationId: getNetworkSwitchLinkAggregations
export def "networks-switch-link-aggregations get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/linkAggregations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a link aggregation group
#
# POST /networks/{networkId}/switch/linkAggregations
# operationId: createNetworkSwitchLinkAggregation
# --switchPorts item shape: {portId: string, serial: string}
# --switchProfilePorts item shape: {portId: string, profile: string}
export def "networks-switch-link-aggregations create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --switch-ports: list # Array of switch or stack ports for creating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, serial: string}
  --switch-profile-ports: list # Array of switch profile ports for creating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, profile: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/linkAggregations"))
  let req_body = {"switchPorts": $switch_ports, "switchProfilePorts": $switch_profile_ports} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Split a link aggregation group into separate ports
#
# DELETE /networks/{networkId}/switch/linkAggregations/{linkAggregationId}
# operationId: deleteNetworkSwitchLinkAggregation
export def "networks-switch-link-aggregations delete" [
  network_id: string
  link_aggregation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), link_aggregation_id: (encode-path-segment $link_aggregation_id)} | format pattern "/networks/{network_id}/switch/linkAggregations/{link_aggregation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a link aggregation group
#
# PUT /networks/{networkId}/switch/linkAggregations/{linkAggregationId}
# operationId: updateNetworkSwitchLinkAggregation
# --switchPorts item shape: {portId: string, serial: string}
# --switchProfilePorts item shape: {portId: string, profile: string}
export def "networks-switch-link-aggregations update" [
  network_id: string
  link_aggregation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --switch-ports: list # Array of switch or stack ports for updating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, serial: string}
  --switch-profile-ports: list # Array of switch profile ports for updating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, profile: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), link_aggregation_id: (encode-path-segment $link_aggregation_id)} | format pattern "/networks/{network_id}/switch/linkAggregations/{link_aggregation_id}"))
  let req_body = {"switchPorts": $switch_ports, "switchProfilePorts": $switch_profile_ports} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List switch port schedules
#
# GET /networks/{networkId}/switch/portSchedules
# operationId: getNetworkSwitchPortSchedules
export def "networks-switch-port-schedules get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/portSchedules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a switch port schedule
#
# POST /networks/{networkId}/switch/portSchedules
# operationId: createNetworkSwitchPortSchedule
# --portSchedule shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
export def "networks-switch-port-schedules create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for your port schedule. Required
  --port-schedule: record # The schedule for switch port scheduling. Schedules are applied to days of the week. When it's empty, default schedule with all days of a week are configured. Any unspecified day in the schedule is added as a default schedule configuration of the day. — shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/portSchedules"))
  let req_body = {"name": $name, "portSchedule": $port_schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a switch port schedule
#
# DELETE /networks/{networkId}/switch/portSchedules/{portScheduleId}
# operationId: deleteNetworkSwitchPortSchedule
export def "networks-switch-port-schedules delete" [
  network_id: string
  port_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), port_schedule_id: (encode-path-segment $port_schedule_id)} | format pattern "/networks/{network_id}/switch/portSchedules/{port_schedule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a switch port schedule
#
# PUT /networks/{networkId}/switch/portSchedules/{portScheduleId}
# operationId: updateNetworkSwitchPortSchedule
# --portSchedule shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
export def "networks-switch-port-schedules update" [
  network_id: string
  port_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for your port schedule.
  --port-schedule: record # The schedule for switch port scheduling. Schedules are applied to days of the week. When it's empty, default schedule with all days of a week are configured. Any unspecified day in the schedule is added as a default schedule configuration of the day. — shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), port_schedule_id: (encode-path-segment $port_schedule_id)} | format pattern "/networks/{network_id}/switch/portSchedules/{port_schedule_id}"))
  let req_body = {"name": $name, "portSchedule": $port_schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the switch network settings
#
# GET /networks/{networkId}/switch/settings
# operationId: getNetworkSwitchSettings
export def "networks-switch-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update switch network settings
#
# PUT /networks/{networkId}/switch/settings
# operationId: updateNetworkSwitchSettings
# --powerExceptions item shape: {powerType: "combined"|"redundant"|"useNetworkSetting", serial: string}
export def "networks-switch-settings update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --power-exceptions: list # Exceptions on a per switch basis to "useCombinedPower" — item shape: {powerType: "combined"|"redundant"|"useNetworkSetting", serial: string}
  --use-combined-power: oneof<nothing, bool> # The use Combined Power as the default behavior of secondary power supplies on supported devices.
  --vlan: int # Management VLAN
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings"))
  let req_body = {"powerExceptions": $power_exceptions, "useCombinedPower": $use_combined_power, "vlan": $vlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the MTU configuration
#
# GET /networks/{networkId}/switch/settings/mtu
# operationId: getNetworkSwitchSettingsMtu
export def "networks-switch-settings-mtu get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/mtu"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the MTU configuration
#
# PUT /networks/{networkId}/switch/settings/mtu
# operationId: updateNetworkSwitchSettingsMtu
# --overrides item shape: {mtuSize: int, switchProfiles?: list<string>, switches?: list<string>}
export def "networks-switch-settings-mtu update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-mtu-size: int # MTU size for the entire network. Default value is 9578.
  --overrides: list # Override MTU size for individual switches or switch profiles. An empty array will clear overrides. — item shape: {mtuSize: int, switchProfiles?: list<string>, switches?: list<string>}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/mtu"))
  let req_body = {"defaultMtuSize": $default_mtu_size, "overrides": $overrides} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return multicast settings for a network
#
# GET /networks/{networkId}/switch/settings/multicast
# operationId: getNetworkSwitchSettingsMulticast
export def "networks-switch-settings-multicast get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/multicast"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update multicast settings for a network
#
# PUT /networks/{networkId}/switch/settings/multicast
# operationId: updateNetworkSwitchSettingsMulticast
# --defaultSettings shape: {floodUnknownMulticastTrafficEnabled?: bool, igmpSnoopingEnabled?: bool}
# --overrides item shape: {floodUnknownMulticastTrafficEnabled: bool, igmpSnoopingEnabled: bool, stacks?: list<string>, switchProfiles?: list<string>, switches?: list<string>}
export def "networks-switch-settings-multicast update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-settings: record # Default multicast setting for entire network. IGMP snooping and Flood unknown multicast traffic settings are enabled by default. — shape: {floodUnknownMulticastTrafficEnabled?: bool, igmpSnoopingEnabled?: bool}
  --overrides: list # Array of paired switches/stacks/profiles and corresponding multicast settings. An empty array will clear the multicast settings. — item shape: {floodUnknownMulticastTrafficEnabled: bool, igmpSnoopingEnabled: bool, stacks?: list<string>, switchProfiles?: list<string>, switches?: list<string>}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/multicast"))
  let req_body = {"defaultSettings": $default_settings, "overrides": $overrides} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List quality of service rules
#
# GET /networks/{networkId}/switch/settings/qosRules
# operationId: getNetworkSwitchSettingsQosRules
export def "networks-switch-settings-qos-rules list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/qosRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a quality of service rule
#
# POST /networks/{networkId}/switch/settings/qosRules
# operationId: createNetworkSwitchSettingsQosRule
export def "networks-switch-settings-qos-rules create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dscp: int # DSCP tag. Set this to -1 to trust incoming DSCP. Default value is 0
  --dst-port: int # The destination port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --dst-port-range: string # The destination port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --protocol: string@protocol-completer # The protocol of the incoming packet. Can be one of "ANY", "TCP" or "UDP". Default value is "ANY"
  --src-port: int # The source port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --src-port-range: string # The source port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  vlan: int # The VLAN of the incoming packet. A null value will match any VLAN.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/qosRules"))
  let req_body = {"dscp": $dscp, "dstPort": $dst_port, "dstPortRange": $dst_port_range, "protocol": $protocol, "srcPort": $src_port, "srcPortRange": $src_port_range, "vlan": $vlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the quality of service rule IDs by order in which they will be processed by the switch
#
# GET /networks/{networkId}/switch/settings/qosRules/order
# operationId: getNetworkSwitchSettingsQosRulesOrder
export def "networks-switch-settings-qos-rules-order get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/qosRules/order"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the order in which the rules should be processed by the switch
#
# PUT /networks/{networkId}/switch/settings/qosRules/order
# operationId: updateNetworkSwitchSettingsQosRulesOrder
export def "networks-switch-settings-qos-rules-order update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rule_ids: list<string> # A list of quality of service rule IDs arranged in order in which they should be processed by the switch.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/qosRules/order"))
  let req_body = {"ruleIds": $rule_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a quality of service rule
#
# DELETE /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# operationId: deleteNetworkSwitchSettingsQosRule
export def "networks-switch-settings-qos-rules delete" [
  network_id: string
  qos_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), qos_rule_id: (encode-path-segment $qos_rule_id)} | format pattern "/networks/{network_id}/switch/settings/qosRules/{qos_rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a quality of service rule
#
# GET /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# operationId: getNetworkSwitchSettingsQosRule
export def "networks-switch-settings-qos-rules get" [
  network_id: string
  qos_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), qos_rule_id: (encode-path-segment $qos_rule_id)} | format pattern "/networks/{network_id}/switch/settings/qosRules/{qos_rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a quality of service rule
#
# PUT /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# operationId: updateNetworkSwitchSettingsQosRule
export def "networks-switch-settings-qos-rules update" [
  network_id: string
  qos_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dscp: int # DSCP tag that should be assigned to incoming packet. Set this to -1 to trust incoming DSCP. Default value is 0.
  --dst-port: int # The destination port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --dst-port-range: string # The destination port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --protocol: string@protocol-completer # The protocol of the incoming packet. Can be one of "ANY", "TCP" or "UDP". Default value is "ANY".
  --src-port: int # The source port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --src-port-range: string # The source port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --vlan: int # The VLAN of the incoming packet. A null value will match any VLAN.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), qos_rule_id: (encode-path-segment $qos_rule_id)} | format pattern "/networks/{network_id}/switch/settings/qosRules/{qos_rule_id}"))
  let req_body = {"dscp": $dscp, "dstPort": $dst_port, "dstPortRange": $dst_port_range, "protocol": $protocol, "srcPort": $src_port, "srcPortRange": $src_port_range, "vlan": $vlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the storm control configuration for a switch network
#
# GET /networks/{networkId}/switch/settings/stormControl
# operationId: getNetworkSwitchSettingsStormControl
export def "networks-switch-settings-storm-control get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/stormControl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the storm control configuration for a switch network
#
# PUT /networks/{networkId}/switch/settings/stormControl
# operationId: updateNetworkSwitchSettingsStormControl
export def "networks-switch-settings-storm-control update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcast-threshold: int # Percentage (1 to 99) of total available port bandwidth for broadcast traffic type. Default value 100 percent rate is to clear the configuration.
  --multicast-threshold: int # Percentage (1 to 99) of total available port bandwidth for multicast traffic type. Default value 100 percent rate is to clear the configuration.
  --unknown-unicast-threshold: int # Percentage (1 to 99) of total available port bandwidth for unknown unicast (dlf-destination lookup failure) traffic type. Default value 100 percent rate is to clear the configuration.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switch/settings/stormControl"))
  let req_body = {"broadcastThreshold": $broadcast_threshold, "multicastThreshold": $multicast_threshold, "unknownUnicastThreshold": $unknown_unicast_threshold} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the switch stacks in a network
#
# GET /networks/{networkId}/switchStacks
# operationId: getNetworkSwitchStacks
export def "networks-switch-stacks list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switchStacks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a stack
#
# POST /networks/{networkId}/switchStacks
# operationId: createNetworkSwitchStack
export def "networks-switch-stacks create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new stack
  serials: list<string> # An array of switch serials to be added into the new stack
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/switchStacks"))
  let req_body = {"name": $name, "serials": $serials} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a stack
#
# DELETE /networks/{networkId}/switchStacks/{switchStackId}
# operationId: deleteNetworkSwitchStack
export def "networks-switch-stacks delete" [
  network_id: string
  switch_stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), switch_stack_id: (encode-path-segment $switch_stack_id)} | format pattern "/networks/{network_id}/switchStacks/{switch_stack_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show a switch stack
#
# GET /networks/{networkId}/switchStacks/{switchStackId}
# operationId: getNetworkSwitchStack
export def "networks-switch-stacks get" [
  network_id: string
  switch_stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), switch_stack_id: (encode-path-segment $switch_stack_id)} | format pattern "/networks/{network_id}/switchStacks/{switch_stack_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a switch to a stack
#
# POST /networks/{networkId}/switchStacks/{switchStackId}/add
# operationId: addNetworkSwitchStack
export def "networks-switch-stacks-add create" [
  network_id: string
  switch_stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  serial: string # The serial of the switch to be added
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), switch_stack_id: (encode-path-segment $switch_stack_id)} | format pattern "/networks/{network_id}/switchStacks/{switch_stack_id}/add"))
  let req_body = {"serial": $serial} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove a switch from a stack
#
# POST /networks/{networkId}/switchStacks/{switchStackId}/remove
# operationId: removeNetworkSwitchStack
export def "networks-switch-stacks-remove delete" [
  network_id: string
  switch_stack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  serial: string # The serial of the switch to be removed
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), switch_stack_id: (encode-path-segment $switch_stack_id)} | format pattern "/networks/{network_id}/switchStacks/{switch_stack_id}/remove"))
  let req_body = {"serial": $serial} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the syslog servers for a network
#
# GET /networks/{networkId}/syslogServers
# operationId: getNetworkSyslogServers
export def "networks-syslog-servers get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/syslogServers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the syslog servers for a network
#
# PUT /networks/{networkId}/syslogServers
# operationId: updateNetworkSyslogServers
# --servers item shape: {host: string, port: int, roles: list<string>}
export def "networks-syslog-servers update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  servers: list # A list of the syslog servers for this network — item shape: {host: string, port: int, roles: list<string>}
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/syslogServers"))
  let req_body = {"servers": $servers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the traffic analysis data for this network
#
# GET /networks/{networkId}/traffic
# operationId: getNetworkTraffic
export def "networks-traffic get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 30 days from today.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameter t0. The value must be in seconds and be less than or equal to 30 days. (format: float)
  --device-type: string@device-type-completer # Filter the data by device type: 'combined', 'wireless', 'switch' or 'appliance'. Defaults to 'combined'. When using 'combined', for each rule the data will come from the device type with the most usage.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "deviceType" $device_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/traffic") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unbind a network from a template.
#
# POST /networks/{networkId}/unbind
# operationId: unbindNetwork
export def "networks-unbind create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/unbind"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the uplink settings for your MX network.
#
# GET /networks/{networkId}/uplinkSettings
# operationId: getNetworkUplinkSettings
export def "networks-uplink-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/uplinkSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the uplink settings for your MX network.
#
# PUT /networks/{networkId}/uplinkSettings
# operationId: updateNetworkUplinkSettings
# --bandwidthLimits shape: {cellular?: record, wan1?: record, wan2?: record}
export def "networks-uplink-settings update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bandwidth-limits: record # A mapping of uplinks to their bandwidth settings (be sure to check which uplinks are supported for your network) — shape: {cellular?: record, wan1?: record, wan2?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/uplinkSettings"))
  let req_body = {"bandwidthLimits": $bandwidth_limits} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the VLANs for an MX network
#
# GET /networks/{networkId}/vlans
# operationId: getNetworkVlans
export def "networks-vlans list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/vlans"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a VLAN
#
# POST /networks/{networkId}/vlans
# operationId: createNetworkVlan
export def "networks-vlans create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appliance_ip: string # The local IP of the appliance on the VLAN
  --group-policy-id: string # The id of the desired group policy to apply to the VLAN
  id: string # The VLAN ID of the new VLAN (must be between 1 and 4094)
  name: string # The name of the new VLAN
  subnet: string # The subnet of the VLAN
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/vlans"))
  let req_body = {"applianceIp": $appliance_ip, "groupPolicyId": $group_policy_id, "id": $id, "name": $name, "subnet": $subnet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a VLAN from a network
#
# DELETE /networks/{networkId}/vlans/{vlanId}
# operationId: deleteNetworkVlan
export def "networks-vlans delete" [
  network_id: string
  vlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), vlan_id: (encode-path-segment $vlan_id)} | format pattern "/networks/{network_id}/vlans/{vlan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a VLAN
#
# GET /networks/{networkId}/vlans/{vlanId}
# operationId: getNetworkVlan
export def "networks-vlans get" [
  network_id: string
  vlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), vlan_id: (encode-path-segment $vlan_id)} | format pattern "/networks/{network_id}/vlans/{vlan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a VLAN
#
# PUT /networks/{networkId}/vlans/{vlanId}
# operationId: updateNetworkVlan
# --dhcpOptions item shape: {code: string, type: "hex"|"integer"|"ip"|"text", value: string}
# --reservedIpRanges item shape: {comment: string, end: string, start: string}
export def "networks-vlans update" [
  network_id: string
  vlan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appliance-ip: string # The local IP of the appliance on the VLAN
  --dhcp-boot-filename: string # DHCP boot option for boot filename
  --dhcp-boot-next-server: string # DHCP boot option to direct boot clients to the server to load the boot file from
  --dhcp-boot-options-enabled: oneof<nothing, bool> # Use DHCP boot options specified in other properties
  --dhcp-handling: string@dhcp-handling-completer # The appliance's handling of DHCP requests on this VLAN. One of: 'Run a DHCP server', 'Relay DHCP to another server' or 'Do not respond to DHCP requests'
  --dhcp-lease-time: string@dhcp-lease-time-completer # The term of DHCP leases if the appliance is running a DHCP server on this VLAN. One of: '30 minutes', '1 hour', '4 hours', '12 hours', '1 day' or '1 week'
  --dhcp-options: list # The list of DHCP options that will be included in DHCP responses. Each object in the list should have "code", "type", and "value" properties. — item shape: {code: string, type: "hex"|"integer"|"ip"|"text", value: string}
  --dhcp-relay-server-ips: list<string> # The IPs of the DHCP servers that DHCP requests should be relayed to
  --dns-nameservers: string # The DNS nameservers used for DHCP responses, either "upstream_dns", "google_dns", "opendns", or a newline seperated string of IP addresses or domain names
  --fixed-ip-assignments: record # The DHCP fixed IP assignments on the VLAN. This should be an object that contains mappings from MAC addresses to objects that themselves each contain "ip" and "name" string fields. See the sample request/response for more details.
  --group-policy-id: string # The id of the desired group policy to apply to the VLAN
  --name: string # The name of the VLAN
  --reserved-ip-ranges: list # The DHCP reserved IP ranges on the VLAN — item shape: {comment: string, end: string, start: string}
  --subnet: string # The subnet of the VLAN
  --vpn-nat-subnet: string # The translated VPN subnet if VPN and VPN subnet translation are enabled on the VLAN
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), vlan_id: (encode-path-segment $vlan_id)} | format pattern "/networks/{network_id}/vlans/{vlan_id}"))
  let req_body = {"applianceIp": $appliance_ip, "dhcpBootFilename": $dhcp_boot_filename, "dhcpBootNextServer": $dhcp_boot_next_server, "dhcpBootOptionsEnabled": $dhcp_boot_options_enabled, "dhcpHandling": $dhcp_handling, "dhcpLeaseTime": $dhcp_lease_time, "dhcpOptions": $dhcp_options, "dhcpRelayServerIps": $dhcp_relay_server_ips, "dnsNameservers": $dns_nameservers, "fixedIpAssignments": $fixed_ip_assignments, "groupPolicyId": $group_policy_id, "name": $name, "reservedIpRanges": $reserved_ip_ranges, "subnet": $subnet, "vpnNatSubnet": $vpn_nat_subnet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the enabled status of VLANs for the network
#
# GET /networks/{networkId}/vlansEnabledState
# operationId: getNetworkVlansEnabledState
export def "networks-vlans-enabled-state get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/vlansEnabledState"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable/Disable VLANs for the given network
#
# PUT /networks/{networkId}/vlansEnabledState
# operationId: updateNetworkVlansEnabledState
export def "networks-vlans-enabled-state update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Boolean indicating whether to enable (true) or disable (false) VLANs for the network
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/vlansEnabledState"))
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return MX warm spare settings
#
# GET /networks/{networkId}/warmSpareSettings
# operationId: getNetworkWarmSpareSettings
export def "networks-warm-spare-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/warmSpareSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update MX warm spare settings
#
# PUT /networks/{networkId}/warmSpareSettings
# operationId: updateNetworkWarmSpareSettings
export def "networks-warm-spare-settings update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Enable warm spare
  --spare-serial: string # Serial number of the warm spare appliance
  --uplink-mode: string # Uplink mode, either virtual or public
  --virtual-ip1: string # The WAN 1 shared IP
  --virtual-ip2: string # The WAN 2 shared IP
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/warmSpareSettings"))
  let req_body = {"enabled": $enabled, "spareSerial": $spare_serial, "uplinkMode": $uplink_mode, "virtualIp1": $virtual_ip1, "virtualIp2": $virtual_ip2} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the non-basic RF profiles for this network
#
# GET /networks/{networkId}/wireless/rfProfiles
# operationId: getNetworkWirelessRfProfiles
export def "networks-wireless-rf-profiles list" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-template-profiles: oneof<nothing, bool> # If the network is bound to a template, this parameter controls whether or not the non-basic RF profiles defined on the template should be included in the response alongside the non-basic profiles defined on the bound network. Defaults to false.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeTemplateProfiles" $include_template_profiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/wireless/rfProfiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates new RF profile for this network
#
# POST /networks/{networkId}/wireless/rfProfiles
# operationId: createNetworkWirelessRfProfile
# --apBandSettings shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
# --fiveGhzSettings shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
# --twoFourGhzSettings shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
export def "networks-wireless-rf-profiles create" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ap-band-settings: record # Settings that will be enabled if selectionType is set to 'ap'. — shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
  band_selection_type: string@band-selection-type-completer # Band selection can be set to either 'ssid' or 'ap'. This param is required on creation.
  --client-balancing-enabled: oneof<nothing, bool> # Steers client to best available access point. Can be either true or false. Defaults to true.
  --five-ghz-settings: record # Settings related to 5Ghz band — shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
  --min-bitrate-type: string@min-bitrate-type-completer # Minimum bitrate can be set to either 'band' or 'ssid'. Defaults to band.
  name: string # The name of the new profile. Must be unique. This param is required on creation.
  --two-four-ghz-settings: record # Settings related to 2.4Ghz band — shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/wireless/rfProfiles"))
  let req_body = {"apBandSettings": $ap_band_settings, "bandSelectionType": $band_selection_type, "clientBalancingEnabled": $client_balancing_enabled, "fiveGhzSettings": $five_ghz_settings, "minBitrateType": $min_bitrate_type, "name": $name, "twoFourGhzSettings": $two_four_ghz_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a RF Profile
#
# DELETE /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# operationId: deleteNetworkWirelessRfProfile
export def "networks-wireless-rf-profiles delete" [
  network_id: string
  rf_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), rf_profile_id: (encode-path-segment $rf_profile_id)} | format pattern "/networks/{network_id}/wireless/rfProfiles/{rf_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a RF profile
#
# GET /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# operationId: getNetworkWirelessRfProfile
export def "networks-wireless-rf-profiles get" [
  network_id: string
  rf_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), rf_profile_id: (encode-path-segment $rf_profile_id)} | format pattern "/networks/{network_id}/wireless/rfProfiles/{rf_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates specified RF profile for this network
#
# PUT /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# operationId: updateNetworkWirelessRfProfile
# --apBandSettings shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
# --fiveGhzSettings shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
# --twoFourGhzSettings shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
export def "networks-wireless-rf-profiles update" [
  network_id: string
  rf_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ap-band-settings: record # Settings that will be enabled if selectionType is set to 'ap'. — shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
  --band-selection-type: string@band-selection-type-completer # Band selection can be set to either 'ssid' or 'ap'.
  --client-balancing-enabled: oneof<nothing, bool> # Steers client to best available access point. Can be either true or false.
  --five-ghz-settings: record # Settings related to 5Ghz band — shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
  --min-bitrate-type: string@min-bitrate-type-completer # Minimum bitrate can be set to either 'band' or 'ssid'.
  --name: string # The name of the new profile. Must be unique.
  --two-four-ghz-settings: record # Settings related to 2.4Ghz band — shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list<int>}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), rf_profile_id: (encode-path-segment $rf_profile_id)} | format pattern "/networks/{network_id}/wireless/rfProfiles/{rf_profile_id}"))
  let req_body = {"apBandSettings": $ap_band_settings, "bandSelectionType": $band_selection_type, "clientBalancingEnabled": $client_balancing_enabled, "fiveGhzSettings": $five_ghz_settings, "minBitrateType": $min_bitrate_type, "name": $name, "twoFourGhzSettings": $two_four_ghz_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the wireless settings for a network
#
# GET /networks/{networkId}/wireless/settings
# operationId: getNetworkWirelessSettings
export def "networks-wireless-settings get" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/wireless/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the wireless settings for a network
#
# PUT /networks/{networkId}/wireless/settings
# operationId: updateNetworkWirelessSettings
export def "networks-wireless-settings update" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ipv6-bridge-enabled: oneof<nothing, bool> # Toggle for enabling or disabling IPv6 bridging in a network (Note: if enabled, SSIDs must also be configured to use bridge mode)
  --led-lights-on: oneof<nothing, bool> # Toggle for enabling or disabling LED lights on all APs in the network (making them run dark)
  --location-analytics-enabled: oneof<nothing, bool> # Toggle for enabling or disabling location analytics for your network
  --meshing-enabled: oneof<nothing, bool> # Toggle for enabling or disabling meshing in a network
  --upgrade-strategy: string@upgrade-strategy-completer # The upgrade strategy to apply to the network. Must be one of 'minimizeUpgradeTime' or 'minimizeClientDowntime'. Requires firmware version MR 26.8 or higher'
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/wireless/settings"))
  let req_body = {"ipv6BridgeEnabled": $ipv6_bridge_enabled, "ledLightsOn": $led_lights_on, "locationAnalyticsEnabled": $location_analytics_enabled, "meshingEnabled": $meshing_enabled, "upgradeStrategy": $upgrade_strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lock a set of devices
#
# PUT /networks/{network_id}/sm/devices/lock
# operationId: lockNetworkSmDevices
export def "networks-sm-devices-lock lock" [
  network_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # The ids of the devices to be locked.
  --pin: int # The pin number for locking macOS devices (a six digit number). Required only for macOS devices.
  --scope: string # The scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags of the devices to be wiped.
  --serials: string # The serials of the devices to be locked.
  --wifi-macs: string # The wifiMacs of the devices to be locked.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id)} | format pattern "/networks/{network_id}/sm/devices/lock"))
  let req_body = {"ids": $ids, "pin": $pin, "scope": $scope, "serials": $serials, "wifiMacs": $wifi_macs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns historical connectivity data (whether a device is regularly checking in to Dashboard).
#
# GET /networks/{network_id}/sm/{id}/connectivity
# operationId: getNetworkSmConnectivity
export def "networks-sm-connectivity get" [
  network_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), id: (encode-path-segment $id)} | format pattern "/networks/{network_id}/sm/{id}/connectivity") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return historical records of various Systems Manager network connection details for desktop devices.
#
# GET /networks/{network_id}/sm/{id}/desktopLogs
# operationId: getNetworkSmDesktopLogs
export def "networks-sm-desktop-logs get" [
  network_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), id: (encode-path-segment $id)} | format pattern "/networks/{network_id}/sm/{id}/desktopLogs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return historical records of commands sent to Systems Manager devices
#
# GET /networks/{network_id}/sm/{id}/deviceCommandLogs
# operationId: getNetworkSmDeviceCommandLogs
export def "networks-sm-device-command-logs get" [
  network_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), id: (encode-path-segment $id)} | format pattern "/networks/{network_id}/sm/{id}/deviceCommandLogs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return historical records of various Systems Manager client metrics for desktop devices.
#
# GET /networks/{network_id}/sm/{id}/performanceHistory
# operationId: getNetworkSmPerformanceHistory
export def "networks-sm-performance-history get" [
  network_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({network_id: (encode-path-segment $network_id), id: (encode-path-segment $id)} | format pattern "/networks/{network_id}/sm/{id}/performanceHistory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the organizations that the user has privileges on
#
# GET /organizations
# operationId: getOrganizations
export def "organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return an organization
#
# GET /organizations/{organizationId}
# operationId: getOrganization
export def "organizations get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the list of action batches in the organization
#
# GET /organizations/{organizationId}/actionBatches
# operationId: getOrganizationActionBatches
export def "organizations-action-batches get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Filter batches by status. Valid types are pending, completed, and failed.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/actionBatches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an action batch
#
# POST /organizations/{organizationId}/actionBatches
# operationId: createOrganizationActionBatch
# --actions item shape: {body?: record, operation: string, resource: string}
export def "organizations-action-batches create-batch" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  actions: list # A set of changes to make as part of this action (more details) — item shape: {body?: record, operation: string, resource: string}
  --confirmed: oneof<nothing, bool> # Set to true for immediate execution. Set to false if the action should be previewed before executing. This property cannot be unset once it is true. Defaults to false.
  --synchronous: oneof<nothing, bool> # Set to true to force the batch to run synchronous. There can be at most 20 actions in synchronous batch. Defaults to false.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/actionBatches"))
  let req_body = {"actions": $actions, "confirmed": $confirmed, "synchronous": $synchronous} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an action batch
#
# DELETE /organizations/{organizationId}/actionBatches/{actionBatchId}
# operationId: deleteOrganizationActionBatch
export def "organizations-action-batches delete-batch" [
  organization_id: string
  action_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), action_batch_id: (encode-path-segment $action_batch_id)} | format pattern "/organizations/{organization_id}/actionBatches/{action_batch_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an action batch
#
# PUT /organizations/{organizationId}/actionBatches/{actionBatchId}
# operationId: updateOrganizationActionBatch
export def "organizations-action-batches update-batch" [
  organization_id: string
  action_batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --confirmed: oneof<nothing, bool> # A boolean representing whether or not the batch has been confirmed. This property cannot be unset once it is true.
  --synchronous: oneof<nothing, bool> # Set to true to force the batch to run synchronous. There can be at most 20 actions in synchronous batch.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), action_batch_id: (encode-path-segment $action_batch_id)} | format pattern "/organizations/{organization_id}/actionBatches/{action_batch_id}"))
  let req_body = {"confirmed": $confirmed, "synchronous": $synchronous} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the dashboard administrators in this organization
#
# GET /organizations/{organizationId}/admins
# operationId: getOrganizationAdmins
export def "organizations-admins get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/admins"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new dashboard administrator
#
# POST /organizations/{organizationId}/admins
# operationId: createOrganizationAdmin
# --networks item shape: {access: string, id: string}
# --tags item shape: {access: string, tag: string}
export def "organizations-admins create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authentication-method: string@authentication-method-completer # The method of authentication the user will use to sign in to the Meraki dashboard. Can be one of 'Email' or 'Cisco SecureX Sign-On'. The default is Email authentication
  email: string # The email of the dashboard administrator. This attribute can not be updated.
  name: string # The name of the dashboard administrator
  --networks: list # The list of networks that the dashboard administrator has privileges on — item shape: {access: string, id: string}
  org_access: string@org-access-completer # The privilege of the dashboard administrator on the organization. Can be one of 'full', 'read-only', 'enterprise' or 'none'
  --tags: list # The list of tags that the dashboard administrator has privileges on — item shape: {access: string, tag: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/admins"))
  let req_body = {"authenticationMethod": $authentication_method, "email": $email, "name": $name, "networks": $networks, "orgAccess": $org_access, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Revoke all access for a dashboard administrator within this organization
#
# DELETE /organizations/{organizationId}/admins/{adminId}
# operationId: deleteOrganizationAdmin
export def "organizations-admins delete" [
  organization_id: string
  admin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), admin_id: (encode-path-segment $admin_id)} | format pattern "/organizations/{organization_id}/admins/{admin_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an administrator
#
# PUT /organizations/{organizationId}/admins/{adminId}
# operationId: updateOrganizationAdmin
# --networks item shape: {access: string, id: string}
# --tags item shape: {access: string, tag: string}
export def "organizations-admins update" [
  organization_id: string
  admin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the dashboard administrator
  --networks: list # The list of networks that the dashboard administrator has privileges on — item shape: {access: string, id: string}
  --org-access: string@org-access-completer # The privilege of the dashboard administrator on the organization. Can be one of 'full', 'read-only', 'enterprise' or 'none'
  --tags: list # The list of tags that the dashboard administrator has privileges on — item shape: {access: string, tag: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), admin_id: (encode-path-segment $admin_id)} | format pattern "/organizations/{organization_id}/admins/{admin_id}"))
  let req_body = {"name": $name, "networks": $networks, "orgAccess": $org_access, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the API requests made by an organization
#
# GET /organizations/{organizationId}/apiRequests
# operationId: getOrganizationApiRequests
export def "organizations-api-requests get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 31 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 31 days. The default is 31 days. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 50.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --admin-id: string # Filter the results by the ID of the admin who made the API requests
  --path: string # Filter the results by the path of the API requests
  --method: string # Filter the results by the method of the API requests (must be 'GET', 'PUT', 'POST' or 'DELETE')
  --response-code: int # Filter the results by the response code of the API requests
  --source-ip: string # Filter the results by the IP address of the originating API request
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar") (serialize-qp "adminId" $admin_id "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "responseCode" $response_code "scalar") (serialize-qp "sourceIp" $source_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/apiRequests") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return an aggregated overview of API requests data
#
# GET /organizations/{organizationId}/apiRequests/overview
# operationId: getOrganizationApiRequestsOverview
export def "organizations-api-requests-overview get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 31 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 31 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 31 days. The default is 31 days. (format: float)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/apiRequests/overview") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Claim a list of devices, licenses, and/or orders into an organization
#
# POST /organizations/{organizationId}/claim
# operationId: claimIntoOrganization
# --licenses item shape: {key: string, mode?: "addDevices"|"renew"}
export def "organizations-claim create-into" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --licenses: list # The licenses that should be claimed — item shape: {key: string, mode?: "addDevices"|"renew"}
  --orders: list<string> # The numbers of the orders that should be claimed
  --serials: list<string> # The serials of the devices that should be claimed
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/claim"))
  let req_body = {"licenses": $licenses, "orders": $orders, "serials": $serials} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a new organization by cloning the addressed organization
#
# POST /organizations/{organizationId}/clone
# operationId: cloneOrganization
export def "organizations-clone clone" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new organization
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/clone"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the configuration templates for this organization
#
# GET /organizations/{organizationId}/configTemplates
# operationId: getOrganizationConfigTemplates
export def "organizations-config-templates get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/configTemplates"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a configuration template
#
# DELETE /organizations/{organizationId}/configTemplates/{configTemplateId}
# operationId: deleteOrganizationConfigTemplate
export def "organizations-config-templates delete" [
  organization_id: string
  config_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), config_template_id: (encode-path-segment $config_template_id)} | format pattern "/organizations/{organization_id}/configTemplates/{config_template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the switch profiles for your switch template configuration
#
# GET /organizations/{organizationId}/configTemplates/{configTemplateId}/switchProfiles
# operationId: getOrganizationConfigTemplateSwitchProfiles
export def "organizations-config-templates-switch-profiles get" [
  organization_id: string
  config_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), config_template_id: (encode-path-segment $config_template_id)} | format pattern "/organizations/{organization_id}/configTemplates/{config_template_id}/switchProfiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View the Change Log for your organization
#
# GET /organizations/{organizationId}/configurationChanges
# operationId: getOrganizationConfigurationChanges
export def "organizations-configuration-changes get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 365 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 365 days. The default is 365 days. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 5000. Default is 5000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --network-id: string # Filters on the given network
  --admin-id: string # Filters on the given Admin
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar") (serialize-qp "networkId" $network_id "scalar") (serialize-qp "adminId" $admin_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/configurationChanges") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the status of every Meraki device in the organization
#
# GET /organizations/{organizationId}/deviceStatuses
# operationId: getOrganizationDeviceStatuses
export def "organizations-device-statuses get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/deviceStatuses"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the devices in an organization
#
# GET /organizations/{organizationId}/devices
# operationId: getOrganizationDevices
export def "organizations-devices get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --configuration-updated-after: string # Filter results by whether or not the device's configuration has been updated after the given timestamp
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar") (serialize-qp "configurationUpdatedAfter" $configuration_updated_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the monitored media servers for this organization
#
# GET /organizations/{organizationId}/insight/monitoredMediaServers
# operationId: getOrganizationInsightMonitoredMediaServers
export def "organizations-insight-monitored-media-servers list" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/insight/monitoredMediaServers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a media server to be monitored for this organization
#
# POST /organizations/{organizationId}/insight/monitoredMediaServers
# operationId: createOrganizationInsightMonitoredMediaServer
export def "organizations-insight-monitored-media-servers create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The IP address (IPv4 only) or hostname of the media server to monitor
  name: string # The name of the VoIP provider
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/insight/monitoredMediaServers"))
  let req_body = {"address": $address, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a monitored media server from this organization
#
# DELETE /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# operationId: deleteOrganizationInsightMonitoredMediaServer
export def "organizations-insight-monitored-media-servers delete" [
  organization_id: string
  monitored_media_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), monitored_media_server_id: (encode-path-segment $monitored_media_server_id)} | format pattern "/organizations/{organization_id}/insight/monitoredMediaServers/{monitored_media_server_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a monitored media server for this organization
#
# GET /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# operationId: getOrganizationInsightMonitoredMediaServer
export def "organizations-insight-monitored-media-servers get" [
  organization_id: string
  monitored_media_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), monitored_media_server_id: (encode-path-segment $monitored_media_server_id)} | format pattern "/organizations/{organization_id}/insight/monitoredMediaServers/{monitored_media_server_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a monitored media server for this organization
#
# PUT /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# operationId: updateOrganizationInsightMonitoredMediaServer
export def "organizations-insight-monitored-media-servers update" [
  organization_id: string
  monitored_media_server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The IP address (IPv4 only) or hostname of the media server to monitor
  --name: string # The name of the VoIP provider
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), monitored_media_server_id: (encode-path-segment $monitored_media_server_id)} | format pattern "/organizations/{organization_id}/insight/monitoredMediaServers/{monitored_media_server_id}"))
  let req_body = {"address": $address, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the inventory for an organization
#
# GET /organizations/{organizationId}/inventory
# operationId: getOrganizationInventory
export def "organizations-inventory get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-license-info: oneof<nothing, bool> # When this parameter is true, each entity in the response will include the license expiration date of the device (if any). Only applies to organizations that are on the per-device licensing model. Defaults to false.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeLicenseInfo" $include_license_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/inventory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return an overview of the license state for an organization
#
# GET /organizations/{organizationId}/licenseState
# operationId: getOrganizationLicenseState
export def "organizations-license-state get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/licenseState"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the licenses for an organization
#
# GET /organizations/{organizationId}/licenses
# operationId: getOrganizationLicenses
export def "organizations-licenses list" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --device-serial: string # Filter the licenses to those assigned to a particular device
  --network-id: string # Filter the licenses to those assigned in a particular network
  --state: string@state-completer # Filter the licenses to those in a particular state. Can be one of 'active', 'expired', 'expiring', 'recentlyQueued', 'unused' or 'unusedActive'
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar") (serialize-qp "deviceSerial" $device_serial "scalar") (serialize-qp "networkId" $network_id "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/licenses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign SM seats to a network
#
# POST /organizations/{organizationId}/licenses/assignSeats
# operationId: assignOrganizationLicensesSeats
export def "organizations-licenses-assign-seats assign" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  license_id: string # The ID of the SM license to assign seats from
  network_id: string # The ID of the SM network to assign the seats to
  seat_count: int # The number of seats to assign to the SM network. Must be less than or equal to the total number of seats of the license
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/licenses/assignSeats"))
  let req_body = {"licenseId": $license_id, "networkId": $network_id, "seatCount": $seat_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Move SM seats to another organization
#
# POST /organizations/{organizationId}/licenses/moveSeats
# operationId: moveOrganizationLicensesSeats
export def "organizations-licenses-move-seats move" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dest_organization_id: string # The ID of the organization to move the SM seats to
  license_id: string # The ID of the SM license to move the seats from
  seat_count: int # The number of seats to move to the new organization. Must be less than or equal to the total number of seats of the license
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/licenses/moveSeats"))
  let req_body = {"destOrganizationId": $dest_organization_id, "licenseId": $license_id, "seatCount": $seat_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Renew SM seats of a license
#
# POST /organizations/{organizationId}/licenses/renewSeats
# operationId: renewOrganizationLicensesSeats
export def "organizations-licenses-renew-seats create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  license_id_to_renew: string # The ID of the SM license to renew. This license must already be assigned to an SM network
  unused_license_id: string # The SM license to use to renew the seats on 'licenseIdToRenew'. This license must have at least as many seats available as there are seats on 'licenseIdToRenew'
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/licenses/renewSeats"))
  let req_body = {"licenseIdToRenew": $license_id_to_renew, "unusedLicenseId": $unused_license_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Display a license
#
# GET /organizations/{organizationId}/licenses/{licenseId}
# operationId: getOrganizationLicense
export def "organizations-licenses get" [
  organization_id: string
  license_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), license_id: (encode-path-segment $license_id)} | format pattern "/organizations/{organization_id}/licenses/{license_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the networks in an organization
#
# GET /organizations/{organizationId}/networks
# operationId: getOrganizationNetworks
export def "organizations-networks get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-template-id: string # An optional parameter that is the ID of a config template. Will return all networks bound to that template.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configTemplateId" $config_template_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/networks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a network
#
# POST /organizations/{organizationId}/networks
# operationId: createOrganizationNetwork
export def "organizations-networks create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --copy-from-network-id: string # The ID of the network to copy configuration from. Other provided parameters will override the copied configuration, except type which must match this network's type exactly.
  --disable-my-meraki-com: oneof<nothing, bool> # Disables the local device status pages (my.meraki.com, ap.meraki.com, switch.meraki.com, wired.meraki.com). Optional (defaults to false)
  --disable-remote-status-page: oneof<nothing, bool> # Disables access to the device status page (http://[device's LAN IP]). Optional. Can only be set if disableMyMerakiCom is set to false
  name: string # The name of the new network
  --tags: string # A space-separated list of tags to be applied to the network
  --time-zone: string # The timezone of the network. For a list of allowed timezones, please see the 'TZ' column in the table in this article.
  type: string # The type of the new network. Valid types are wireless, appliance, switch, systemsManager, camera, cellularGateway, environmental, or a space-separated list of those for a combined network.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/networks"))
  let req_body = {"copyFromNetworkId": $copy_from_network_id, "disableMyMerakiCom": $disable_my_meraki_com, "disableRemoteStatusPage": $disable_remote_status_page, "name": $name, "tags": $tags, "timeZone": $time_zone, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Combine multiple networks into a single network
#
# POST /organizations/{organizationId}/networks/combine
# operationId: combineOrganizationNetworks
export def "organizations-networks-combine create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enrollment-string: string # A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. Please note that changing this field may cause existing bookmarks to break. All networks that are part of this combined network will have their enrollment string appended by '-network_type'. If left empty, all exisitng enrollment strings will be deleted.
  name: string # The name of the combined network
  network_ids: list<string> # A list of the network IDs that will be combined. If an ID of a combined network is included in this list, the other networks in the list will be grouped into that network
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/networks/combine"))
  let req_body = {"enrollmentString": $enrollment_string, "name": $name, "networkIds": $network_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the OpenAPI 2.0 Specification of the organization's API documentation in JSON
#
# GET /organizations/{organizationId}/openapiSpec
# operationId: getOrganizationOpenapiSpec
export def "organizations-openapi-spec get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/openapiSpec"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the SAML roles for this organization
#
# GET /organizations/{organizationId}/samlRoles
# operationId: getOrganizationSamlRoles
export def "organizations-saml-roles list" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/samlRoles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a SAML role
#
# POST /organizations/{organizationId}/samlRoles
# operationId: createOrganizationSamlRole
# --networks item shape: {access: string, id: string}
# --tags item shape: {access: string, tag: string}
export def "organizations-saml-roles create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --networks: list # The list of networks that the SAML administrator has privileges on — item shape: {access: string, id: string}
  org_access: string # The privilege of the SAML administrator on the organization
  role: string # The role of the SAML administrator
  --tags: list # The list of tags that the SAML administrator has privleges on — item shape: {access: string, tag: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/samlRoles"))
  let req_body = {"networks": $networks, "orgAccess": $org_access, "role": $role, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return a SAML role
#
# GET /organizations/{organizationId}/samlRoles/{samlRoleId}
# operationId: getOrganizationSamlRole
export def "organizations-saml-roles get" [
  organization_id: string
  saml_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), saml_role_id: (encode-path-segment $saml_role_id)} | format pattern "/organizations/{organization_id}/samlRoles/{saml_role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a SAML role
#
# PUT /organizations/{organizationId}/samlRoles/{samlRoleId}
# operationId: updateOrganizationSamlRole
# --networks item shape: {access: string, id: string}
# --tags item shape: {access: string, tag: string}
export def "organizations-saml-roles update" [
  organization_id: string
  saml_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --networks: list # The list of networks that the SAML administrator has privileges on — item shape: {access: string, id: string}
  --org-access: string # The privilege of the SAML administrator on the organization
  --role: string # The role of the SAML administrator
  --tags: list # The list of tags that the SAML administrator has privleges on — item shape: {access: string, tag: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), saml_role_id: (encode-path-segment $saml_role_id)} | format pattern "/organizations/{organization_id}/samlRoles/{saml_role_id}"))
  let req_body = {"networks": $networks, "orgAccess": $org_access, "role": $role, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all supported intrusion settings for an organization
#
# GET /organizations/{organizationId}/security/intrusionSettings
# operationId: getOrganizationSecurityIntrusionSettings
export def "organizations-security-intrusion-settings get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/security/intrusionSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets supported intrusion settings for an organization
#
# PUT /organizations/{organizationId}/security/intrusionSettings
# operationId: updateOrganizationSecurityIntrusionSettings
# --whitelistedRules item shape: {message?: string, ruleId: string}
export def "organizations-security-intrusion-settings update" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  whitelisted_rules: list # Sets a list of specific SNORT signatures to allow — item shape: {message?: string, ruleId: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/security/intrusionSettings"))
  let req_body = {"whitelistedRules": $whitelisted_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the security events (intrusion detection only) for an organization
#
# GET /organizations/{organizationId}/securityEvents
# operationId: getOrganizationSecurityEvents
export def "organizations-security-events get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. Data is gathered after the specified t0 value. The maximum lookback period is 365 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 365 days after t0.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 365 days. The default is 31 days. (format: float)
  --per-page: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 100.
  --starting-after: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --ending-before: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "startingAfter" $starting_after "scalar") (serialize-qp "endingBefore" $ending_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/securityEvents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the SNMP settings for an organization
#
# GET /organizations/{organizationId}/snmp
# operationId: getOrganizationSnmp
export def "organizations-snmp get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/snmp"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the third party VPN peers for an organization
#
# GET /organizations/{organizationId}/thirdPartyVPNPeers
# operationId: getOrganizationThirdPartyVPNPeers
export def "organizations-third-party-vpn-peers get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/thirdPartyVPNPeers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the third party VPN peers for an organization
#
# PUT /organizations/{organizationId}/thirdPartyVPNPeers
# operationId: updateOrganizationThirdPartyVPNPeers
# --peers item shape: {ikeVersion?: "1"|"2", ipsecPolicies?: record, ipsecPoliciesPreset?: string, name: string, networkTags?: list<string>, privateSubnets: list<string>, publicIp: string, remoteId?: string, secret: string}
export def "organizations-third-party-vpn-peers update" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  peers: list # The list of VPN peers — item shape: {ikeVersion?: "1"|"2", ipsecPolicies?: record, ipsecPoliciesPreset?: string, name: string, networkTags?: list<string>, privateSubnets: list<string>, publicIp: string, remoteId?: string, secret: string}
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/thirdPartyVPNPeers"))
  let req_body = {"peers": $peers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Return the uplink loss and latency for every MX in the organization from at latest 2 minutes ago
#
# GET /organizations/{organizationId}/uplinksLossAndLatency
# operationId: getOrganizationUplinksLossAndLatency
export def "organizations-uplinks-loss-and-latency get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t0: string # The beginning of the timespan for the data. The maximum lookback period is 60 days from today.
  --t1: string # The end of the timespan for the data. t1 can be a maximum of 5 minutes after t0. The latest possible time that t1 can be is 2 minutes into the past.
  --timespan: float # The timespan for which the information will be fetched. If specifying timespan, do not specify parameters t0 and t1. The value must be in seconds and be less than or equal to 5 minutes. The default is 5 minutes. (format: float)
  --uplink: string@uplink-completer # Optional filter for a specific WAN uplink. Valid uplinks are wan1, wan2, cellular. Default will return all uplinks.
  --ip: string # Optional filter for a specific destination IP. Default will return all destination IPs.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "uplink" $uplink "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/uplinksLossAndLatency") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the firewall rules for an organization's site-to-site VPN
#
# GET /organizations/{organizationId}/vpnFirewallRules
# operationId: getOrganizationVpnFirewallRules
export def "organizations-vpn-firewall-rules get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/vpnFirewallRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the firewall rules of an organization's site-to-site VPN
#
# PUT /organizations/{organizationId}/vpnFirewallRules
# operationId: updateOrganizationVpnFirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
export def "organizations-vpn-firewall-rules update" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslog-default-rule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/organizations/{organization_id}/vpnFirewallRules"))
  let req_body = {"rules": $rules, "syslogDefaultRule": $syslog_default_rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
