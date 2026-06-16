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
def objectType-completer [] { ["person" "vehicle"] }
def motionDetectorVersion-completer [] { ["1" "2"] }
def quality-completer [] { ["Enhanced" "High" "Standard"] }
def resolution-completer [] { ["1080x1080" "1280x720" "1920x1080" "2058x2058"] }
def majorMinorAssignmentMode-completer [] { ["Non-unique" "Unique"] }
def band-completer [] { ["2.4" "5"] }
def devicePolicy-completer [] { ["Allowed" "Blocked" "Group policy" "Normal" "Per connection" "Whitelisted"] }
def urlCategoryListSize-completer [] { ["fullList" "topSites"] }
def uplink-completer [] { ["cellular" "wan1" "wan2"] }
def access-completer [] { ["blocked" "restricted" "unrestricted"] }
def type-completer [] { ["delete" "restrict processing"] }
def idsRulesets-completer [] { ["balanced" "connectivity" "security"] }
def mode-completer [] { ["detection" "disabled" "prevention"] }
def mode-completer-1 [] { ["disabled" "enabled"] }
def mode-completer-2 [] { ["hub" "none" "spoke"] }
def ssidNumber-completer [] { ["0" "1" "10" "11" "12" "13" "14" "2" "3" "4" "5" "6" "7" "8" "9"] }
def authMode-completer [] { ["8021x-google" "8021x-localradius" "8021x-meraki" "8021x-nac" "8021x-radius" "ipsk-with-radius" "ipsk-without-radius" "open" "open-enhanced" "open-with-nac" "open-with-radius" "psk"] }
def encryptionMode-completer [] { ["wep" "wpa"] }
def enterpriseAdminAccess-completer [] { ["access disabled" "access enabled"] }
def radiusFailoverPolicy-completer [] { ["Allow access" "Deny access"] }
def radiusLoadBalancingPolicy-completer [] { ["Round robin" "Strict priority order"] }
def splashPage-completer [] { ["Billing" "Cisco ISE" "Click-through splash page" "Facebook Wi-Fi" "Google Apps domain" "Google OAuth" "None" "Password-protected with Active Directory" "Password-protected with LDAP" "Password-protected with Meraki RADIUS" "Password-protected with custom RADIUS" "SMS authentication" "Sponsored guest" "Systems Manager Sentry"] }
def wpaEncryptionMode-completer [] { ["WPA1 and WPA2" "WPA1 only" "WPA2 only" "WPA3 Transition Mode" "WPA3 only"] }
def protocol-completer [] { ["ANY" "TCP" "UDP"] }
def deviceType-completer [] { ["appliance" "combined" "switch" "wireless"] }
def dhcpHandling-completer [] { ["Do not respond to DHCP requests" "Relay DHCP to another server" "Run a DHCP server"] }
def dhcpLeaseTime-completer [] { ["1 day" "1 hour" "1 week" "12 hours" "30 minutes" "4 hours"] }
def bandSelectionType-completer [] { ["ap" "ssid"] }
def minBitrateType-completer [] { ["band" "ssid"] }
def upgradeStrategy-completer [] { ["minimizeClientDowntime" "minimizeUpgradeTime"] }
def status-completer [] { ["completed" "failed" "pending"] }
def authenticationMethod-completer [] { ["Cisco SecureX Sign-On" "Email"] }
def orgAccess-completer [] { ["enterprise" "full" "none" "read-only"] }
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
  let full_url = (build-url $base $"/devices/($serial)/camera/analytics/live")
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
  --objectType: string@objectType-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "objectType" $objectType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($serial)/camera/analytics/overview" $qp)
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
  --objectType: string@objectType-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "objectType" $objectType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($serial)/camera/analytics/recent" $qp)
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
  let full_url = (build-url $base $"/devices/($serial)/camera/analytics/zones")
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
  zoneId: string
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
  --objectType: string@objectType-completer # [optional] The object type for which analytics will be retrieved. The default object type is person. The available types are [person, vehicle].
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "objectType" $objectType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($serial)/camera/analytics/zones/($zoneId)/history" $qp)
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
  let full_url = (build-url $base $"/devices/($serial)/camera/qualityAndRetentionSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update quality and retention settings for the given camera
#
# PUT /devices/{serial}/camera/qualityAndRetentionSettings
# operationId: updateDeviceCameraQualityAndRetentionSettings
export def "devices-camera-quality-and-retention-settings updateDeviceCameraQualityAndRetentionSettings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --audioRecordingEnabled: oneof<nothing, bool> # Boolean indicating if audio recording is enabled(true) or disabled(false) on the camera
  --motionBasedRetentionEnabled: oneof<nothing, bool> # Boolean indicating if motion-based retention is enabled(true) or disabled(false) on the camera
  --motionDetectorVersion: int@motionDetectorVersion-completer # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  --profileId: string # The ID of a quality and retention profile to assign to the camera. The profile's settings will override all of the per-camera quality and retention settings. If the value of this parameter is null, any existing profile will be unassigned from the camera.
  --quality: string@quality-completer # Quality of the camera. Can be one of 'Standard', 'High' or 'Enhanced'. Not all qualities are supported by every camera model.
  --resolution: string@resolution-completer # Resolution of the camera. Can be one of '1280x720', '1920x1080', '1080x1080' or '2058x2058'. Not all resolutions are supported by every camera model.
  --restrictedBandwidthModeEnabled: oneof<nothing, bool> # Boolean indicating if restricted bandwidth is enabled(true) or disabled(false) on the camera. This setting does not apply to MV2 cameras.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($serial)/camera/qualityAndRetentionSettings")
  let body = {audioRecordingEnabled: $audioRecordingEnabled, motionBasedRetentionEnabled: $motionBasedRetentionEnabled, motionDetectorVersion: $motionDetectorVersion, profileId: $profileId, quality: $quality, resolution: $resolution, restrictedBandwidthModeEnabled: $restrictedBandwidthModeEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/devices/($serial)/camera/video/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update video settings for the given camera
#
# PUT /devices/{serial}/camera/video/settings
# operationId: updateDeviceCameraVideoSettings
export def "devices-camera-video-settings updateDeviceCameraVideoSettings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --externalRtspEnabled: oneof<nothing, bool> # Boolean indicating if external rtsp stream is exposed
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($serial)/camera/video/settings")
  let body = {externalRtspEnabled: $externalRtspEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/devices/($serial)/cellularGateway/settings")
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
export def "devices-cellular-gateway-settings updateDeviceCellularGatewaySettings" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fixedIpAssignments: list # list of all fixed IP assignments for a single MG — item shape: {ip: string, mac: string, name?: string}
  --reservedIpRanges: list # list of all reserved IP ranges for a single MG — item shape: {comment: string, end: string, start: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($serial)/cellularGateway/settings")
  let body = {fixedIpAssignments: $fixedIpAssignments, reservedIpRanges: $reservedIpRanges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/devices/($serial)/cellularGateway/settings/portForwardingRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the port forwarding rules for a single MG.
#
# PUT /devices/{serial}/cellularGateway/settings/portForwardingRules
# operationId: updateDeviceCellularGatewaySettingsPortForwardingRules
# --rules item shape: {access: string, allowedIps?: list, lanIp: string, localPort: string, name?: string, protocol: string, publicPort: string}
export def "devices-cellular-gateway-settings-port-forwarding-rules updateDeviceCellularGatewaySettingsPortForwardingRules" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An array of port forwarding params — item shape: {access: string, allowedIps?: list, lanIp: string, localPort: string, name?: string, protocol: string, publicPort: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($serial)/cellularGateway/settings/portForwardingRules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/devices/($serial)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cycle a set of switch ports
#
# POST /devices/{serial}/switch/ports/cycle
# operationId: cycleDeviceSwitchPorts
export def "devices-switch-ports-cycle cycleDeviceSwitchPorts" [
  serial: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ports: list # List of switch ports. Example: [1, 2-5, 1_MA-MOD-8X10G_1, 1_MA-MOD-8X10G_2-1_MA-MOD-8X10G_8]
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($serial)/switch/ports/cycle")
  let body = {ports: $ports} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/devices/($serial)/switchPortStatuses" $qp)
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
  let full_url = (build-url $base $"/devices/($serial)/switchPortStatuses/packets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the bluetooth settings for a wireless device
#
# PUT /devices/{serial}/wireless/bluetooth/settings
# operationId: updateDeviceWirelessBluetoothSettings
export def "devices-wireless-bluetooth-settings updateDeviceWirelessBluetoothSettings" [
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
  let full_url = (build-url $base $"/devices/($serial)/wireless/bluetooth/settings")
  let body = {major: $major, minor: $minor, uuid: $uuid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a network
#
# DELETE /networks/{networkId}
# operationId: deleteNetwork
export def "networks delete" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a network
#
# GET /networks/{networkId}
# operationId: getNetwork
export def "networks get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a network
#
# PUT /networks/{networkId}
# operationId: updateNetwork
export def "networks updateNetwork" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disableMyMerakiCom: oneof<nothing, bool> # Disables the local device status pages (<a target='_blank' href='http://my.meraki.com/'>my.meraki.com, </a><a target='_blank' href='http://ap.meraki.com/'>ap.meraki.com, </a><a target='_blank' href='http://switch.meraki.com/'>switch.meraki.com, </a><a target='_blank' href='http://wired.meraki.com/'>wired.meraki.com</a>). Optional (defaults to false)
  --disableRemoteStatusPage: oneof<nothing, bool> # Disables access to the device status page (<a target='_blank'>http://[device's LAN IP])</a>. Optional. Can only be set if disableMyMerakiCom is set to false
  --enrollmentString: string # A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. Please note that changing this field may cause existing bookmarks to break.
  --name: string # The name of the network
  --tags: string # A space-separated list of tags to be applied to the network
  --timeZone: string # The timezone of the network. For a list of allowed timezones, please see the 'TZ' column in the table in <a target='_blank' href='https://en.wikipedia.org/wiki/List_of_tz_database_time_zones'>this article.</a>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)")
  let body = {disableMyMerakiCom: $disableMyMerakiCom, disableRemoteStatusPage: $disableRemoteStatusPage, enrollmentString: $enrollmentString, name: $name, tags: $tags, timeZone: $timeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the access policies for this network
#
# GET /networks/{networkId}/accessPolicies
# operationId: getNetworkAccessPolicies
export def "networks-access-policies get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/accessPolicies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Air Marshal scan results from a network
#
# GET /networks/{networkId}/airMarshal
# operationId: getNetworkAirMarshal
export def "networks-air-marshal get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/airMarshal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the alert configuration for this network
#
# GET /networks/{networkId}/alertSettings
# operationId: getNetworkAlertSettings
export def "networks-alert-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/alertSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the alert configuration for this network
#
# PUT /networks/{networkId}/alertSettings
# operationId: updateNetworkAlertSettings
# --alerts item shape: {alertDestinations?: record, enabled?: bool, filters?: record, type: string}
# --defaultDestinations shape: {allAdmins?: bool, emails?: list, httpServerIds?: list, snmp?: bool}
export def "networks-alert-settings updateNetworkAlertSettings" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alerts: list # Alert-specific configuration for each type. Only alerts that pertain to the network can be updated. — item shape: {alertDestinations?: record, enabled?: bool, filters?: record, type: string}
  --defaultDestinations: record # The network-wide destinations for all alerts on the network. — shape: {allAdmins?: bool, emails?: list, httpServerIds?: list, snmp?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/alertSettings")
  let body = {alerts: $alerts, defaultDestinations: $defaultDestinations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the inbound firewall rules for an MX network
#
# GET /networks/{networkId}/appliance/firewall/inboundFirewallRules
# operationId: getNetworkApplianceFirewallInboundFirewallRules
export def "networks-appliance-firewall-inbound-firewall-rules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/appliance/firewall/inboundFirewallRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the inbound firewall rules of an MX network
#
# PUT /networks/{networkId}/appliance/firewall/inboundFirewallRules
# operationId: updateNetworkApplianceFirewallInboundFirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
export def "networks-appliance-firewall-inbound-firewall-rules updateNetworkApplianceFirewallInboundFirewallRules" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslogDefaultRule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/appliance/firewall/inboundFirewallRules")
  let body = {rules: $rules, syslogDefaultRule: $syslogDefaultRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List per-port VLAN settings for all ports of a MX.
#
# GET /networks/{networkId}/appliancePorts
# operationId: getNetworkAppliancePorts
export def "networks-appliance-ports list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/appliancePorts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return per-port VLAN settings for a single MX port.
#
# GET /networks/{networkId}/appliancePorts/{appliancePortId}
# operationId: getNetworkAppliancePort
export def "networks-appliance-ports get" [
  networkId: string
  appliancePortId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/appliancePorts/($appliancePortId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the per-port VLAN settings for a single MX port.
#
# PUT /networks/{networkId}/appliancePorts/{appliancePortId}
# operationId: updateNetworkAppliancePort
export def "networks-appliance-ports updateNetworkAppliancePort" [
  networkId: string
  appliancePortId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessPolicy: string # The name of the policy. Only applicable to Access ports. Valid values are: 'open', '8021x-radius', 'mac-radius', 'hybris-radius' for MX64 or Z3 or any MX supporting the per port authentication feature. Otherwise, 'open' is the only valid value and 'open' is the default value if the field is missing.
  --allowedVlans: string # Comma-delimited list of the VLAN ID's allowed on the port, or 'all' to permit all VLAN's on the port.
  --dropUntaggedTraffic: oneof<nothing, bool> # Trunk port can Drop all Untagged traffic. When true, no VLAN is required. Access ports cannot have dropUntaggedTraffic set to true.
  --enabled: oneof<nothing, bool> # The status of the port
  --type: string # The type of the port: 'access' or 'trunk'.
  --vlan: int # Native VLAN when the port is in Trunk mode. Access VLAN when the port is in Access mode.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/appliancePorts/($appliancePortId)")
  let body = {accessPolicy: $accessPolicy, allowedVlans: $allowedVlans, dropUntaggedTraffic: $dropUntaggedTraffic, enabled: $enabled, type: $type, vlan: $vlan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bind a network to a template.
#
# POST /networks/{networkId}/bind
# operationId: bindNetwork
export def "networks-bind bindNetwork" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoBind: oneof<nothing, bool> # Optional boolean indicating whether the network's switches should automatically bind to profiles of the same model. Defaults to false if left unspecified. This option only affects switch networks and switch templates. Auto-bind is not valid unless the switch template has at least one profile and has at most one profile per switch model.
  configTemplateId: string # The ID of the template to which the network should be bound.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/bind")
  let body = {autoBind: $autoBind, configTemplateId: $configTemplateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the Bluetooth clients seen by APs in this network
#
# GET /networks/{networkId}/bluetoothClients
# operationId: getNetworkBluetoothClients
export def "networks-bluetooth-clients list" [
  networkId: string
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
  --perPage: int # The number of entries per page returned. Acceptable range is 5 - 1000. Default is 10.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --includeConnectivityHistory: oneof<nothing, bool> # Include the connectivity history for this client
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar") (serialize-qp "includeConnectivityHistory" $includeConnectivityHistory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/bluetoothClients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a Bluetooth client
#
# GET /networks/{networkId}/bluetoothClients/{bluetoothClientId}
# operationId: getNetworkBluetoothClient
export def "networks-bluetooth-clients get" [
  networkId: string
  bluetoothClientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeConnectivityHistory: oneof<nothing, bool> # Include the connectivity history for this client
  --connectivityHistoryTimespan: int # The timespan, in seconds, for the connectivityHistory data. By default 1 day, 86400, will be used.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeConnectivityHistory" $includeConnectivityHistory "scalar") (serialize-qp "connectivityHistoryTimespan" $connectivityHistoryTimespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/bluetoothClients/($bluetoothClientId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the Bluetooth settings for a network. <a href="https://documentation.meraki.com/MR/Bluetooth/Bluetooth_Low_Energy_(BLE)">Bluetooth settings</a> must be enabled on the network.
#
# GET /networks/{networkId}/bluetoothSettings
# operationId: getNetworkBluetoothSettings
export def "networks-bluetooth-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/bluetoothSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the Bluetooth settings for a network
#
# PUT /networks/{networkId}/bluetoothSettings
# operationId: updateNetworkBluetoothSettings
export def "networks-bluetooth-settings updateNetworkBluetoothSettings" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advertisingEnabled: oneof<nothing, bool> # Whether APs will advertise beacons.
  --major: int # The major number to be used in the beacon identifier. Only valid in 'Non-unique' mode.
  --majorMinorAssignmentMode: string@majorMinorAssignmentMode-completer # The way major and minor number should be assigned to nodes in the network. ('Unique', 'Non-unique')
  --minor: int # The minor number to be used in the beacon identifier. Only valid in 'Non-unique' mode.
  --scanningEnabled: oneof<nothing, bool> # Whether APs will scan for Bluetooth enabled clients.
  --uuid: string # The UUID to be used in the beacon identifier.
]: any -> record<advertisingEnabled: bool, major: int, majorMinorAssignmentMode: string, minor: int, scanningEnabled: bool, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/bluetoothSettings")
  let body = {advertisingEnabled: $advertisingEnabled, major: $major, majorMinorAssignmentMode: $majorMinorAssignmentMode, minor: $minor, scanningEnabled: $scanningEnabled, uuid: $uuid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the quality retention profiles for this network
#
# GET /networks/{networkId}/camera/qualityRetentionProfiles
# operationId: getNetworkCameraQualityRetentionProfiles
export def "networks-camera-quality-retention-profiles list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/camera/qualityRetentionProfiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates new quality retention profile for this network.
#
# POST /networks/{networkId}/camera/qualityRetentionProfiles
# operationId: createNetworkCameraQualityRetentionProfile
# --videoSettings shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
export def "networks-camera-quality-retention-profiles createNetworkCameraQualityRetentionProfile" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --audioRecordingEnabled: oneof<nothing, bool> # Whether or not to record audio. Can be either true or false. Defaults to false.
  --cloudArchiveEnabled: oneof<nothing, bool> # Create redundant video backup using Cloud Archive. Can be either true or false. Defaults to false.
  --maxRetentionDays: int # The maximum number of days for which the data will be stored, or 'null' to keep data until storage space runs out. If the former, it can be one of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 30, 60, 90] days.
  --motionBasedRetentionEnabled: oneof<nothing, bool> # Deletes footage older than 3 days in which no motion was detected. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --motionDetectorVersion: int # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  name: string # The name of the new profile. Must be unique. This parameter is required.
  --restrictedBandwidthModeEnabled: oneof<nothing, bool> # Disable features that require additional bandwidth such as Motion Recap. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --scheduleId: string # Schedule for which this camera will record video, or 'null' to always record.
  --videoSettings: record # Video quality and resolution settings for all the camera models. — shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/camera/qualityRetentionProfiles")
  let body = {audioRecordingEnabled: $audioRecordingEnabled, cloudArchiveEnabled: $cloudArchiveEnabled, maxRetentionDays: $maxRetentionDays, motionBasedRetentionEnabled: $motionBasedRetentionEnabled, motionDetectorVersion: $motionDetectorVersion, name: $name, restrictedBandwidthModeEnabled: $restrictedBandwidthModeEnabled, scheduleId: $scheduleId, videoSettings: $videoSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an existing quality retention profile for this network.
#
# DELETE /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# operationId: deleteNetworkCameraQualityRetentionProfile
export def "networks-camera-quality-retention-profiles delete" [
  networkId: string
  qualityRetentionProfileId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/camera/qualityRetentionProfiles/($qualityRetentionProfileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single quality retention profile
#
# GET /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# operationId: getNetworkCameraQualityRetentionProfile
export def "networks-camera-quality-retention-profiles get" [
  networkId: string
  qualityRetentionProfileId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/camera/qualityRetentionProfiles/($qualityRetentionProfileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing quality retention profile for this network.
#
# PUT /networks/{networkId}/camera/qualityRetentionProfiles/{qualityRetentionProfileId}
# operationId: updateNetworkCameraQualityRetentionProfile
# --videoSettings shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
export def "networks-camera-quality-retention-profiles updateNetworkCameraQualityRetentionProfile" [
  networkId: string
  qualityRetentionProfileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --audioRecordingEnabled: oneof<nothing, bool> # Whether or not to record audio. Can be either true or false. Defaults to false.
  --cloudArchiveEnabled: oneof<nothing, bool> # Create redundant video backup using Cloud Archive. Can be either true or false. Defaults to false.
  --maxRetentionDays: int # The maximum number of days for which the data will be stored, or 'null' to keep data until storage space runs out. If the former, it can be one of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 30, 60, 90] days.
  --motionBasedRetentionEnabled: oneof<nothing, bool> # Deletes footage older than 3 days in which no motion was detected. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --motionDetectorVersion: int # The version of the motion detector that will be used by the camera. Only applies to Gen 2 cameras. Defaults to v2.
  --name: string # The name of the new profile. Must be unique.
  --restrictedBandwidthModeEnabled: oneof<nothing, bool> # Disable features that require additional bandwidth such as Motion Recap. Can be either true or false. Defaults to false. This setting does not apply to MV2 cameras.
  --scheduleId: string # Schedule for which this camera will record video, or 'null' to always record.
  --videoSettings: record # Video quality and resolution settings for all the camera models. — shape: {MV12/MV22/MV72?: record, MV12WE?: record, MV13?: record, MV21/MV71?: record, MV22X/MV72X?: record, MV32?: record, MV33?: record, MV52?: record, MV63?: record, MV63X?: record, MV93?: record, MV93X?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/camera/qualityRetentionProfiles/($qualityRetentionProfileId)")
  let body = {audioRecordingEnabled: $audioRecordingEnabled, cloudArchiveEnabled: $cloudArchiveEnabled, maxRetentionDays: $maxRetentionDays, motionBasedRetentionEnabled: $motionBasedRetentionEnabled, motionDetectorVersion: $motionDetectorVersion, name: $name, restrictedBandwidthModeEnabled: $restrictedBandwidthModeEnabled, scheduleId: $scheduleId, videoSettings: $videoSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of all camera recording schedules.
#
# GET /networks/{networkId}/camera/schedules
# operationId: getNetworkCameraSchedules
export def "networks-camera-schedules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/camera/schedules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a snapshot of what the camera sees at the specified time and return a link to that image.
#
# POST /networks/{networkId}/cameras/{serial}/snapshot
# operationId: generateNetworkCameraSnapshot
export def "networks-cameras-snapshot generateNetworkCameraSnapshot" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/cameras/($serial)/snapshot")
  let body = {fullframe: $fullframe, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns video link to the specified camera
#
# GET /networks/{networkId}/cameras/{serial}/videoLink
# operationId: getNetworkCameraVideoLink
export def "networks-cameras-video-link get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/cameras/($serial)/videoLink" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the cellular firewall rules for an MX network
#
# GET /networks/{networkId}/cellularFirewallRules
# operationId: getNetworkCellularFirewallRules
export def "networks-cellular-firewall-rules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/cellularFirewallRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the cellular firewall rules of an MX network
#
# PUT /networks/{networkId}/cellularFirewallRules
# operationId: updateNetworkCellularFirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
export def "networks-cellular-firewall-rules updateNetworkCellularFirewallRules" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/cellularFirewallRules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the clients that have used this network in the timespan
#
# GET /networks/{networkId}/clients
# operationId: getNetworkClients
export def "networks-clients list" [
  networkId: string
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 10.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> record<description: string, firstSeen: int, groupPolicy8021x: string, id: string, ip: string, ip6: string, ip6Local: string, lastSeen: int, mac: string, manufacturer: string, notes: string, os: string, recentDeviceMac: string, recentDeviceName: string, recentDeviceSerial: string, smInstalled: bool, ssid: string, status: string, switchport: string, usage: record<recv: float, sent: float>, user: string, vlan: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated connectivity info for this network, grouped by clients
#
# GET /networks/{networkId}/clients/connectionStats
# operationId: getNetworkClientsConnectionStats
export def "networks-clients-connection-stats list" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/clients/connectionStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for this network, grouped by clients
#
# GET /networks/{networkId}/clients/latencyStats
# operationId: getNetworkClientsLatencyStats
export def "networks-clients-latency-stats list" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/clients/latencyStats" $qp)
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
export def "networks-clients-provision provisionNetworkClients" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  devicePolicy: string@devicePolicy-completer # The policy to apply to the specified client. Can be 'Group policy', 'Whitelisted', 'Allowed', 'Blocked', 'Per connection' or 'Normal'. Required.
  --groupPolicyId: string # The ID of the desired group policy to apply to the client. Required if 'devicePolicy' is set to "Group policy". Otherwise this is ignored.
  mac: string # The MAC address of the client. Required.
  --name: string # The display name for the client. Optional. Limited to 255 bytes.
  --policiesBySecurityAppliance: record # An object, describing what the policy-connection association is for the security appliance. (Only relevant if the security appliance is actually within the network) — shape: {devicePolicy?: "Blocked"|"Normal"|"Whitelisted"}
  --policiesBySsid: record # An object, describing the policy-connection associations for each active SSID within the network. Keys should be the number of enabled SSIDs, mapping to an object describing the client's policy — shape: {0?: record, 1?: record, 2?: record, 3?: record, 4?: record, 5?: record, 6?: record, 7?: record, 8?: record, 9?: record, 10?: record, 11?: record, 12?: record, 13?: record, 14?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/clients/provision")
  let body = {devicePolicy: $devicePolicy, groupPolicyId: $groupPolicyId, mac: $mac, name: $name, policiesBySecurityAppliance: $policiesBySecurityAppliance, policiesBySsid: $policiesBySsid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the client associated with the given identifier
#
# GET /networks/{networkId}/clients/{clientId}
# operationId: getNetworkClient
export def "networks-clients get" [
  networkId: string
  clientId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated connectivity info for a given client on this network
#
# GET /networks/{networkId}/clients/{clientId}/connectionStats
# operationId: getNetworkClientConnectionStats
export def "networks-clients-connection-stats get" [
  networkId: string
  clientId: string
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
  --apTag: string # Filter results by AP Tag
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/connectionStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the events associated with this client
#
# GET /networks/{networkId}/clients/{clientId}/events
# operationId: getNetworkClientEvents
export def "networks-clients-events get" [
  networkId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 100. Default is 100.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the latency history for a client
#
# GET /networks/{networkId}/clients/{clientId}/latencyHistory
# operationId: getNetworkClientLatencyHistory
export def "networks-clients-latency-history get" [
  networkId: string
  clientId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/latencyHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for a given client on this network
#
# GET /networks/{networkId}/clients/{clientId}/latencyStats
# operationId: getNetworkClientLatencyStats
export def "networks-clients-latency-stats get" [
  networkId: string
  clientId: string
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
  --apTag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/latencyStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the policy assigned to a client on the network
#
# GET /networks/{networkId}/clients/{clientId}/policy
# operationId: getNetworkClientPolicy
export def "networks-clients-policy get" [
  networkId: string
  clientId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/policy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the policy assigned to a client on the network
#
# PUT /networks/{networkId}/clients/{clientId}/policy
# operationId: updateNetworkClientPolicy
export def "networks-clients-policy updateNetworkClientPolicy" [
  networkId: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  devicePolicy: string # The policy to assign. Can be 'Whitelisted', 'Blocked', 'Normal' or 'Group policy'. Required.
  --groupPolicyId: string # [optional] If 'devicePolicy' is set to 'Group policy' this param is used to specify the group policy ID.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/policy")
  let body = {devicePolicy: $devicePolicy, groupPolicyId: $groupPolicyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the splash authorization for a client, for each SSID they've associated with through splash
#
# GET /networks/{networkId}/clients/{clientId}/splashAuthorizationStatus
# operationId: getNetworkClientSplashAuthorizationStatus
export def "networks-clients-splash-authorization-status get" [
  networkId: string
  clientId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/splashAuthorizationStatus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a client's splash authorization
#
# PUT /networks/{networkId}/clients/{clientId}/splashAuthorizationStatus
# operationId: updateNetworkClientSplashAuthorizationStatus
# --ssids shape: {0?: record, 1?: record, 2?: record, 3?: record, 4?: record, 5?: record, 6?: record, 7?: record, 8?: record, 9?: record, 10?: record, 11?: record, 12?: record, 13?: record, 14?: record}
export def "networks-clients-splash-authorization-status updateNetworkClientSplashAuthorizationStatus" [
  networkId: string
  clientId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/splashAuthorizationStatus")
  let body = {ssids: $ssids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the client's daily usage history
#
# GET /networks/{networkId}/clients/{clientId}/usageHistory
# operationId: getNetworkClientUsageHistory
export def "networks-clients-usage-history get" [
  networkId: string
  clientId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/clients/($clientId)/usageHistory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated connectivity info for this network
#
# GET /networks/{networkId}/connectionStats
# operationId: getNetworkConnectionStats
export def "networks-connection-stats get" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/connectionStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the content filtering settings for an MX network
#
# GET /networks/{networkId}/contentFiltering
# operationId: getNetworkContentFiltering
export def "networks-content-filtering get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/contentFiltering")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the content filtering settings for an MX network
#
# PUT /networks/{networkId}/contentFiltering
# operationId: updateNetworkContentFiltering
export def "networks-content-filtering updateNetworkContentFiltering" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedUrlPatterns: list # A list of URL patterns that are allowed
  --blockedUrlCategories: list # A list of URL categories to block
  --blockedUrlPatterns: list # A list of URL patterns that are blocked
  --urlCategoryListSize: string@urlCategoryListSize-completer # URL category list size which is either 'topSites' or 'fullList'
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/contentFiltering")
  let body = {allowedUrlPatterns: $allowedUrlPatterns, blockedUrlCategories: $blockedUrlCategories, blockedUrlPatterns: $blockedUrlPatterns, urlCategoryListSize: $urlCategoryListSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all available content filtering categories for an MX network
#
# GET /networks/{networkId}/contentFiltering/categories
# operationId: getNetworkContentFilteringCategories
export def "networks-content-filtering-categories get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/contentFiltering/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the devices in a network
#
# GET /networks/{networkId}/devices
# operationId: getNetworkDevices
export def "networks-devices list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/devices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Claim devices into a network. (Note: for recently claimed devices, it may take a few minutes for API requests against that device to succeed)
#
# POST /networks/{networkId}/devices/claim
# operationId: claimNetworkDevices
export def "networks-devices-claim claimNetworkDevices" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --serial: string # [DEPRECATED] The serial of a device to claim
  --serials: list # A list of serials of devices to claim
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/devices/claim")
  let body = {serial: $serial, serials: $serials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Aggregated connectivity info for this network, grouped by node
#
# GET /networks/{networkId}/devices/connectionStats
# operationId: getNetworkDevicesConnectionStats
export def "networks-devices-connection-stats list" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/devices/connectionStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for this network, grouped by node
#
# GET /networks/{networkId}/devices/latencyStats
# operationId: getNetworkDevicesLatencyStats
export def "networks-devices-latency-stats list" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/devices/latencyStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a single device
#
# GET /networks/{networkId}/devices/{serial}
# operationId: getNetworkDevice
export def "networks-devices get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the attributes of a device
#
# PUT /networks/{networkId}/devices/{serial}
# operationId: updateNetworkDevice
export def "networks-devices updateNetworkDevice" [
  networkId: string
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
  --floorPlanId: string # The floor plan to associate to this device. null disassociates the device from the floorplan.
  --lat: float # The latitude of a device (format: float)
  --lng: float # The longitude of a device (format: float)
  --moveMapMarker: oneof<nothing, bool> # Whether or not to set the latitude and longitude of a device based on the new address. Only applies when lat and lng are not specified.
  --name: string # The name of a device
  --notes: string # The notes for the device. String. Limited to 255 characters.
  --switchProfileId: string # The ID of a switch profile to bind to the device (for available switch profiles, see the 'Switch Profiles' endpoint). Use null to unbind the switch device from the current profile. For a device to be bindable to a switch profile, it must (1) be a switch, and (2) belong to a network that is bound to a configuration template.
  --tags: string # The tags of a device
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)")
  let body = {address: $address, floorPlanId: $floorPlanId, lat: $lat, lng: $lng, moveMapMarker: $moveMapMarker, name: $name, notes: $notes, switchProfileId: $switchProfileId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Aggregated connectivity info for a given AP on this network
#
# GET /networks/{networkId}/devices/{serial}/connectionStats
# operationId: getNetworkDeviceConnectionStats
export def "networks-devices-connection-stats get" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)/connectionStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for a given AP on this network
#
# GET /networks/{networkId}/devices/{serial}/latencyStats
# operationId: getNetworkDeviceLatencyStats
export def "networks-devices-latency-stats get" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)/latencyStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the uplink loss percentage and latency in milliseconds for a wired network device.
#
# GET /networks/{networkId}/devices/{serial}/lossAndLatencyHistory
# operationId: getNetworkDeviceLossAndLatencyHistory
export def "networks-devices-loss-and-latency-history get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)/lossAndLatencyHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the performance score for a single MX
#
# GET /networks/{networkId}/devices/{serial}/performance
# operationId: getNetworkDevicePerformance
export def "networks-devices-performance get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)/performance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reboot a device
#
# POST /networks/{networkId}/devices/{serial}/reboot
# operationId: rebootNetworkDevice
export def "networks-devices-reboot rebootNetworkDevice" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)/reboot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a single device
#
# POST /networks/{networkId}/devices/{serial}/remove
# operationId: removeNetworkDevice
export def "networks-devices-remove removeNetworkDevice" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)/remove")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the uplink information for a device.
#
# GET /networks/{networkId}/devices/{serial}/uplink
# operationId: getNetworkDeviceUplink
export def "networks-devices-uplink get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)/uplink")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the SSID statuses of an access point
#
# GET /networks/{networkId}/devices/{serial}/wireless/status
# operationId: getNetworkDeviceWirelessStatus
export def "networks-devices-wireless-status get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/devices/($serial)/wireless/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the events for the network
#
# GET /networks/{networkId}/events
# operationId: getNetworkEvents
export def "networks-events get" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --productType: string # The product type to fetch events for. This parameter is required for networks with multiple device types. Valid types are wireless, appliance, switch, systemsManager, camera, cellularGateway, and environmental
  --includedEventTypes: list # A list of event types. The returned events will be filtered to only include events with these types.
  --excludedEventTypes: list # A list of event types. The returned events will be filtered to exclude events with these types.
  --deviceMac: string # The MAC address of the Meraki device which the list of events will be filtered with
  --deviceSerial: string # The serial of the Meraki device which the list of events will be filtered with
  --deviceName: string # The name of the Meraki device which the list of events will be filtered with
  --clientIp: string # The IP of the client which the list of events will be filtered with. Only supported for track-by-IP networks.
  --clientMac: string # The MAC address of the client which the list of events will be filtered with. Only supported for track-by-MAC networks.
  --clientName: string # The name, or partial name, of the client which the list of events will be filtered with
  --smDeviceMac: string # The MAC address of the Systems Manager device which the list of events will be filtered with
  --smDeviceName: string # The name of the Systems Manager device which the list of events will be filtered with
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 10.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productType" $productType "scalar") (serialize-qp "includedEventTypes" $includedEventTypes "csv") (serialize-qp "excludedEventTypes" $excludedEventTypes "csv") (serialize-qp "deviceMac" $deviceMac "scalar") (serialize-qp "deviceSerial" $deviceSerial "scalar") (serialize-qp "deviceName" $deviceName "scalar") (serialize-qp "clientIp" $clientIp "scalar") (serialize-qp "clientMac" $clientMac "scalar") (serialize-qp "clientName" $clientName "scalar") (serialize-qp "smDeviceMac" $smDeviceMac "scalar") (serialize-qp "smDeviceName" $smDeviceName "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the event type to human-readable description
#
# GET /networks/{networkId}/events/eventTypes
# operationId: getNetworkEventsEventTypes
export def "networks-events-event-types get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/events/eventTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all failed client connection events on this network in a given time range
#
# GET /networks/{networkId}/failedConnections
# operationId: getNetworkFailedConnections
export def "networks-failed-connections get" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
  --serial: string # Filter by AP
  --clientId: string # Filter by client MAC
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "clientId" $clientId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/failedConnections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the appliance services and their accessibility rules
#
# GET /networks/{networkId}/firewalledServices
# operationId: getNetworkFirewalledServices
export def "networks-firewalled-services list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/firewalledServices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the accessibility settings of the given service ('ICMP', 'web', or 'SNMP')
#
# GET /networks/{networkId}/firewalledServices/{service}
# operationId: getNetworkFirewalledService
export def "networks-firewalled-services get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/firewalledServices/($service)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the accessibility settings for the given service ('ICMP', 'web', or 'SNMP')
#
# PUT /networks/{networkId}/firewalledServices/{service}
# operationId: updateNetworkFirewalledService
export def "networks-firewalled-services updateNetworkFirewalledService" [
  networkId: string
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
  --allowedIps: list # An array of whitelisted IPs that can access the service. This field is required if "access" is set to "restricted". Otherwise this field is ignored
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/firewalledServices/($service)")
  let body = {access: $access, allowedIps: $allowedIps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the floor plans that belong to your network
#
# GET /networks/{networkId}/floorPlans
# operationId: getNetworkFloorPlans
export def "networks-floor-plans list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/floorPlans")
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
export def "networks-floor-plans createNetworkFloorPlan" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bottomLeftCorner: record # The longitude and latitude of the bottom left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --bottomRightCorner: record # The longitude and latitude of the bottom right corner of your floor plan. — shape: {lat?: float, lng?: float}
  --center: record # The longitude and latitude of the center of your floor plan. The 'center' or two adjacent corners (e.g. 'topLeftCorner' and 'bottomLeftCorner') must be specified. If 'center' is specified, the floor plan is placed over that point with no rotation. If two adjacent corners are specified, the floor plan is rotated to line up with the two specified points. The aspect ratio of the floor plan's image is preserved regardless of which corners/center are specified. (This means if that more than two corners are specified, only two corners may be used to preserve the floor plan's aspect ratio.). No two points can have the same latitude, longitude pair. — shape: {lat?: float, lng?: float}
  imageContents: string # The file contents (a base 64 encoded string) of your image. Supported formats are PNG, GIF, and JPG. Note that all images are saved as PNG files, regardless of the format they are uploaded in. (format: byte)
  name: string # The name of your floor plan.
  --topLeftCorner: record # The longitude and latitude of the top left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --topRightCorner: record # The longitude and latitude of the top right corner of your floor plan. — shape: {lat?: float, lng?: float}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/floorPlans")
  let body = {bottomLeftCorner: $bottomLeftCorner, bottomRightCorner: $bottomRightCorner, center: $center, imageContents: $imageContents, name: $name, topLeftCorner: $topLeftCorner, topRightCorner: $topRightCorner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Destroy a floor plan
#
# DELETE /networks/{networkId}/floorPlans/{floorPlanId}
# operationId: deleteNetworkFloorPlan
export def "networks-floor-plans delete" [
  networkId: string
  floorPlanId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/floorPlans/($floorPlanId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a floor plan by ID
#
# GET /networks/{networkId}/floorPlans/{floorPlanId}
# operationId: getNetworkFloorPlan
export def "networks-floor-plans get" [
  networkId: string
  floorPlanId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/floorPlans/($floorPlanId)")
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
export def "networks-floor-plans updateNetworkFloorPlan" [
  networkId: string
  floorPlanId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bottomLeftCorner: record # The longitude and latitude of the bottom left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --bottomRightCorner: record # The longitude and latitude of the bottom right corner of your floor plan. — shape: {lat?: float, lng?: float}
  --center: record # The longitude and latitude of the center of your floor plan. If you want to change the geolocation data of your floor plan, either the 'center' or two adjacent corners (e.g. 'topLeftCorner' and 'bottomLeftCorner') must be specified. If 'center' is specified, the floor plan is placed over that point with no rotation. If two adjacent corners are specified, the floor plan is rotated to line up with the two specified points. The aspect ratio of the floor plan's image is preserved regardless of which corners/center are specified. (This means if that more than two corners are specified, only two corners may be used to preserve the floor plan's aspect ratio.). No two points can have the same latitude, longitude pair. — shape: {lat?: float, lng?: float}
  --imageContents: string # The file contents (a base 64 encoded string) of your new image. Supported formats are PNG, GIF, and JPG. Note that all images are saved as PNG files, regardless of the format they are uploaded in. If you upload a new image, and you do NOT specify any new geolocation fields ('center, 'topLeftCorner', etc), the floor plan will be recentered with no rotation in order to maintain the aspect ratio of your new image. (format: byte)
  --name: string # The name of your floor plan.
  --topLeftCorner: record # The longitude and latitude of the top left corner of your floor plan. — shape: {lat?: float, lng?: float}
  --topRightCorner: record # The longitude and latitude of the top right corner of your floor plan. — shape: {lat?: float, lng?: float}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/floorPlans/($floorPlanId)")
  let body = {bottomLeftCorner: $bottomLeftCorner, bottomRightCorner: $bottomRightCorner, center: $center, imageContents: $imageContents, name: $name, topLeftCorner: $topLeftCorner, topRightCorner: $topRightCorner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the L3 firewall rules for an MX network
#
# GET /networks/{networkId}/l3FirewallRules
# operationId: getNetworkL3FirewallRules
export def "networks-l3-firewall-rules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/l3FirewallRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the L3 firewall rules of an MX network
#
# PUT /networks/{networkId}/l3FirewallRules
# operationId: updateNetworkL3FirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
export def "networks-l3-firewall-rules updateNetworkL3FirewallRules" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslogDefaultRule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/l3FirewallRules")
  let body = {rules: $rules, syslogDefaultRule: $syslogDefaultRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the MX L7 firewall rules for an MX network
#
# GET /networks/{networkId}/l7FirewallRules
# operationId: getNetworkL7FirewallRules
export def "networks-l7-firewall-rules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/l7FirewallRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the MX L7 firewall rules for an MX network
#
# PUT /networks/{networkId}/l7FirewallRules
# operationId: updateNetworkL7FirewallRules
# --rules item shape: {policy?: "deny", type?: "application"|"applicationCategory"|"host"|"ipRange"|"port", value?: string}
export def "networks-l7-firewall-rules updateNetworkL7FirewallRules" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/l7FirewallRules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the L7 firewall application categories and their associated applications for an MX network
#
# GET /networks/{networkId}/l7FirewallRules/applicationCategories
# operationId: getNetworkL7FirewallRulesApplicationCategories
export def "networks-l7-firewall-rules-application-categories get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/l7FirewallRules/applicationCategories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aggregated latency info for this network
#
# GET /networks/{networkId}/latencyStats
# operationId: getNetworkLatencyStats
export def "networks-latency-stats get" [
  networkId: string
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
  --apTag: string # Filter results by AP Tag
  --fields: string # Partial selection: If present, this call will return only the selected fields of ["rawDistribution", "avg"]. All fields will be returned by default. Selected fields must be entered as a comma separated string.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "band" $band "scalar") (serialize-qp "ssid" $ssid "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "apTag" $apTag "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/latencyStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the splash or RADIUS users configured under Meraki Authentication for a network
#
# GET /networks/{networkId}/merakiAuthUsers
# operationId: getNetworkMerakiAuthUsers
export def "networks-meraki-auth-users list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/merakiAuthUsers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the Meraki Auth splash or RADIUS user
#
# GET /networks/{networkId}/merakiAuthUsers/{merakiAuthUserId}
# operationId: getNetworkMerakiAuthUser
export def "networks-meraki-auth-users get" [
  networkId: string
  merakiAuthUserId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/merakiAuthUsers/($merakiAuthUserId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the 1:Many NAT mapping rules for an MX network
#
# GET /networks/{networkId}/oneToManyNatRules
# operationId: getNetworkOneToManyNatRules
export def "networks-one-to-many-nat-rules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/oneToManyNatRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the 1:Many NAT mapping rules for an MX network
#
# PUT /networks/{networkId}/oneToManyNatRules
# operationId: updateNetworkOneToManyNatRules
# --rules item shape: {portRules: list, publicIp: string, uplink: "internet1"|"internet2"}
export def "networks-one-to-many-nat-rules updateNetworkOneToManyNatRules" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/oneToManyNatRules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the 1:1 NAT mapping rules for an MX network
#
# GET /networks/{networkId}/oneToOneNatRules
# operationId: getNetworkOneToOneNatRules
export def "networks-one-to-one-nat-rules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/oneToOneNatRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the 1:1 NAT mapping rules for an MX network
#
# PUT /networks/{networkId}/oneToOneNatRules
# operationId: updateNetworkOneToOneNatRules
# --rules item shape: {allowedInbound?: list, lanIp: string, name?: string, publicIp?: string, uplink?: "internet1"|"internet2"}
export def "networks-one-to-one-nat-rules updateNetworkOneToOneNatRules" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/oneToOneNatRules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the keys required to access Personally Identifiable Information (PII) for a given identifier
#
# GET /networks/{networkId}/pii/piiKeys
# operationId: getNetworkPiiPiiKeys
export def "networks-pii-pii-keys get" [
  networkId: string
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
  --bluetoothMac: string # The MAC of a Bluetooth client
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "mac" $mac "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "imei" $imei "scalar") (serialize-qp "bluetoothMac" $bluetoothMac "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/pii/piiKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the PII requests for this network or organization
#
# GET /networks/{networkId}/pii/requests
# operationId: getNetworkPiiRequests
export def "networks-pii-requests list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/pii/requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a new delete or restrict processing PII request
#
# POST /networks/{networkId}/pii/requests
# operationId: createNetworkPiiRequest
export def "networks-pii-requests createNetworkPiiRequest" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasets: list # The datasets related to the provided key that should be deleted. Only applies to "delete" requests. The value "all" will be expanded to all datasets applicable to this type. The datasets by applicable to each type are: mac (usage, events, traffic), email (users, loginAttempts), username (users, loginAttempts), bluetoothMac (client, connectivity), smDeviceId (device), smUserId (user)
  --email: string # The email of a network user account. Only applies to "delete" requests.
  --mac: string # The MAC of a network client device. Applies to both "restrict processing" and "delete" requests.
  --smDeviceId: string # The sm_device_id of a Systems Manager device. The only way to "restrict processing" or "delete" a Systems Manager device. Must include "device" in the dataset for a "delete" request to destroy the device.
  --smUserId: string # The sm_user_id of a Systems Manager user. The only way to "restrict processing" or "delete" a Systems Manager user. Must include "user" in the dataset for a "delete" request to destroy the user.
  --type: string@type-completer # One of "delete" or "restrict processing"
  --username: string # The username of a network log in. Only applies to "delete" requests.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/pii/requests")
  let body = {datasets: $datasets, email: $email, mac: $mac, smDeviceId: $smDeviceId, smUserId: $smUserId, type: $type, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a restrict processing PII request
#
# DELETE /networks/{networkId}/pii/requests/{requestId}
# operationId: deleteNetworkPiiRequest
export def "networks-pii-requests delete" [
  networkId: string
  requestId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/pii/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a PII request
#
# GET /networks/{networkId}/pii/requests/{requestId}
# operationId: getNetworkPiiRequest
export def "networks-pii-requests get" [
  networkId: string
  requestId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/pii/requests/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Given a piece of Personally Identifiable Information (PII), return the Systems Manager device ID(s) associated with that identifier
#
# GET /networks/{networkId}/pii/smDevicesForKey
# operationId: getNetworkPiiSmDevicesForKey
export def "networks-pii-sm-devices-for-key get" [
  networkId: string
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
  --bluetoothMac: string # The MAC of a Bluetooth client
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "mac" $mac "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "imei" $imei "scalar") (serialize-qp "bluetoothMac" $bluetoothMac "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/pii/smDevicesForKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Given a piece of Personally Identifiable Information (PII), return the Systems Manager owner ID(s) associated with that identifier
#
# GET /networks/{networkId}/pii/smOwnersForKey
# operationId: getNetworkPiiSmOwnersForKey
export def "networks-pii-sm-owners-for-key get" [
  networkId: string
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
  --bluetoothMac: string # The MAC of a Bluetooth client
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "mac" $mac "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "imei" $imei "scalar") (serialize-qp "bluetoothMac" $bluetoothMac "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/pii/smOwnersForKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the port forwarding rules for an MX network
#
# GET /networks/{networkId}/portForwardingRules
# operationId: getNetworkPortForwardingRules
export def "networks-port-forwarding-rules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/portForwardingRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the port forwarding rules for an MX network
#
# PUT /networks/{networkId}/portForwardingRules
# operationId: updateNetworkPortForwardingRules
# --rules item shape: {allowedIps: list, lanIp: string, localPort: string, name?: string, protocol: "tcp"|"udp", publicPort: string, uplink?: "both"|"internet1"|"internet2"}
export def "networks-port-forwarding-rules updateNetworkPortForwardingRules" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rules: list # An array of port forwarding params — item shape: {allowedIps: list, lanIp: string, localPort: string, name?: string, protocol: "tcp"|"udp", publicPort: string, uplink?: "both"|"internet1"|"internet2"}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/portForwardingRules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all supported intrusion settings for an MX network
#
# GET /networks/{networkId}/security/intrusionSettings
# operationId: getNetworkSecurityIntrusionSettings
export def "networks-security-intrusion-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/security/intrusionSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the supported intrusion settings for an MX network
#
# PUT /networks/{networkId}/security/intrusionSettings
# operationId: updateNetworkSecurityIntrusionSettings
# --protectedNetworks shape: {excludedCidr?: list, includedCidr?: list, useDefault?: bool}
export def "networks-security-intrusion-settings updateNetworkSecurityIntrusionSettings" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --idsRulesets: string@idsRulesets-completer # Set the detection ruleset 'connectivity'/'balanced'/'security' (optional - omitting will leave current config unchanged). Default value is 'balanced' if none currently saved
  --mode: string@mode-completer # Set mode to 'disabled'/'detection'/'prevention' (optional - omitting will leave current config unchanged)
  --protectedNetworks: record # Set the included/excluded networks from the intrusion engine (optional - omitting will leave current config unchanged). This is available only in 'passthrough' mode — shape: {excludedCidr?: list, includedCidr?: list, useDefault?: bool}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/security/intrusionSettings")
  let body = {idsRulesets: $idsRulesets, mode: $mode, protectedNetworks: $protectedNetworks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all supported malware settings for an MX network
#
# GET /networks/{networkId}/security/malwareSettings
# operationId: getNetworkSecurityMalwareSettings
export def "networks-security-malware-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/security/malwareSettings")
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
export def "networks-security-malware-settings updateNetworkSecurityMalwareSettings" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedFiles: list # The sha256 digests of files that should be permitted by the malware detection engine. If omitted, the current config will remain unchanged. This is available only if your network supports AMP allow listing — item shape: {comment: string, sha256: string}
  --allowedUrls: list # The urls that should be permitted by the malware detection engine. If omitted, the current config will remain unchanged. This is available only if your network supports AMP allow listing — item shape: {comment: string, url: string}
  mode: string@mode-completer-1 # Set mode to 'enabled' to enable malware prevention, otherwise 'disabled'
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/security/malwareSettings")
  let body = {allowedFiles: $allowedFiles, allowedUrls: $allowedUrls, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the security events (intrusion detection only) for a network
#
# GET /networks/{networkId}/securityEvents
# operationId: getNetworkSecurityEvents
export def "networks-security-events get" [
  networkId: string
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 100.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/securityEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the site-to-site VPN settings of a network
#
# GET /networks/{networkId}/siteToSiteVpn
# operationId: getNetworkSiteToSiteVpn
export def "networks-site-to-site-vpn get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/siteToSiteVpn")
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
export def "networks-site-to-site-vpn updateNetworkSiteToSiteVpn" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/siteToSiteVpn")
  let body = {hubs: $hubs, mode: $mode, subnets: $subnets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bypass activation lock attempt
#
# POST /networks/{networkId}/sm/bypassActivationLockAttempts
# operationId: createNetworkSmBypassActivationLockAttempt
export def "networks-sm-bypass-activation-lock-attempts createNetworkSmBypassActivationLockAttempt" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list # The ids of the devices to attempt activation lock bypass.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/sm/bypassActivationLockAttempts")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bypass activation lock attempt status
#
# GET /networks/{networkId}/sm/bypassActivationLockAttempts/{attemptId}
# operationId: getNetworkSmBypassActivationLockAttempt
export def "networks-sm-bypass-activation-lock-attempts get" [
  networkId: string
  attemptId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/bypassActivationLockAttempts/($attemptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the fields of a device
#
# PUT /networks/{networkId}/sm/device/fields
# operationId: updateNetworkSmDeviceFields
# --deviceFields shape: {name?: string, notes?: string}
export def "networks-sm-device-fields updateNetworkSmDeviceFields" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  deviceFields: record # The new fields of the device. Each field of this object is optional. — shape: {name?: string, notes?: string}
  --id: string # The id of the device to be modified.
  --serial: string # The serial of the device to be modified.
  --wifiMac: string # The wifiMac of the device to be modified.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/sm/device/fields")
  let body = {deviceFields: $deviceFields, id: $id, serial: $serial, wifiMac: $wifiMac} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Wipe a device
#
# PUT /networks/{networkId}/sm/device/wipe
# operationId: wipeNetworkSmDevice
export def "networks-sm-device-wipe wipeNetworkSmDevice" [
  networkId: string
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
  --wifiMac: string # The wifiMac of the device to be wiped.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/sm/device/wipe")
  let body = {id: $id, pin: $pin, serial: $serial, wifiMac: $wifiMac} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh the details of a device
#
# POST /networks/{networkId}/sm/device/{deviceId}/refreshDetails
# operationId: refreshNetworkSmDeviceDetails
export def "networks-sm-device-refresh-details refreshNetworkSmDeviceDetails" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/device/($deviceId)/refreshDetails")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the devices enrolled in an SM network with various specified fields and filters
#
# GET /networks/{networkId}/sm/devices
# operationId: getNetworkSmDevices
export def "networks-sm-devices get" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Additional fields that will be displayed for each device. Multiple fields can be passed in as comma separated values.     The default fields are: id, name, tags, ssid, wifiMac, osName, systemModel, uuid, and serialNumber. The additional fields are: ip,     systemType, availableDeviceCapacity, kioskAppName, biosVersion, lastConnected, missingAppsCount, userSuppliedAddress, location, lastUser,     ownerEmail, ownerUsername, publicIp, phoneNumber, diskInfoJson, deviceCapacity, isManaged, hadMdm, isSupervised, meid, imei, iccid,     simCarrierNetwork, cellularDataUsed, isHotspotEnabled, createdAt, batteryEstCharge, quarantined, avName, avRunning, asName, fwName,     isRooted, loginRequired, screenLockEnabled, screenLockDelay, autoLoginDisabled, autoTags, hasMdm, hasDesktopAgent, diskEncryptionEnabled,     hardwareEncryptionCaps, passCodeLock, usesHardwareKeystore, and androidSecurityPatchVersion.
  --wifiMacs: string # Filter devices by wifi mac(s). Multiple wifi macs can be passed in as comma separated values.
  --serials: string # Filter devices by serial(s). Multiple serials can be passed in as comma separated values.
  --ids: string # Filter devices by id(s). Multiple ids can be passed in as comma separated values.
  --scope: string # Specify a scope (one of all, none, withAny, withAll, withoutAny, or withoutAll) and a set of tags as comma separated values.
  --batchSize: int # Number of devices to return, 1000 is the default as well as the max.
  --batchToken: string # If the network has more devices than the batch size, a batch token will be returned     as a part of the device list. To see the remainder of the devices, pass in the batchToken as a parameter in the next request.     Requests made with the batchToken do not require additional parameters as the batchToken includes the parameters passed in     with the original request. Additional parameters passed in with the batchToken will be ignored.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "wifiMacs" $wifiMacs "scalar") (serialize-qp "serials" $serials "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "batchSize" $batchSize "scalar") (serialize-qp "batchToken" $batchToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/sm/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force check-in a set of devices
#
# PUT /networks/{networkId}/sm/devices/checkin
# operationId: checkinNetworkSmDevices
export def "networks-sm-devices-checkin checkinNetworkSmDevices" [
  networkId: string
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
  --wifiMacs: string # The wifiMacs of the devices to be checked-in.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/sm/devices/checkin")
  let body = {ids: $ids, scope: $scope, serials: $serials, wifiMacs: $wifiMacs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add, delete, or update the tags of a set of devices
#
# PUT /networks/{networkId}/sm/devices/tags
# operationId: updateNetworkSmDevicesTags
export def "networks-sm-devices-tags updateNetworkSmDevicesTags" [
  networkId: string
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
  updateAction: string # One of add, delete, or update. Only devices that have been modified will be returned.
  --wifiMacs: string # The wifiMacs of the devices to be modified.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/sm/devices/tags")
  let body = {ids: $ids, scope: $scope, serials: $serials, tags: $tags, updateAction: $updateAction, wifiMacs: $wifiMacs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unenroll a device
#
# POST /networks/{networkId}/sm/devices/{deviceId}/unenroll
# operationId: unenrollNetworkSmDevice
export def "networks-sm-devices-unenroll unenrollNetworkSmDevice" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/devices/($deviceId)/unenroll")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the profiles in the network
#
# GET /networks/{networkId}/sm/profiles
# operationId: getNetworkSmProfiles
export def "networks-sm-profiles get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/profiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the target groups in this network
#
# GET /networks/{networkId}/sm/targetGroups
# operationId: getNetworkSmTargetGroups
export def "networks-sm-target-groups list" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withDetails: oneof<nothing, bool> # Boolean indicating if the the ids of the devices or users scoped by the target group should be included in the response
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withDetails" $withDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/sm/targetGroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a target group
#
# POST /networks/{networkId}/sm/targetGroups
# operationId: createNetworkSmTargetGroup
export def "networks-sm-target-groups createNetworkSmTargetGroup" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/targetGroups")
  let body = {name: $name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a target group from a network
#
# DELETE /networks/{networkId}/sm/targetGroups/{targetGroupId}
# operationId: deleteNetworkSmTargetGroup
export def "networks-sm-target-groups delete" [
  networkId: string
  targetGroupId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/targetGroups/($targetGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a target group
#
# GET /networks/{networkId}/sm/targetGroups/{targetGroupId}
# operationId: getNetworkSmTargetGroup
export def "networks-sm-target-groups get" [
  networkId: string
  targetGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withDetails: oneof<nothing, bool> # Boolean indicating if the the ids of the devices or users scoped by the target group should be included in the response
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withDetails" $withDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/sm/targetGroups/($targetGroupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a target group
#
# PUT /networks/{networkId}/sm/targetGroups/{targetGroupId}
# operationId: updateNetworkSmTargetGroup
export def "networks-sm-target-groups updateNetworkSmTargetGroup" [
  networkId: string
  targetGroupId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/targetGroups/($targetGroupId)")
  let body = {name: $name, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the profiles associated with a user
#
# GET /networks/{networkId}/sm/user/{userId}/deviceProfiles
# operationId: getNetworkSmUserDeviceProfiles
export def "networks-sm-user-device-profiles get" [
  networkId: string
  userId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/user/($userId)/deviceProfiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of softwares associated with a user
#
# GET /networks/{networkId}/sm/user/{userId}/softwares
# operationId: getNetworkSmUserSoftwares
export def "networks-sm-user-softwares get" [
  networkId: string
  userId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/user/($userId)/softwares")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the owners in an SM network with various specified fields and filters
#
# GET /networks/{networkId}/sm/users
# operationId: getNetworkSmUsers
export def "networks-sm-users get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the client's daily cellular data usage history
#
# GET /networks/{networkId}/sm/{deviceId}/cellularUsageHistory
# operationId: getNetworkSmCellularUsageHistory
export def "networks-sm-cellular-usage-history get" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/($deviceId)/cellularUsageHistory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the certs on a device
#
# GET /networks/{networkId}/sm/{deviceId}/certs
# operationId: getNetworkSmCerts
export def "networks-sm-certs get" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/($deviceId)/certs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the profiles associated with a device
#
# GET /networks/{networkId}/sm/{deviceId}/deviceProfiles
# operationId: getNetworkSmDeviceProfiles
export def "networks-sm-device-profiles get" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/($deviceId)/deviceProfiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the network adapters of a device
#
# GET /networks/{networkId}/sm/{deviceId}/networkAdapters
# operationId: getNetworkSmNetworkAdapters
export def "networks-sm-network-adapters get" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/($deviceId)/networkAdapters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the restrictions on a device
#
# GET /networks/{networkId}/sm/{deviceId}/restrictions
# operationId: getNetworkSmRestrictions
export def "networks-sm-restrictions get" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/($deviceId)/restrictions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the security centers on a device
#
# GET /networks/{networkId}/sm/{deviceId}/securityCenters
# operationId: getNetworkSmSecurityCenters
export def "networks-sm-security-centers get" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/($deviceId)/securityCenters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of softwares associated with a device
#
# GET /networks/{networkId}/sm/{deviceId}/softwares
# operationId: getNetworkSmSoftwares
export def "networks-sm-softwares get" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/($deviceId)/softwares")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the saved SSID names on a device
#
# GET /networks/{networkId}/sm/{deviceId}/wlanLists
# operationId: getNetworkSmWlanLists
export def "networks-sm-wlan-lists get" [
  networkId: string
  deviceId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/sm/($deviceId)/wlanLists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the SNMP settings for a network
#
# GET /networks/{networkId}/snmpSettings
# operationId: getNetworkSnmpSettings
export def "networks-snmp-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/snmpSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the splash login attempts for a network
#
# GET /networks/{networkId}/splashLoginAttempts
# operationId: getNetworkSplashLoginAttempts
export def "networks-splash-login-attempts get" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ssidNumber: int@ssidNumber-completer # Only return the login attempts for the specified SSID
  --loginIdentifier: string # The username, email, or phone number used during login
  --timespan: int # The timespan, in seconds, for the login attempts. The period will be from [timespan] seconds ago until now. The maximum timespan is 3 months
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ssidNumber" $ssidNumber "scalar") (serialize-qp "loginIdentifier" $loginIdentifier "scalar") (serialize-qp "timespan" $timespan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/splashLoginAttempts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Split a combined network into individual networks for each type of device
#
# POST /networks/{networkId}/split
# operationId: splitNetwork
export def "networks-split splitNetwork" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/split")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the SSIDs in a network
#
# GET /networks/{networkId}/ssids
# operationId: getNetworkSsids
export def "networks-ssids list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/ssids")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a single SSID
#
# GET /networks/{networkId}/ssids/{number}
# operationId: getNetworkSsid
export def "networks-ssids get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/ssids/($number)")
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
export def "networks-ssids updateNetworkSsid" [
  networkId: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apTagsAndVlanIds: list # The list of tags and VLAN IDs used for VLAN tagging. This param is only valid when the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming' — item shape: {tags?: string, vlanId?: int}
  --authMode: string@authMode-completer # The association control method for the SSID ('open', 'open-enhanced', 'psk', 'open-with-radius', 'open-with-nac', '8021x-meraki', '8021x-nac', '8021x-radius', '8021x-google', '8021x-localradius', 'ipsk-with-radius' or 'ipsk-without-radius')
  --availabilityTags: list # Accepts a list of tags for this SSID. If availableOnAllAps is false, then the SSID will only be broadcast by APs with tags matching any of the tags in this list.
  --availableOnAllAps: oneof<nothing, bool> # Boolean indicating whether all APs should broadcast the SSID or if it should be restricted to APs matching any availability tags. Can only be false if the SSID has availability tags.
  --bandSelection: string # The client-serving radio frequencies of this SSID in the default indoor RF profile. ('Dual band operation', '5 GHz band only' or 'Dual band operation with Band Steering')
  --concentratorNetworkId: string # The concentrator to use when the ipAssignmentMode is 'Layer 3 roaming with a concentrator' or 'VPN'.
  --defaultVlanId: int # The default VLAN ID used for 'all other APs'. This param is only valid when the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
  --disassociateClientsOnVpnFailover: oneof<nothing, bool> # Disassociate clients when 'VPN' concentrator failover occurs in order to trigger clients to re-associate and generate new DHCP requests. This param is only valid if ipAssignmentMode is 'VPN'.
  --enabled: oneof<nothing, bool> # Whether or not the SSID is enabled
  --encryptionMode: string@encryptionMode-completer # The psk encryption mode for the SSID ('wep' or 'wpa'). This param is only valid if the authMode is 'psk'
  --enterpriseAdminAccess: string@enterpriseAdminAccess-completer # Whether or not an SSID is accessible by 'enterprise' administrators ('access disabled' or 'access enabled')
  --ipAssignmentMode: string # The client IP assignment mode ('NAT mode', 'Bridge mode', 'Layer 3 roaming', 'Ethernet over GRE', 'Layer 3 roaming with a concentrator' or 'VPN')
  --lanIsolationEnabled: oneof<nothing, bool> # Boolean indicating whether Layer 2 LAN isolation should be enabled or disabled. Only configurable when ipAssignmentMode is 'Bridge mode'.
  --minBitrate: float # The minimum bitrate in Mbps of this SSID in the default indoor RF profile. ('1', '2', '5.5', '6', '9', '11', '12', '18', '24', '36', '48' or '54') (format: float)
  --name: string # The name of the SSID
  --perClientBandwidthLimitDown: int # The download bandwidth limit in Kbps. (0 represents no limit.)
  --perClientBandwidthLimitUp: int # The upload bandwidth limit in Kbps. (0 represents no limit.)
  --psk: string # The passkey for the SSID. This param is only valid if the authMode is 'psk'
  --radiusAccountingEnabled: oneof<nothing, bool> # Whether or not RADIUS accounting is enabled. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius'
  --radiusAccountingServers: list # The RADIUS accounting 802.1X servers to be used for authentication. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius' and radiusAccountingEnabled is 'true' — item shape: {host: string, port?: int, secret?: string}
  --radiusAttributeForGroupPolicies: string # Specify the RADIUS attribute used to look up group policies ('Filter-Id', 'Reply-Message', 'Airespace-ACL-Name' or 'Aruba-User-Role'). Access points must receive this attribute in the RADIUS Access-Accept message
  --radiusCoaEnabled: oneof<nothing, bool> # If true, Meraki devices will act as a RADIUS Dynamic Authorization Server and will respond to RADIUS Change-of-Authorization and Disconnect messages sent by the RADIUS server.
  --radiusFailoverPolicy: string@radiusFailoverPolicy-completer # This policy determines how authentication requests should be handled in the event that all of the configured RADIUS servers are unreachable ('Deny access' or 'Allow access')
  --radiusLoadBalancingPolicy: string@radiusLoadBalancingPolicy-completer # This policy determines which RADIUS server will be contacted first in an authentication attempt and the ordering of any necessary retry attempts ('Strict priority order' or 'Round robin')
  --radiusOverride: oneof<nothing, bool> # If true, the RADIUS response can override VLAN tag. This is not valid when ipAssignmentMode is 'NAT mode'.
  --radiusServers: list # The RADIUS 802.1X servers to be used for authentication. This param is only valid if the authMode is 'open-with-radius', '8021x-radius' or 'ipsk-with-radius' — item shape: {host: string, port?: int, secret?: string}
  --secondaryConcentratorNetworkId: string # The secondary concentrator to use when the ipAssignmentMode is 'VPN'. If configured, the APs will switch to using this concentrator if the primary concentrator is unreachable. This param is optional. ('disabled' represents no secondary concentrator.)
  --splashPage: string@splashPage-completer # The type of splash page for the SSID ('None', 'Click-through splash page', 'Billing', 'Password-protected with Meraki RADIUS', 'Password-protected with custom RADIUS', 'Password-protected with Active Directory', 'Password-protected with LDAP', 'SMS authentication', 'Systems Manager Sentry', 'Facebook Wi-Fi', 'Google OAuth', 'Sponsored guest', 'Cisco ISE' or 'Google Apps domain'). This attribute is not supported for template children.
  --useVlanTagging: oneof<nothing, bool> # Whether or not traffic should be directed to use specific VLANs. This param is only valid if the ipAssignmentMode is 'Bridge mode' or 'Layer 3 roaming'
  --visible: oneof<nothing, bool> # Boolean indicating whether APs should advertise or hide this SSID. APs will only broadcast this SSID if set to true
  --vlanId: int # The VLAN ID used for VLAN tagging. This param is only valid when the ipAssignmentMode is 'Layer 3 roaming with a concentrator' or 'VPN'
  --walledGardenEnabled: oneof<nothing, bool> # Allow access to a configurable list of IP ranges, which users may access prior to sign-on.
  --walledGardenRanges: string # Specify your walled garden by entering space-separated addresses, ranges using CIDR notation, domain names, and domain wildcards (e.g. 192.168.1.1/24 192.168.37.10/32 www.yahoo.com *.google.com). Meraki's splash page is automatically included in your walled garden.
  --wpaEncryptionMode: string@wpaEncryptionMode-completer # The types of WPA encryption. ('WPA1 only', 'WPA1 and WPA2', 'WPA2 only', 'WPA3 Transition Mode' or 'WPA3 only')
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/ssids/($number)")
  let body = {apTagsAndVlanIds: $apTagsAndVlanIds, authMode: $authMode, availabilityTags: $availabilityTags, availableOnAllAps: $availableOnAllAps, bandSelection: $bandSelection, concentratorNetworkId: $concentratorNetworkId, defaultVlanId: $defaultVlanId, disassociateClientsOnVpnFailover: $disassociateClientsOnVpnFailover, enabled: $enabled, encryptionMode: $encryptionMode, enterpriseAdminAccess: $enterpriseAdminAccess, ipAssignmentMode: $ipAssignmentMode, lanIsolationEnabled: $lanIsolationEnabled, minBitrate: $minBitrate, name: $name, perClientBandwidthLimitDown: $perClientBandwidthLimitDown, perClientBandwidthLimitUp: $perClientBandwidthLimitUp, psk: $psk, radiusAccountingEnabled: $radiusAccountingEnabled, radiusAccountingServers: $radiusAccountingServers, radiusAttributeForGroupPolicies: $radiusAttributeForGroupPolicies, radiusCoaEnabled: $radiusCoaEnabled, radiusFailoverPolicy: $radiusFailoverPolicy, radiusLoadBalancingPolicy: $radiusLoadBalancingPolicy, radiusOverride: $radiusOverride, radiusServers: $radiusServers, secondaryConcentratorNetworkId: $secondaryConcentratorNetworkId, splashPage: $splashPage, useVlanTagging: $useVlanTagging, visible: $visible, vlanId: $vlanId, walledGardenEnabled: $walledGardenEnabled, walledGardenRanges: $walledGardenRanges, wpaEncryptionMode: $wpaEncryptionMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the L3 firewall rules for an SSID on an MR network
#
# GET /networks/{networkId}/ssids/{number}/l3FirewallRules
# operationId: getNetworkSsidL3FirewallRules
export def "networks-ssids-l3-firewall-rules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/ssids/($number)/l3FirewallRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the L3 firewall rules of an SSID on an MR network
#
# PUT /networks/{networkId}/ssids/{number}/l3FirewallRules
# operationId: updateNetworkSsidL3FirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp"}
export def "networks-ssids-l3-firewall-rules updateNetworkSsidL3FirewallRules" [
  networkId: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowLanAccess: oneof<nothing, bool> # Allow wireless client access to local LAN (boolean value - true allows access and false denies access) (optional)
  --rules: list # An ordered array of the firewall rules for this SSID (not including the local LAN access rule or the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp"}
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/ssids/($number)/l3FirewallRules")
  let body = {allowLanAccess: $allowLanAccess, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Display the splash page settings for the given SSID
#
# GET /networks/{networkId}/ssids/{number}/splashSettings
# operationId: getNetworkSsidSplashSettings
export def "networks-ssids-splash-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/ssids/($number)/splashSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the splash page settings for the given SSID
#
# PUT /networks/{networkId}/ssids/{number}/splashSettings
# operationId: updateNetworkSsidSplashSettings
export def "networks-ssids-splash-settings updateNetworkSsidSplashSettings" [
  networkId: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --splashUrl: string # [optional] The custom splash URL of the click-through splash page. Note that the URL can be configured without necessarily being used. In order to enable the custom URL, see 'useSplashUrl'
  --useSplashUrl: oneof<nothing, bool> # [optional] Boolean indicating whether the user will be redirected to the custom splash url. A custom splash URL must be set if this is true. Note that depending on your SSID's access control settings, it may not be possible to use the custom splash URL.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/ssids/($number)/splashSettings")
  let body = {splashUrl: $splashUrl, useSplashUrl: $useSplashUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the static routes for an MX or teleworker network
#
# GET /networks/{networkId}/staticRoutes
# operationId: getNetworkStaticRoutes
export def "networks-static-routes list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/staticRoutes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a static route for an MX or teleworker network
#
# POST /networks/{networkId}/staticRoutes
# operationId: createNetworkStaticRoute
export def "networks-static-routes createNetworkStaticRoute" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  gatewayIp: string # The gateway IP (next hop) of the static route
  name: string # The name of the new static route
  subnet: string # The subnet of the static route
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/staticRoutes")
  let body = {gatewayIp: $gatewayIp, name: $name, subnet: $subnet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a static route from an MX or teleworker network
#
# DELETE /networks/{networkId}/staticRoutes/{staticRouteId}
# operationId: deleteNetworkStaticRoute
export def "networks-static-routes delete" [
  networkId: string
  staticRouteId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/staticRoutes/($staticRouteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a static route for an MX or teleworker network
#
# GET /networks/{networkId}/staticRoutes/{staticRouteId}
# operationId: getNetworkStaticRoute
export def "networks-static-routes get" [
  networkId: string
  staticRouteId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/staticRoutes/($staticRouteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a static route for an MX or teleworker network
#
# PUT /networks/{networkId}/staticRoutes/{staticRouteId}
# operationId: updateNetworkStaticRoute
# --reservedIpRanges item shape: {comment: string, end: string, start: string}
export def "networks-static-routes updateNetworkStaticRoute" [
  networkId: string
  staticRouteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # The enabled state of the static route
  --fixedIpAssignments: record # The DHCP fixed IP assignments on the static route. This should be an object that contains mappings from MAC addresses to objects that themselves each contain "ip" and "name" string fields. See the sample request/response for more details.
  --gatewayIp: string # The gateway IP (next hop) of the static route
  --name: string # The name of the static route
  --reservedIpRanges: list # The DHCP reserved IP ranges on the static route — item shape: {comment: string, end: string, start: string}
  --subnet: string # The subnet of the static route
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/staticRoutes/($staticRouteId)")
  let body = {enabled: $enabled, fixedIpAssignments: $fixedIpAssignments, gatewayIp: $gatewayIp, name: $name, reservedIpRanges: $reservedIpRanges, subnet: $subnet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Swap MX primary and warm spare appliances
#
# POST /networks/{networkId}/swapWarmSpare
# operationId: swapNetworkWarmSpare
export def "networks-swap-warm-spare swapNetworkWarmSpare" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/swapWarmSpare")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List link aggregation groups
#
# GET /networks/{networkId}/switch/linkAggregations
# operationId: getNetworkSwitchLinkAggregations
export def "networks-switch-link-aggregations get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/linkAggregations")
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
export def "networks-switch-link-aggregations createNetworkSwitchLinkAggregation" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --switchPorts: list # Array of switch or stack ports for creating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, serial: string}
  --switchProfilePorts: list # Array of switch profile ports for creating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, profile: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/linkAggregations")
  let body = {switchPorts: $switchPorts, switchProfilePorts: $switchProfilePorts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Split a link aggregation group into separate ports
#
# DELETE /networks/{networkId}/switch/linkAggregations/{linkAggregationId}
# operationId: deleteNetworkSwitchLinkAggregation
export def "networks-switch-link-aggregations delete" [
  networkId: string
  linkAggregationId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/linkAggregations/($linkAggregationId)")
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
export def "networks-switch-link-aggregations updateNetworkSwitchLinkAggregation" [
  networkId: string
  linkAggregationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --switchPorts: list # Array of switch or stack ports for updating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, serial: string}
  --switchProfilePorts: list # Array of switch profile ports for updating aggregation group. Minimum 2 and maximum 8 ports are supported. — item shape: {portId: string, profile: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/linkAggregations/($linkAggregationId)")
  let body = {switchPorts: $switchPorts, switchProfilePorts: $switchProfilePorts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List switch port schedules
#
# GET /networks/{networkId}/switch/portSchedules
# operationId: getNetworkSwitchPortSchedules
export def "networks-switch-port-schedules get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/portSchedules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a switch port schedule
#
# POST /networks/{networkId}/switch/portSchedules
# operationId: createNetworkSwitchPortSchedule
# --portSchedule shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
export def "networks-switch-port-schedules createNetworkSwitchPortSchedule" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for your port schedule. Required
  --portSchedule: record #     The schedule for switch port scheduling. Schedules are applied to days of the week.     When it's empty, default schedule with all days of a week are configured.     Any unspecified day in the schedule is added as a default schedule configuration of the day. — shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/portSchedules")
  let body = {name: $name, portSchedule: $portSchedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a switch port schedule
#
# DELETE /networks/{networkId}/switch/portSchedules/{portScheduleId}
# operationId: deleteNetworkSwitchPortSchedule
export def "networks-switch-port-schedules delete" [
  networkId: string
  portScheduleId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/portSchedules/($portScheduleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a switch port schedule
#
# PUT /networks/{networkId}/switch/portSchedules/{portScheduleId}
# operationId: updateNetworkSwitchPortSchedule
# --portSchedule shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
export def "networks-switch-port-schedules updateNetworkSwitchPortSchedule" [
  networkId: string
  portScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name for your port schedule.
  --portSchedule: record #     The schedule for switch port scheduling. Schedules are applied to days of the week.     When it's empty, default schedule with all days of a week are configured.     Any unspecified day in the schedule is added as a default schedule configuration of the day. — shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/portSchedules/($portScheduleId)")
  let body = {name: $name, portSchedule: $portSchedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the switch network settings
#
# GET /networks/{networkId}/switch/settings
# operationId: getNetworkSwitchSettings
export def "networks-switch-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update switch network settings
#
# PUT /networks/{networkId}/switch/settings
# operationId: updateNetworkSwitchSettings
# --powerExceptions item shape: {powerType: "combined"|"redundant"|"useNetworkSetting", serial: string}
export def "networks-switch-settings updateNetworkSwitchSettings" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --powerExceptions: list # Exceptions on a per switch basis to "useCombinedPower" — item shape: {powerType: "combined"|"redundant"|"useNetworkSetting", serial: string}
  --useCombinedPower: oneof<nothing, bool> # The use Combined Power as the default behavior of secondary power supplies on supported devices.
  --vlan: int # Management VLAN
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings")
  let body = {powerExceptions: $powerExceptions, useCombinedPower: $useCombinedPower, vlan: $vlan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the MTU configuration
#
# GET /networks/{networkId}/switch/settings/mtu
# operationId: getNetworkSwitchSettingsMtu
export def "networks-switch-settings-mtu get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/mtu")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the MTU configuration
#
# PUT /networks/{networkId}/switch/settings/mtu
# operationId: updateNetworkSwitchSettingsMtu
# --overrides item shape: {mtuSize: int, switchProfiles?: list, switches?: list}
export def "networks-switch-settings-mtu updateNetworkSwitchSettingsMtu" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultMtuSize: int # MTU size for the entire network. Default value is 9578.
  --overrides: list # Override MTU size for individual switches or switch profiles. An empty array will clear overrides. — item shape: {mtuSize: int, switchProfiles?: list, switches?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/mtu")
  let body = {defaultMtuSize: $defaultMtuSize, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return multicast settings for a network
#
# GET /networks/{networkId}/switch/settings/multicast
# operationId: getNetworkSwitchSettingsMulticast
export def "networks-switch-settings-multicast get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/multicast")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update multicast settings for a network
#
# PUT /networks/{networkId}/switch/settings/multicast
# operationId: updateNetworkSwitchSettingsMulticast
# --defaultSettings shape: {floodUnknownMulticastTrafficEnabled?: bool, igmpSnoopingEnabled?: bool}
# --overrides item shape: {floodUnknownMulticastTrafficEnabled: bool, igmpSnoopingEnabled: bool, stacks?: list, switchProfiles?: list, switches?: list}
export def "networks-switch-settings-multicast updateNetworkSwitchSettingsMulticast" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultSettings: record # Default multicast setting for entire network. IGMP snooping and Flood unknown multicast traffic settings are enabled by default. — shape: {floodUnknownMulticastTrafficEnabled?: bool, igmpSnoopingEnabled?: bool}
  --overrides: list # Array of paired switches/stacks/profiles and corresponding multicast settings. An empty array will clear the multicast settings. — item shape: {floodUnknownMulticastTrafficEnabled: bool, igmpSnoopingEnabled: bool, stacks?: list, switchProfiles?: list, switches?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/multicast")
  let body = {defaultSettings: $defaultSettings, overrides: $overrides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List quality of service rules
#
# GET /networks/{networkId}/switch/settings/qosRules
# operationId: getNetworkSwitchSettingsQosRules
export def "networks-switch-settings-qos-rules list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/qosRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a quality of service rule
#
# POST /networks/{networkId}/switch/settings/qosRules
# operationId: createNetworkSwitchSettingsQosRule
export def "networks-switch-settings-qos-rules createNetworkSwitchSettingsQosRule" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dscp: int # DSCP tag. Set this to -1 to trust incoming DSCP. Default value is 0
  --dstPort: int # The destination port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --dstPortRange: string # The destination port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --protocol: string@protocol-completer # The protocol of the incoming packet. Can be one of "ANY", "TCP" or "UDP". Default value is "ANY"
  --srcPort: int # The source port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --srcPortRange: string # The source port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  vlan: int # The VLAN of the incoming packet. A null value will match any VLAN.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/qosRules")
  let body = {dscp: $dscp, dstPort: $dstPort, dstPortRange: $dstPortRange, protocol: $protocol, srcPort: $srcPort, srcPortRange: $srcPortRange, vlan: $vlan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the quality of service rule IDs by order in which they will be processed by the switch
#
# GET /networks/{networkId}/switch/settings/qosRules/order
# operationId: getNetworkSwitchSettingsQosRulesOrder
export def "networks-switch-settings-qos-rules-order get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/qosRules/order")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the order in which the rules should be processed by the switch
#
# PUT /networks/{networkId}/switch/settings/qosRules/order
# operationId: updateNetworkSwitchSettingsQosRulesOrder
export def "networks-switch-settings-qos-rules-order updateNetworkSwitchSettingsQosRulesOrder" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ruleIds: list # A list of quality of service rule IDs arranged in order in which they should be processed by the switch.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/qosRules/order")
  let body = {ruleIds: $ruleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a quality of service rule
#
# DELETE /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# operationId: deleteNetworkSwitchSettingsQosRule
export def "networks-switch-settings-qos-rules delete" [
  networkId: string
  qosRuleId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/qosRules/($qosRuleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a quality of service rule
#
# GET /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# operationId: getNetworkSwitchSettingsQosRule
export def "networks-switch-settings-qos-rules get" [
  networkId: string
  qosRuleId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/qosRules/($qosRuleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a quality of service rule
#
# PUT /networks/{networkId}/switch/settings/qosRules/{qosRuleId}
# operationId: updateNetworkSwitchSettingsQosRule
export def "networks-switch-settings-qos-rules updateNetworkSwitchSettingsQosRule" [
  networkId: string
  qosRuleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dscp: int # DSCP tag that should be assigned to incoming packet. Set this to -1 to trust incoming DSCP. Default value is 0.
  --dstPort: int # The destination port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --dstPortRange: string # The destination port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --protocol: string@protocol-completer # The protocol of the incoming packet. Can be one of "ANY", "TCP" or "UDP". Default value is "ANY".
  --srcPort: int # The source port of the incoming packet. Applicable only if protocol is TCP or UDP.
  --srcPortRange: string # The source port range of the incoming packet. Applicable only if protocol is set to TCP or UDP. Example: 70-80
  --vlan: int # The VLAN of the incoming packet. A null value will match any VLAN.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/qosRules/($qosRuleId)")
  let body = {dscp: $dscp, dstPort: $dstPort, dstPortRange: $dstPortRange, protocol: $protocol, srcPort: $srcPort, srcPortRange: $srcPortRange, vlan: $vlan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the storm control configuration for a switch network
#
# GET /networks/{networkId}/switch/settings/stormControl
# operationId: getNetworkSwitchSettingsStormControl
export def "networks-switch-settings-storm-control get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/stormControl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the storm control configuration for a switch network
#
# PUT /networks/{networkId}/switch/settings/stormControl
# operationId: updateNetworkSwitchSettingsStormControl
export def "networks-switch-settings-storm-control updateNetworkSwitchSettingsStormControl" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broadcastThreshold: int # Percentage (1 to 99) of total available port bandwidth for broadcast traffic type. Default value 100 percent rate is to clear the configuration.
  --multicastThreshold: int # Percentage (1 to 99) of total available port bandwidth for multicast traffic type. Default value 100 percent rate is to clear the configuration.
  --unknownUnicastThreshold: int # Percentage (1 to 99) of total available port bandwidth for unknown unicast (dlf-destination lookup failure) traffic type. Default value 100 percent rate is to clear the configuration.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switch/settings/stormControl")
  let body = {broadcastThreshold: $broadcastThreshold, multicastThreshold: $multicastThreshold, unknownUnicastThreshold: $unknownUnicastThreshold} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the switch stacks in a network
#
# GET /networks/{networkId}/switchStacks
# operationId: getNetworkSwitchStacks
export def "networks-switch-stacks list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switchStacks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a stack
#
# POST /networks/{networkId}/switchStacks
# operationId: createNetworkSwitchStack
export def "networks-switch-stacks createNetworkSwitchStack" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the new stack
  serials: list # An array of switch serials to be added into the new stack
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/switchStacks")
  let body = {name: $name, serials: $serials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a stack
#
# DELETE /networks/{networkId}/switchStacks/{switchStackId}
# operationId: deleteNetworkSwitchStack
export def "networks-switch-stacks delete" [
  networkId: string
  switchStackId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switchStacks/($switchStackId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show a switch stack
#
# GET /networks/{networkId}/switchStacks/{switchStackId}
# operationId: getNetworkSwitchStack
export def "networks-switch-stacks get" [
  networkId: string
  switchStackId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switchStacks/($switchStackId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a switch to a stack
#
# POST /networks/{networkId}/switchStacks/{switchStackId}/add
# operationId: addNetworkSwitchStack
export def "networks-switch-stacks-add addNetworkSwitchStack" [
  networkId: string
  switchStackId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switchStacks/($switchStackId)/add")
  let body = {serial: $serial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a switch from a stack
#
# POST /networks/{networkId}/switchStacks/{switchStackId}/remove
# operationId: removeNetworkSwitchStack
export def "networks-switch-stacks-remove removeNetworkSwitchStack" [
  networkId: string
  switchStackId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/switchStacks/($switchStackId)/remove")
  let body = {serial: $serial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the syslog servers for a network
#
# GET /networks/{networkId}/syslogServers
# operationId: getNetworkSyslogServers
export def "networks-syslog-servers get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/syslogServers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the syslog servers for a network
#
# PUT /networks/{networkId}/syslogServers
# operationId: updateNetworkSyslogServers
# --servers item shape: {host: string, port: int, roles: list}
export def "networks-syslog-servers updateNetworkSyslogServers" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  servers: list # A list of the syslog servers for this network — item shape: {host: string, port: int, roles: list}
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/syslogServers")
  let body = {servers: $servers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the traffic analysis data for this network
#
# GET /networks/{networkId}/traffic
# operationId: getNetworkTraffic
export def "networks-traffic get" [
  networkId: string
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
  --deviceType: string@deviceType-completer # Filter the data by device type: 'combined', 'wireless', 'switch' or 'appliance'. Defaults to 'combined'. When using 'combined', for each rule the data will come from the device type with the most usage.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "deviceType" $deviceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/traffic" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unbind a network from a template.
#
# POST /networks/{networkId}/unbind
# operationId: unbindNetwork
export def "networks-unbind unbindNetwork" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/unbind")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the uplink settings for your MX network.
#
# GET /networks/{networkId}/uplinkSettings
# operationId: getNetworkUplinkSettings
export def "networks-uplink-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/uplinkSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the uplink settings for your MX network.
#
# PUT /networks/{networkId}/uplinkSettings
# operationId: updateNetworkUplinkSettings
# --bandwidthLimits shape: {cellular?: record, wan1?: record, wan2?: record}
export def "networks-uplink-settings updateNetworkUplinkSettings" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bandwidthLimits: record # A mapping of uplinks to their bandwidth settings (be sure to check which uplinks are supported for your network) — shape: {cellular?: record, wan1?: record, wan2?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/uplinkSettings")
  let body = {bandwidthLimits: $bandwidthLimits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the VLANs for an MX network
#
# GET /networks/{networkId}/vlans
# operationId: getNetworkVlans
export def "networks-vlans list" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/vlans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a VLAN
#
# POST /networks/{networkId}/vlans
# operationId: createNetworkVlan
export def "networks-vlans createNetworkVlan" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  applianceIp: string # The local IP of the appliance on the VLAN
  --groupPolicyId: string # The id of the desired group policy to apply to the VLAN
  id: string # The VLAN ID of the new VLAN (must be between 1 and 4094)
  name: string # The name of the new VLAN
  subnet: string # The subnet of the VLAN
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/vlans")
  let body = {applianceIp: $applianceIp, groupPolicyId: $groupPolicyId, id: $id, name: $name, subnet: $subnet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a VLAN from a network
#
# DELETE /networks/{networkId}/vlans/{vlanId}
# operationId: deleteNetworkVlan
export def "networks-vlans delete" [
  networkId: string
  vlanId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/vlans/($vlanId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a VLAN
#
# GET /networks/{networkId}/vlans/{vlanId}
# operationId: getNetworkVlan
export def "networks-vlans get" [
  networkId: string
  vlanId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/vlans/($vlanId)")
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
export def "networks-vlans updateNetworkVlan" [
  networkId: string
  vlanId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --applianceIp: string # The local IP of the appliance on the VLAN
  --dhcpBootFilename: string # DHCP boot option for boot filename
  --dhcpBootNextServer: string # DHCP boot option to direct boot clients to the server to load the boot file from
  --dhcpBootOptionsEnabled: oneof<nothing, bool> # Use DHCP boot options specified in other properties
  --dhcpHandling: string@dhcpHandling-completer # The appliance's handling of DHCP requests on this VLAN. One of: 'Run a DHCP server', 'Relay DHCP to another server' or 'Do not respond to DHCP requests'
  --dhcpLeaseTime: string@dhcpLeaseTime-completer # The term of DHCP leases if the appliance is running a DHCP server on this VLAN. One of: '30 minutes', '1 hour', '4 hours', '12 hours', '1 day' or '1 week'
  --dhcpOptions: list # The list of DHCP options that will be included in DHCP responses. Each object in the list should have "code", "type", and "value" properties. — item shape: {code: string, type: "hex"|"integer"|"ip"|"text", value: string}
  --dhcpRelayServerIps: list # The IPs of the DHCP servers that DHCP requests should be relayed to
  --dnsNameservers: string # The DNS nameservers used for DHCP responses, either "upstream_dns", "google_dns", "opendns", or a newline seperated string of IP addresses or domain names
  --fixedIpAssignments: record # The DHCP fixed IP assignments on the VLAN. This should be an object that contains mappings from MAC addresses to objects that themselves each contain "ip" and "name" string fields. See the sample request/response for more details.
  --groupPolicyId: string # The id of the desired group policy to apply to the VLAN
  --name: string # The name of the VLAN
  --reservedIpRanges: list # The DHCP reserved IP ranges on the VLAN — item shape: {comment: string, end: string, start: string}
  --subnet: string # The subnet of the VLAN
  --vpnNatSubnet: string # The translated VPN subnet if VPN and VPN subnet translation are enabled on the VLAN
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/vlans/($vlanId)")
  let body = {applianceIp: $applianceIp, dhcpBootFilename: $dhcpBootFilename, dhcpBootNextServer: $dhcpBootNextServer, dhcpBootOptionsEnabled: $dhcpBootOptionsEnabled, dhcpHandling: $dhcpHandling, dhcpLeaseTime: $dhcpLeaseTime, dhcpOptions: $dhcpOptions, dhcpRelayServerIps: $dhcpRelayServerIps, dnsNameservers: $dnsNameservers, fixedIpAssignments: $fixedIpAssignments, groupPolicyId: $groupPolicyId, name: $name, reservedIpRanges: $reservedIpRanges, subnet: $subnet, vpnNatSubnet: $vpnNatSubnet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the enabled status of VLANs for the network
#
# GET /networks/{networkId}/vlansEnabledState
# operationId: getNetworkVlansEnabledState
export def "networks-vlans-enabled-state get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/vlansEnabledState")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable/Disable VLANs for the given network
#
# PUT /networks/{networkId}/vlansEnabledState
# operationId: updateNetworkVlansEnabledState
export def "networks-vlans-enabled-state updateNetworkVlansEnabledState" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/vlansEnabledState")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return MX warm spare settings
#
# GET /networks/{networkId}/warmSpareSettings
# operationId: getNetworkWarmSpareSettings
export def "networks-warm-spare-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/warmSpareSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update MX warm spare settings
#
# PUT /networks/{networkId}/warmSpareSettings
# operationId: updateNetworkWarmSpareSettings
export def "networks-warm-spare-settings updateNetworkWarmSpareSettings" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Enable warm spare
  --spareSerial: string # Serial number of the warm spare appliance
  --uplinkMode: string # Uplink mode, either virtual or public
  --virtualIp1: string # The WAN 1 shared IP
  --virtualIp2: string # The WAN 2 shared IP
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/warmSpareSettings")
  let body = {enabled: $enabled, spareSerial: $spareSerial, uplinkMode: $uplinkMode, virtualIp1: $virtualIp1, virtualIp2: $virtualIp2} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the non-basic RF profiles for this network
#
# GET /networks/{networkId}/wireless/rfProfiles
# operationId: getNetworkWirelessRfProfiles
export def "networks-wireless-rf-profiles list" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeTemplateProfiles: oneof<nothing, bool> # If the network is bound to a template, this parameter controls whether or not the non-basic RF profiles defined on the template should be included in the response alongside the non-basic profiles defined on the bound network. Defaults to false.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeTemplateProfiles" $includeTemplateProfiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($networkId)/wireless/rfProfiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates new RF profile for this network
#
# POST /networks/{networkId}/wireless/rfProfiles
# operationId: createNetworkWirelessRfProfile
# --apBandSettings shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
# --fiveGhzSettings shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list}
# --twoFourGhzSettings shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list}
export def "networks-wireless-rf-profiles createNetworkWirelessRfProfile" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apBandSettings: record # Settings that will be enabled if selectionType is set to 'ap'. — shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
  bandSelectionType: string@bandSelectionType-completer # Band selection can be set to either 'ssid' or 'ap'. This param is required on creation.
  --clientBalancingEnabled: oneof<nothing, bool> # Steers client to best available access point. Can be either true or false. Defaults to true.
  --fiveGhzSettings: record # Settings related to 5Ghz band — shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list}
  --minBitrateType: string@minBitrateType-completer # Minimum bitrate can be set to either 'band' or 'ssid'. Defaults to band.
  name: string # The name of the new profile. Must be unique. This param is required on creation.
  --twoFourGhzSettings: record # Settings related to 2.4Ghz band — shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/wireless/rfProfiles")
  let body = {apBandSettings: $apBandSettings, bandSelectionType: $bandSelectionType, clientBalancingEnabled: $clientBalancingEnabled, fiveGhzSettings: $fiveGhzSettings, minBitrateType: $minBitrateType, name: $name, twoFourGhzSettings: $twoFourGhzSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a RF Profile
#
# DELETE /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# operationId: deleteNetworkWirelessRfProfile
export def "networks-wireless-rf-profiles delete" [
  networkId: string
  rfProfileId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/wireless/rfProfiles/($rfProfileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a RF profile
#
# GET /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# operationId: getNetworkWirelessRfProfile
export def "networks-wireless-rf-profiles get" [
  networkId: string
  rfProfileId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/wireless/rfProfiles/($rfProfileId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates specified RF profile for this network
#
# PUT /networks/{networkId}/wireless/rfProfiles/{rfProfileId}
# operationId: updateNetworkWirelessRfProfile
# --apBandSettings shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
# --fiveGhzSettings shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list}
# --twoFourGhzSettings shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list}
export def "networks-wireless-rf-profiles updateNetworkWirelessRfProfile" [
  networkId: string
  rfProfileId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apBandSettings: record # Settings that will be enabled if selectionType is set to 'ap'. — shape: {bandOperationMode?: "2.4ghz"|"5ghz"|"dual", bandSteeringEnabled?: bool}
  --bandSelectionType: string@bandSelectionType-completer # Band selection can be set to either 'ssid' or 'ap'.
  --clientBalancingEnabled: oneof<nothing, bool> # Steers client to best available access point. Can be either true or false.
  --fiveGhzSettings: record # Settings related to 5Ghz band — shape: {channelWidth?: string, maxPower?: int, minBitrate?: int, minPower?: int, rxsop?: int, validAutoChannels?: list}
  --minBitrateType: string@minBitrateType-completer # Minimum bitrate can be set to either 'band' or 'ssid'.
  --name: string # The name of the new profile. Must be unique.
  --twoFourGhzSettings: record # Settings related to 2.4Ghz band — shape: {axEnabled?: bool, maxPower?: int, minBitrate?: float, minPower?: int, rxsop?: int, validAutoChannels?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/wireless/rfProfiles/($rfProfileId)")
  let body = {apBandSettings: $apBandSettings, bandSelectionType: $bandSelectionType, clientBalancingEnabled: $clientBalancingEnabled, fiveGhzSettings: $fiveGhzSettings, minBitrateType: $minBitrateType, name: $name, twoFourGhzSettings: $twoFourGhzSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the wireless settings for a network
#
# GET /networks/{networkId}/wireless/settings
# operationId: getNetworkWirelessSettings
export def "networks-wireless-settings get" [
  networkId: string
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
  let full_url = (build-url $base $"/networks/($networkId)/wireless/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the wireless settings for a network
#
# PUT /networks/{networkId}/wireless/settings
# operationId: updateNetworkWirelessSettings
export def "networks-wireless-settings updateNetworkWirelessSettings" [
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ipv6BridgeEnabled: oneof<nothing, bool> # Toggle for enabling or disabling IPv6 bridging in a network (Note: if enabled, SSIDs must also be configured to use bridge mode)
  --ledLightsOn: oneof<nothing, bool> # Toggle for enabling or disabling LED lights on all APs in the network (making them run dark)
  --locationAnalyticsEnabled: oneof<nothing, bool> # Toggle for enabling or disabling location analytics for your network
  --meshingEnabled: oneof<nothing, bool> # Toggle for enabling or disabling meshing in a network
  --upgradeStrategy: string@upgradeStrategy-completer # The upgrade strategy to apply to the network. Must be one of 'minimizeUpgradeTime' or 'minimizeClientDowntime'. Requires firmware version MR 26.8 or higher'
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($networkId)/wireless/settings")
  let body = {ipv6BridgeEnabled: $ipv6BridgeEnabled, ledLightsOn: $ledLightsOn, locationAnalyticsEnabled: $locationAnalyticsEnabled, meshingEnabled: $meshingEnabled, upgradeStrategy: $upgradeStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lock a set of devices
#
# PUT /networks/{network_id}/sm/devices/lock
# operationId: lockNetworkSmDevices
export def "networks-sm-devices-lock lockNetworkSmDevices" [
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
  --wifiMacs: string # The wifiMacs of the devices to be locked.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($network_id)/sm/devices/lock")
  let body = {ids: $ids, pin: $pin, scope: $scope, serials: $serials, wifiMacs: $wifiMacs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($network_id)/sm/($id)/connectivity" $qp)
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($network_id)/sm/($id)/desktopLogs" $qp)
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($network_id)/sm/($id)/deviceCommandLogs" $qp)
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($network_id)/sm/($id)/performanceHistory" $qp)
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
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the list of action batches in the organization
#
# GET /organizations/{organizationId}/actionBatches
# operationId: getOrganizationActionBatches
export def "organizations-action-batches get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/actionBatches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an action batch
#
# POST /organizations/{organizationId}/actionBatches
# operationId: createOrganizationActionBatch
# --actions item shape: {body?: record, operation: string, resource: string}
export def "organizations-action-batches createOrganizationActionBatch" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  actions: list # A set of changes to make as part of this action (<a href='https://developer.cisco.com/meraki/api/#/rest/guides/action-batches/'>more details</a>) — item shape: {body?: record, operation: string, resource: string}
  --confirmed: oneof<nothing, bool> # Set to true for immediate execution. Set to false if the action should be previewed before executing. This property cannot be unset once it is true. Defaults to false.
  --synchronous: oneof<nothing, bool> # Set to true to force the batch to run synchronous. There can be at most 20 actions in synchronous batch. Defaults to false.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/actionBatches")
  let body = {actions: $actions, confirmed: $confirmed, synchronous: $synchronous} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an action batch
#
# DELETE /organizations/{organizationId}/actionBatches/{actionBatchId}
# operationId: deleteOrganizationActionBatch
export def "organizations-action-batches delete" [
  organizationId: string
  actionBatchId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/actionBatches/($actionBatchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an action batch
#
# PUT /organizations/{organizationId}/actionBatches/{actionBatchId}
# operationId: updateOrganizationActionBatch
export def "organizations-action-batches updateOrganizationActionBatch" [
  organizationId: string
  actionBatchId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/actionBatches/($actionBatchId)")
  let body = {confirmed: $confirmed, synchronous: $synchronous} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the dashboard administrators in this organization
#
# GET /organizations/{organizationId}/admins
# operationId: getOrganizationAdmins
export def "organizations-admins get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/admins")
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
export def "organizations-admins createOrganizationAdmin" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authenticationMethod: string@authenticationMethod-completer # The method of authentication the user will use to sign in to the Meraki dashboard. Can be one of 'Email' or 'Cisco SecureX Sign-On'. The default is Email authentication
  email: string # The email of the dashboard administrator. This attribute can not be updated.
  name: string # The name of the dashboard administrator
  --networks: list # The list of networks that the dashboard administrator has privileges on — item shape: {access: string, id: string}
  orgAccess: string@orgAccess-completer # The privilege of the dashboard administrator on the organization. Can be one of 'full', 'read-only', 'enterprise' or 'none'
  --tags: list # The list of tags that the dashboard administrator has privileges on — item shape: {access: string, tag: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/admins")
  let body = {authenticationMethod: $authenticationMethod, email: $email, name: $name, networks: $networks, orgAccess: $orgAccess, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke all access for a dashboard administrator within this organization
#
# DELETE /organizations/{organizationId}/admins/{adminId}
# operationId: deleteOrganizationAdmin
export def "organizations-admins delete" [
  organizationId: string
  adminId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/admins/($adminId)")
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
export def "organizations-admins updateOrganizationAdmin" [
  organizationId: string
  adminId: string
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
  --orgAccess: string@orgAccess-completer # The privilege of the dashboard administrator on the organization. Can be one of 'full', 'read-only', 'enterprise' or 'none'
  --tags: list # The list of tags that the dashboard administrator has privileges on — item shape: {access: string, tag: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/admins/($adminId)")
  let body = {name: $name, networks: $networks, orgAccess: $orgAccess, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the API requests made by an organization
#
# GET /organizations/{organizationId}/apiRequests
# operationId: getOrganizationApiRequests
export def "organizations-api-requests get" [
  organizationId: string
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 50.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --adminId: string # Filter the results by the ID of the admin who made the API requests
  --path: string # Filter the results by the path of the API requests
  --method: string # Filter the results by the method of the API requests (must be 'GET', 'PUT', 'POST' or 'DELETE')
  --responseCode: int # Filter the results by the response code of the API requests
  --sourceIp: string # Filter the results by the IP address of the originating API request
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar") (serialize-qp "adminId" $adminId "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "responseCode" $responseCode "scalar") (serialize-qp "sourceIp" $sourceIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/apiRequests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return an aggregated overview of API requests data
#
# GET /organizations/{organizationId}/apiRequests/overview
# operationId: getOrganizationApiRequestsOverview
export def "organizations-api-requests-overview get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/apiRequests/overview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Claim a list of devices, licenses, and/or orders into an organization
#
# POST /organizations/{organizationId}/claim
# operationId: claimIntoOrganization
# --licenses item shape: {key: string, mode?: "addDevices"|"renew"}
export def "organizations-claim claimIntoOrganization" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --licenses: list # The licenses that should be claimed — item shape: {key: string, mode?: "addDevices"|"renew"}
  --orders: list # The numbers of the orders that should be claimed
  --serials: list # The serials of the devices that should be claimed
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/claim")
  let body = {licenses: $licenses, orders: $orders, serials: $serials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new organization by cloning the addressed organization
#
# POST /organizations/{organizationId}/clone
# operationId: cloneOrganization
export def "organizations-clone cloneOrganization" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/clone")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the configuration templates for this organization
#
# GET /organizations/{organizationId}/configTemplates
# operationId: getOrganizationConfigTemplates
export def "organizations-config-templates get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/configTemplates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a configuration template
#
# DELETE /organizations/{organizationId}/configTemplates/{configTemplateId}
# operationId: deleteOrganizationConfigTemplate
export def "organizations-config-templates delete" [
  organizationId: string
  configTemplateId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/configTemplates/($configTemplateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the switch profiles for your switch template configuration
#
# GET /organizations/{organizationId}/configTemplates/{configTemplateId}/switchProfiles
# operationId: getOrganizationConfigTemplateSwitchProfiles
export def "organizations-config-templates-switch-profiles get" [
  organizationId: string
  configTemplateId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/configTemplates/($configTemplateId)/switchProfiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View the Change Log for your organization
#
# GET /organizations/{organizationId}/configurationChanges
# operationId: getOrganizationConfigurationChanges
export def "organizations-configuration-changes get" [
  organizationId: string
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 5000. Default is 5000.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --networkId: string # Filters on the given network
  --adminId: string # Filters on the given Admin
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar") (serialize-qp "networkId" $networkId "scalar") (serialize-qp "adminId" $adminId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/configurationChanges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the status of every Meraki device in the organization
#
# GET /organizations/{organizationId}/deviceStatuses
# operationId: getOrganizationDeviceStatuses
export def "organizations-device-statuses get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/deviceStatuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the devices in an organization
#
# GET /organizations/{organizationId}/devices
# operationId: getOrganizationDevices
export def "organizations-devices get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --configurationUpdatedAfter: string # Filter results by whether or not the device's configuration has been updated after the given timestamp
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar") (serialize-qp "configurationUpdatedAfter" $configurationUpdatedAfter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the monitored media servers for this organization
#
# GET /organizations/{organizationId}/insight/monitoredMediaServers
# operationId: getOrganizationInsightMonitoredMediaServers
export def "organizations-insight-monitored-media-servers list" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/insight/monitoredMediaServers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a media server to be monitored for this organization
#
# POST /organizations/{organizationId}/insight/monitoredMediaServers
# operationId: createOrganizationInsightMonitoredMediaServer
export def "organizations-insight-monitored-media-servers createOrganizationInsightMonitoredMediaServer" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/insight/monitoredMediaServers")
  let body = {address: $address, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a monitored media server from this organization
#
# DELETE /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# operationId: deleteOrganizationInsightMonitoredMediaServer
export def "organizations-insight-monitored-media-servers delete" [
  organizationId: string
  monitoredMediaServerId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/insight/monitoredMediaServers/($monitoredMediaServerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a monitored media server for this organization
#
# GET /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# operationId: getOrganizationInsightMonitoredMediaServer
export def "organizations-insight-monitored-media-servers get" [
  organizationId: string
  monitoredMediaServerId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/insight/monitoredMediaServers/($monitoredMediaServerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a monitored media server for this organization
#
# PUT /organizations/{organizationId}/insight/monitoredMediaServers/{monitoredMediaServerId}
# operationId: updateOrganizationInsightMonitoredMediaServer
export def "organizations-insight-monitored-media-servers updateOrganizationInsightMonitoredMediaServer" [
  organizationId: string
  monitoredMediaServerId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/insight/monitoredMediaServers/($monitoredMediaServerId)")
  let body = {address: $address, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the inventory for an organization
#
# GET /organizations/{organizationId}/inventory
# operationId: getOrganizationInventory
export def "organizations-inventory get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeLicenseInfo: oneof<nothing, bool> # When this parameter is true, each entity in the response will include the license expiration date of the device (if any). Only applies to organizations that are on the per-device licensing model. Defaults to false.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeLicenseInfo" $includeLicenseInfo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/inventory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return an overview of the license state for an organization
#
# GET /organizations/{organizationId}/licenseState
# operationId: getOrganizationLicenseState
export def "organizations-license-state get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/licenseState")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the licenses for an organization
#
# GET /organizations/{organizationId}/licenses
# operationId: getOrganizationLicenses
export def "organizations-licenses list" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 1000.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --deviceSerial: string # Filter the licenses to those assigned to a particular device
  --networkId: string # Filter the licenses to those assigned in a particular network
  --state: string@state-completer # Filter the licenses to those in a particular state. Can be one of 'active', 'expired', 'expiring', 'recentlyQueued', 'unused' or 'unusedActive'
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar") (serialize-qp "deviceSerial" $deviceSerial "scalar") (serialize-qp "networkId" $networkId "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/licenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign SM seats to a network
#
# POST /organizations/{organizationId}/licenses/assignSeats
# operationId: assignOrganizationLicensesSeats
export def "organizations-licenses-assign-seats assignOrganizationLicensesSeats" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  licenseId: string # The ID of the SM license to assign seats from
  networkId: string # The ID of the SM network to assign the seats to
  seatCount: int # The number of seats to assign to the SM network. Must be less than or equal to the total number of seats of the license
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/licenses/assignSeats")
  let body = {licenseId: $licenseId, networkId: $networkId, seatCount: $seatCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Move SM seats to another organization
#
# POST /organizations/{organizationId}/licenses/moveSeats
# operationId: moveOrganizationLicensesSeats
export def "organizations-licenses-move-seats moveOrganizationLicensesSeats" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destOrganizationId: string # The ID of the organization to move the SM seats to
  licenseId: string # The ID of the SM license to move the seats from
  seatCount: int # The number of seats to move to the new organization. Must be less than or equal to the total number of seats of the license
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/licenses/moveSeats")
  let body = {destOrganizationId: $destOrganizationId, licenseId: $licenseId, seatCount: $seatCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Renew SM seats of a license
#
# POST /organizations/{organizationId}/licenses/renewSeats
# operationId: renewOrganizationLicensesSeats
export def "organizations-licenses-renew-seats renewOrganizationLicensesSeats" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  licenseIdToRenew: string # The ID of the SM license to renew. This license must already be assigned to an SM network
  unusedLicenseId: string # The SM license to use to renew the seats on 'licenseIdToRenew'. This license must have at least as many seats available as there are seats on 'licenseIdToRenew'
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/licenses/renewSeats")
  let body = {licenseIdToRenew: $licenseIdToRenew, unusedLicenseId: $unusedLicenseId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Display a license
#
# GET /organizations/{organizationId}/licenses/{licenseId}
# operationId: getOrganizationLicense
export def "organizations-licenses get" [
  organizationId: string
  licenseId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/licenses/($licenseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the networks in an organization
#
# GET /organizations/{organizationId}/networks
# operationId: getOrganizationNetworks
export def "organizations-networks get" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configTemplateId: string # An optional parameter that is the ID of a config template. Will return all networks bound to that template.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configTemplateId" $configTemplateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a network
#
# POST /organizations/{organizationId}/networks
# operationId: createOrganizationNetwork
export def "organizations-networks createOrganizationNetwork" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --copyFromNetworkId: string # The ID of the network to copy configuration from. Other provided parameters will override the copied configuration, except type which must match this network's type exactly.
  --disableMyMerakiCom: oneof<nothing, bool> # Disables the local device status pages (<a target='_blank' href='http://my.meraki.com/'>my.meraki.com, </a><a target='_blank' href='http://ap.meraki.com/'>ap.meraki.com, </a><a target='_blank' href='http://switch.meraki.com/'>switch.meraki.com, </a><a target='_blank' href='http://wired.meraki.com/'>wired.meraki.com</a>). Optional (defaults to false)
  --disableRemoteStatusPage: oneof<nothing, bool> # Disables access to the device status page (<a target='_blank'>http://[device's LAN IP])</a>. Optional. Can only be set if disableMyMerakiCom is set to false
  name: string # The name of the new network
  --tags: string # A space-separated list of tags to be applied to the network
  --timeZone: string # The timezone of the network. For a list of allowed timezones, please see the 'TZ' column in the table in <a target='_blank' href='https://en.wikipedia.org/wiki/List_of_tz_database_time_zones'>this article.</a>
  type: string # The type of the new network. Valid types are wireless, appliance, switch, systemsManager, camera, cellularGateway, environmental, or a space-separated list of those for a combined network.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/networks")
  let body = {copyFromNetworkId: $copyFromNetworkId, disableMyMerakiCom: $disableMyMerakiCom, disableRemoteStatusPage: $disableRemoteStatusPage, name: $name, tags: $tags, timeZone: $timeZone, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Combine multiple networks into a single network
#
# POST /organizations/{organizationId}/networks/combine
# operationId: combineOrganizationNetworks
export def "organizations-networks-combine combineOrganizationNetworks" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enrollmentString: string # A unique identifier which can be used for device enrollment or easy access through the Meraki SM Registration page or the Self Service Portal. Please note that changing this field may cause existing bookmarks to break. All networks that are part of this combined network will have their enrollment string appended by '-network_type'. If left empty, all exisitng enrollment strings will be deleted.
  name: string # The name of the combined network
  networkIds: list # A list of the network IDs that will be combined. If an ID of a combined network is included in this list, the other networks in the list will be grouped into that network
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/networks/combine")
  let body = {enrollmentString: $enrollmentString, name: $name, networkIds: $networkIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the OpenAPI 2.0 Specification of the organization's API documentation in JSON
#
# GET /organizations/{organizationId}/openapiSpec
# operationId: getOrganizationOpenapiSpec
export def "organizations-openapi-spec get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/openapiSpec")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the SAML roles for this organization
#
# GET /organizations/{organizationId}/samlRoles
# operationId: getOrganizationSamlRoles
export def "organizations-saml-roles list" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/samlRoles")
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
export def "organizations-saml-roles createOrganizationSamlRole" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --networks: list # The list of networks that the SAML administrator has privileges on — item shape: {access: string, id: string}
  orgAccess: string # The privilege of the SAML administrator on the organization
  role: string # The role of the SAML administrator
  --tags: list # The list of tags that the SAML administrator has privleges on — item shape: {access: string, tag: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/samlRoles")
  let body = {networks: $networks, orgAccess: $orgAccess, role: $role, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return a SAML role
#
# GET /organizations/{organizationId}/samlRoles/{samlRoleId}
# operationId: getOrganizationSamlRole
export def "organizations-saml-roles get" [
  organizationId: string
  samlRoleId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/samlRoles/($samlRoleId)")
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
export def "organizations-saml-roles updateOrganizationSamlRole" [
  organizationId: string
  samlRoleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --networks: list # The list of networks that the SAML administrator has privileges on — item shape: {access: string, id: string}
  --orgAccess: string # The privilege of the SAML administrator on the organization
  --role: string # The role of the SAML administrator
  --tags: list # The list of tags that the SAML administrator has privleges on — item shape: {access: string, tag: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/samlRoles/($samlRoleId)")
  let body = {networks: $networks, orgAccess: $orgAccess, role: $role, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all supported intrusion settings for an organization
#
# GET /organizations/{organizationId}/security/intrusionSettings
# operationId: getOrganizationSecurityIntrusionSettings
export def "organizations-security-intrusion-settings get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/security/intrusionSettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets supported intrusion settings for an organization
#
# PUT /organizations/{organizationId}/security/intrusionSettings
# operationId: updateOrganizationSecurityIntrusionSettings
# --whitelistedRules item shape: {message?: string, ruleId: string}
export def "organizations-security-intrusion-settings updateOrganizationSecurityIntrusionSettings" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  whitelistedRules: list # Sets a list of specific SNORT signatures to allow — item shape: {message?: string, ruleId: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/security/intrusionSettings")
  let body = {whitelistedRules: $whitelistedRules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the security events (intrusion detection only) for an organization
#
# GET /organizations/{organizationId}/securityEvents
# operationId: getOrganizationSecurityEvents
export def "organizations-security-events get" [
  organizationId: string
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
  --perPage: int # The number of entries per page returned. Acceptable range is 3 - 1000. Default is 100.
  --startingAfter: string # A token used by the server to indicate the start of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
  --endingBefore: string # A token used by the server to indicate the end of the page. Often this is a timestamp or an ID but it is not limited to those. This parameter should not be defined by client applications. The link for the first, last, prev, or next page in the HTTP Link header should define it.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t0" $t0 "scalar") (serialize-qp "t1" $t1 "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "startingAfter" $startingAfter "scalar") (serialize-qp "endingBefore" $endingBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/securityEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the SNMP settings for an organization
#
# GET /organizations/{organizationId}/snmp
# operationId: getOrganizationSnmp
export def "organizations-snmp get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/snmp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the third party VPN peers for an organization
#
# GET /organizations/{organizationId}/thirdPartyVPNPeers
# operationId: getOrganizationThirdPartyVPNPeers
export def "organizations-third-party-vpn-peers get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/thirdPartyVPNPeers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the third party VPN peers for an organization
#
# PUT /organizations/{organizationId}/thirdPartyVPNPeers
# operationId: updateOrganizationThirdPartyVPNPeers
# --peers item shape: {ikeVersion?: "1"|"2", ipsecPolicies?: record, ipsecPoliciesPreset?: string, name: string, networkTags?: list, privateSubnets: list, publicIp: string, remoteId?: string, secret: string}
export def "organizations-third-party-vpn-peers updateOrganizationThirdPartyVPNPeers" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  peers: list # The list of VPN peers — item shape: {ikeVersion?: "1"|"2", ipsecPolicies?: record, ipsecPoliciesPreset?: string, name: string, networkTags?: list, privateSubnets: list, publicIp: string, remoteId?: string, secret: string}
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/thirdPartyVPNPeers")
  let body = {peers: $peers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return the uplink loss and latency for every MX in the organization from at latest 2 minutes ago
#
# GET /organizations/{organizationId}/uplinksLossAndLatency
# operationId: getOrganizationUplinksLossAndLatency
export def "organizations-uplinks-loss-and-latency get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/uplinksLossAndLatency" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the firewall rules for an organization's site-to-site VPN
#
# GET /organizations/{organizationId}/vpnFirewallRules
# operationId: getOrganizationVpnFirewallRules
export def "organizations-vpn-firewall-rules get" [
  organizationId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/vpnFirewallRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the firewall rules of an organization's site-to-site VPN
#
# PUT /organizations/{organizationId}/vpnFirewallRules
# operationId: updateOrganizationVpnFirewallRules
# --rules item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
export def "organizations-vpn-firewall-rules updateOrganizationVpnFirewallRules" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # An ordered array of the firewall rules (not including the default rule) — item shape: {comment?: string, destCidr: string, destPort?: string, policy: "allow"|"deny", protocol: "any"|"icmp"|"icmp6"|"tcp"|"udp", srcCidr: string, srcPort?: string, syslogEnabled?: bool}
  --syslogDefaultRule: oneof<nothing, bool> # Log the special default rule (boolean value - enable only if you've configured a syslog server) (optional)
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-cisco-meraki-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/vpnFirewallRules")
  let body = {rules: $rules, syslogDefaultRule: $syslogDefaultRule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
