# Auto-generated client for Amazon Location Service v2020-11-19
# Source: https://api.apis.guru/v2/specs/amazonaws.com/location/2020-11-19/openapi.json
# Auth: --token flag or $env.AMAZON_LOCATION_SERVICE_TOKEN

const BASE_URL = "http://geo.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_LOCATION_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://geo.us-east-1.amazonaws.com" "http://geo.us-east-2.amazonaws.com" "http://geo.us-west-1.amazonaws.com" "http://geo.us-west-2.amazonaws.com" "http://geo.us-gov-west-1.amazonaws.com" "http://geo.us-gov-east-1.amazonaws.com" "http://geo.ca-central-1.amazonaws.com" "http://geo.eu-north-1.amazonaws.com" "http://geo.eu-west-1.amazonaws.com" "http://geo.eu-west-2.amazonaws.com" "http://geo.eu-west-3.amazonaws.com" "http://geo.eu-central-1.amazonaws.com" "http://geo.eu-south-1.amazonaws.com" "http://geo.af-south-1.amazonaws.com" "http://geo.ap-northeast-1.amazonaws.com" "http://geo.ap-northeast-2.amazonaws.com" "http://geo.ap-northeast-3.amazonaws.com" "http://geo.ap-southeast-1.amazonaws.com" "http://geo.ap-southeast-2.amazonaws.com" "http://geo.ap-east-1.amazonaws.com" "http://geo.ap-south-1.amazonaws.com" "http://geo.sa-east-1.amazonaws.com" "http://geo.me-south-1.amazonaws.com" "https://geo.us-east-1.amazonaws.com" "https://geo.us-east-2.amazonaws.com" "https://geo.us-west-1.amazonaws.com" "https://geo.us-west-2.amazonaws.com" "https://geo.us-gov-west-1.amazonaws.com" "https://geo.us-gov-east-1.amazonaws.com" "https://geo.ca-central-1.amazonaws.com" "https://geo.eu-north-1.amazonaws.com" "https://geo.eu-west-1.amazonaws.com" "https://geo.eu-west-2.amazonaws.com" "https://geo.eu-west-3.amazonaws.com" "https://geo.eu-central-1.amazonaws.com" "https://geo.eu-south-1.amazonaws.com" "https://geo.af-south-1.amazonaws.com" "https://geo.ap-northeast-1.amazonaws.com" "https://geo.ap-northeast-2.amazonaws.com" "https://geo.ap-northeast-3.amazonaws.com" "https://geo.ap-southeast-1.amazonaws.com" "https://geo.ap-southeast-2.amazonaws.com" "https://geo.ap-east-1.amazonaws.com" "https://geo.ap-south-1.amazonaws.com" "https://geo.sa-east-1.amazonaws.com" "https://geo.me-south-1.amazonaws.com" "http://geo.cn-north-1.amazonaws.com.cn" "http://geo.cn-northwest-1.amazonaws.com.cn" "https://geo.cn-north-1.amazonaws.com.cn" "https://geo.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def distance-unit-completer [] { ["Kilometers" "Miles"] }
def travel-mode-completer [] { ["Bicycle" "Car" "Motorcycle" "Truck" "Walking"] }
def pricing-plan-completer [] { ["MobileAssetManagement" "MobileAssetTracking" "RequestBasedUsage"] }
def position-filtering-completer [] { ["AccuracyBased" "DistanceBased" "TimeBased"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "tracking-trackers-consumers create-associate" } } | get name | first)
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

# Creates an association between a geofence collection and a tracker resource. This allows the tracker resource to communicate location data to the linked geofence collection. You can associate up to five geofence collections to each tracker resource. Currently not supported — Cross-account configurations, such as creating associations between a tracker resource in one account and a geofence collection in another account.
#
# POST /tracking/v0/trackers/{TrackerName}/consumers
# operationId: AssociateTrackerConsumer
export def "tracking-trackers-consumers create-associate" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  consumer_arn: string # The Amazon Resource Name (ARN) for the geofence collection to be associated to tracker resource. Used when you need to specify a resource across all Amazon Web Services. Format example: arn:aws:geo:region:account-id:geofence-collection/ExampleGeofenceCollectionConsumer
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}/consumers"))
  let req_body = {"ConsumerArn": $consumer_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the position history of one or more devices from a tracker resource.
#
# POST /tracking/v0/trackers/{TrackerName}/delete-positions
# operationId: BatchDeleteDevicePositionHistory
export def "tracking-trackers-delete-positions delete-batch-device-history" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  device_ids: list<string> # Devices whose position history you want to delete. For example, for two devices: “DeviceIds” : [DeviceId1,DeviceId2]
]: any -> record<Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}/delete-positions"))
  let req_body = {"DeviceIds": $device_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a batch of geofences from a geofence collection. This operation deletes the resource permanently.
#
# POST /geofencing/v0/collections/{CollectionName}/delete-geofences
# operationId: BatchDeleteGeofence
export def "geofencing-collections-delete-geofences delete-batch" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  geofence_ids: list<string> # The batch of geofences to be deleted.
]: any -> record<Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name)} | format pattern "/geofencing/v0/collections/{collection_name}/delete-geofences"))
  let req_body = {"GeofenceIds": $geofence_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Evaluates device positions against the geofence geometries from a given geofence collection. This operation always returns an empty response because geofences are asynchronously evaluated. The evaluation determines if the device has entered or exited a geofenced area, and then publishes one of the following events to Amazon EventBridge: ENTER if Amazon Location determines that the tracked device has entered a geofenced area. EXIT if Amazon Location determines that the tracked device has exited a geofenced area. The last geofence that a device was observed within is tracked for 30 days after the most recent device position update. Geofence evaluation uses the given device position. It does not account for the optional Accuracy of a DevicePositionUpdate. The DeviceID is used as a string to represent the device. You do not need to have a Tracker associated with the DeviceID.
#
# POST /geofencing/v0/collections/{CollectionName}/positions
# operationId: BatchEvaluateGeofences
# --DevicePositionUpdates item shape: {Accuracy?: any, DeviceId: any, Position: any, PositionProperties?: any, SampleTime: any}
export def "geofencing-collections-positions create-batch-evaluate-geofences" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  device_position_updates: list # Contains device details for each device to be evaluated against the given geofence collection. — item shape: {Accuracy?: any, DeviceId: any, Position: any, PositionProperties?: any, SampleTime: any}
]: any -> record<Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name)} | format pattern "/geofencing/v0/collections/{collection_name}/positions"))
  let req_body = {"DevicePositionUpdates": $device_position_updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the latest device positions for requested devices.
#
# POST /tracking/v0/trackers/{TrackerName}/get-positions
# operationId: BatchGetDevicePosition
export def "tracking-trackers-get-positions get-batch-device" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  device_ids: list<string> # Devices whose position you want to retrieve. For example, for two devices: device-ids=DeviceId1&device-ids=DeviceId2
]: any -> record<DevicePositions: record, Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}/get-positions"))
  let req_body = {"DeviceIds": $device_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# A batch request for storing geofence geometries into a given geofence collection, or updates the geometry of an existing geofence if a geofence ID is included in the request.
#
# POST /geofencing/v0/collections/{CollectionName}/put-geofences
# operationId: BatchPutGeofence
# --Entries item shape: {GeofenceId: any, Geometry: any}
export def "geofencing-collections-put-geofences update-batch" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  entries: list # The batch of geofences to be stored in a geofence collection. — item shape: {GeofenceId: any, Geometry: any}
]: any -> record<Errors: record, Successes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name)} | format pattern "/geofencing/v0/collections/{collection_name}/put-geofences"))
  let req_body = {"Entries": $entries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Uploads position update data for one or more devices to a tracker resource. Amazon Location uses the data when it reports the last known device position and position history. Amazon Location retains location data for 30 days. Position updates are handled based on the PositionFiltering property of the tracker. When PositionFiltering is set to TimeBased, updates are evaluated against linked geofence collections, and location data is stored at a maximum of one position per 30 second interval. If your update frequency is more often than every 30 seconds, only one update per 30 seconds is stored for each unique device ID. When PositionFiltering is set to DistanceBased filtering, location data is stored and evaluated against linked geofence collections only if the device has moved more than 30 m (98.4 ft). When PositionFiltering is set to AccuracyBased filtering, location data is stored and evaluated against linked geofence collections only if the device has moved more than the measured accuracy. For example, if two consecutive updates from a device have a horizontal accuracy of 5 m and 10 m, the second update is neither stored or evaluated if the device has moved less than 15 m. If PositionFiltering is set to AccuracyBased filtering, Amazon Location uses the default value { "Horizontal": 0} when accuracy is not provided on a DevicePositionUpdate.
#
# POST /tracking/v0/trackers/{TrackerName}/positions
# operationId: BatchUpdateDevicePosition
# --Updates item shape: {Accuracy?: any, DeviceId: any, Position: any, PositionProperties?: any, SampleTime: any}
export def "tracking-trackers-positions update-batch-device" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  updates: list # Contains the position update details for each device. — item shape: {Accuracy?: any, DeviceId: any, Position: any, PositionProperties?: any, SampleTime: any}
]: any -> record<Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}/positions"))
  let req_body = {"Updates": $updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Calculates a route (https://docs.aws.amazon.com/location/latest/developerguide/calculate-route.html) given the following required parameters: DeparturePosition and DestinationPosition. Requires that you first create a route calculator resource (https://docs.aws.amazon.com/location-routes/latest/APIReference/API_CreateRouteCalculator.html). By default, a request that doesn't specify a departure time uses the best time of day to travel with the best traffic conditions when calculating the route. Additional options include: Specifying a departure time (https://docs.aws.amazon.com/location/latest/developerguide/departure-time.html) using either DepartureTime or DepartNow. This calculates a route based on predictive traffic data at the given time. You can't specify both DepartureTime and DepartNow in a single request. Specifying both parameters returns a validation error. Specifying a travel mode (https://docs.aws.amazon.com/location/latest/developerguide/travel-mode.html) using TravelMode sets the transportation mode used to calculate the routes. This also lets you specify additional route preferences in CarModeOptions if traveling by Car, or TruckModeOptions if traveling by Truck. If you specify walking for the travel mode and your data provider is Esri, the start and destination must be within 40km.
#
# POST /routes/v0/calculators/{CalculatorName}/calculate/route
# operationId: CalculateRoute
# --CarModeOptions shape: {AvoidFerries?: any, AvoidTolls?: any}
# --TruckModeOptions shape: {AvoidFerries?: any, AvoidTolls?: any, Dimensions?: any, Weight?: any}
export def "routes-calculators-calculate-route create" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --car-mode-options: record # Contains details about additional route preferences for requests that specify TravelMode as Car. — shape: {AvoidFerries?: any, AvoidTolls?: any}
  --depart-now: oneof<nothing, bool> # Sets the time of departure as the current time. Uses the current time to calculate a route. Otherwise, the best time of day to travel with the best traffic conditions is used to calculate the route. Default Value: false Valid Values: false | true
  departure_position: list<float> # The start position for the route. Defined in World Geodetic System (WGS 84) (https://earth-info.nga.mil/index.php?dir=wgs84&action=wgs84) format: [longitude, latitude]. For example, [-123.115, 49.285] If you specify a departure that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). If Esri is the provider for your route calculator, specifying a route that is longer than 400 km returns a 400 RoutesValidationException error. Valid Values: [-180 to 180,-90 to 90]
  --departure-time: string # Specifies the desired time of departure. Uses the given time to calculate the route. Otherwise, the best time of day to travel with the best traffic conditions is used to calculate the route. Setting a departure time in the past returns a 400 ValidationException error. In ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. For example, 2020–07-2T12:15:20.000Z+01:00 (format: date-time)
  destination_position: list<float> # The finish position for the route. Defined in World Geodetic System (WGS 84) (https://earth-info.nga.mil/index.php?dir=wgs84&action=wgs84) format: [longitude, latitude]. For example, [-122.339, 47.615] If you specify a destination that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). Valid Values: [-180 to 180,-90 to 90]
  --distance-unit: string@distance-unit-completer # Set the unit system to specify the distance. Default Value: Kilometers
  --include-leg-geometry: oneof<nothing, bool> # Set to include the geometry details in the result for each path between a pair of positions. Default Value: false Valid Values: false | true
  --travel-mode: string@travel-mode-completer # Specifies the mode of transport when calculating a route. Used in estimating the speed of travel and road compatibility. You can choose Car, Truck, Walking, Bicycle or Motorcycle as options for the TravelMode. Bicycle and Motorcycle are only valid when using Grab as a data provider, and only within Southeast Asia. Truck is not available for Grab. For more details on the using Grab for routing, including areas of coverage, see GrabMaps (https://docs.aws.amazon.com/location/latest/developerguide/grab.html) in the Amazon Location Service Developer Guide. The TravelMode you specify also determines how you specify route preferences: If traveling by Car use the CarModeOptions parameter. If traveling by Truck use the TruckModeOptions parameter. Default Value: Car
  --truck-mode-options: record # Contains details about additional route preferences for requests that specify TravelMode as Truck. — shape: {AvoidFerries?: any, AvoidTolls?: any, Dimensions?: any, Weight?: any}
  --waypoint-positions: list # Specifies an ordered list of up to 23 intermediate positions to include along a route between the departure position and destination position. For example, from the DeparturePosition [-123.115, 49.285], the route follows the order that the waypoint positions are given [[-122.757, 49.0021],[-122.349, 47.620]] If you specify a waypoint position that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). Specifying more than 23 waypoints returns a 400 ValidationException error. If Esri is the provider for your route calculator, specifying a route that is longer than 400 km returns a 400 RoutesValidationException error. Valid Values: [-180 to 180,-90 to 90]
]: any -> record<Legs: record, Summary: record<DataSource: record, Distance: record, DistanceUnit: record, DurationSeconds: record, RouteBBox: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calculator_name | is-empty) { error make --unspanned { msg: "path parameter 'CalculatorName' must be non-empty" } }
  let full_url = (build-url $base ({calculator_name: (encode-path-segment $calculator_name)} | format pattern "/routes/v0/calculators/{calculator_name}/calculate/route"))
  let req_body = {"CarModeOptions": $car_mode_options, "DepartNow": $depart_now, "DeparturePosition": $departure_position, "DepartureTime": $departure_time, "DestinationPosition": $destination_position, "DistanceUnit": $distance_unit, "IncludeLegGeometry": $include_leg_geometry, "TravelMode": $travel_mode, "TruckModeOptions": $truck_mode_options, "WaypointPositions": $waypoint_positions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Calculates a route matrix (https://docs.aws.amazon.com/location/latest/developerguide/calculate-route-matrix.html) given the following required parameters: DeparturePositions and DestinationPositions. CalculateRouteMatrix calculates routes and returns the travel time and travel distance from each departure position to each destination position in the request. For example, given departure positions A and B, and destination positions X and Y, CalculateRouteMatrix will return time and distance for routes from A to X, A to Y, B to X, and B to Y (in that order). The number of results returned (and routes calculated) will be the number of DeparturePositions times the number of DestinationPositions. Your account is charged for each route calculated, not the number of requests. Requires that you first create a route calculator resource (https://docs.aws.amazon.com/location-routes/latest/APIReference/API_CreateRouteCalculator.html). By default, a request that doesn't specify a departure time uses the best time of day to travel with the best traffic conditions when calculating routes. Additional options include: Specifying a departure time (https://docs.aws.amazon.com/location/latest/developerguide/departure-time.html) using either DepartureTime or DepartNow. This calculates routes based on predictive traffic data at the given time. You can't specify both DepartureTime and DepartNow in a single request. Specifying both parameters returns a validation error. Specifying a travel mode (https://docs.aws.amazon.com/location/latest/developerguide/travel-mode.html) using TravelMode sets the transportation mode used to calculate the routes. This also lets you specify additional route preferences in CarModeOptions if traveling by Car, or TruckModeOptions if traveling by Truck.
#
# POST /routes/v0/calculators/{CalculatorName}/calculate/route-matrix
# operationId: CalculateRouteMatrix
# --CarModeOptions shape: {AvoidFerries?: any, AvoidTolls?: any}
# --TruckModeOptions shape: {AvoidFerries?: any, AvoidTolls?: any, Dimensions?: any, Weight?: any}
export def "routes-calculators-calculate-route-matrix create" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --car-mode-options: record # Contains details about additional route preferences for requests that specify TravelMode as Car. — shape: {AvoidFerries?: any, AvoidTolls?: any}
  --depart-now: oneof<nothing, bool> # Sets the time of departure as the current time. Uses the current time to calculate the route matrix. You can't set both DepartureTime and DepartNow. If neither is set, the best time of day to travel with the best traffic conditions is used to calculate the route matrix. Default Value: false Valid Values: false | true
  departure_positions: list # The list of departure (origin) positions for the route matrix. An array of points, each of which is itself a 2-value array defined in WGS 84 (https://earth-info.nga.mil/GandG/wgs84/index.html) format: [longitude, latitude]. For example, [-123.115, 49.285]. Depending on the data provider selected in the route calculator resource there may be additional restrictions on the inputs you can choose. See Position restrictions (https://docs.aws.amazon.com/location/latest/developerguide/calculate-route-matrix.html#matrix-routing-position-limits) in the Amazon Location Service Developer Guide. For route calculators that use Esri as the data provider, if you specify a departure that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). The snapped value is available in the result in SnappedDeparturePositions. Valid Values: [-180 to 180,-90 to 90]
  --departure-time: string # Specifies the desired time of departure. Uses the given time to calculate the route matrix. You can't set both DepartureTime and DepartNow. If neither is set, the best time of day to travel with the best traffic conditions is used to calculate the route matrix. Setting a departure time in the past returns a 400 ValidationException error. In ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. For example, 2020–07-2T12:15:20.000Z+01:00 (format: date-time)
  destination_positions: list # The list of destination positions for the route matrix. An array of points, each of which is itself a 2-value array defined in WGS 84 (https://earth-info.nga.mil/GandG/wgs84/index.html) format: [longitude, latitude]. For example, [-122.339, 47.615] Depending on the data provider selected in the route calculator resource there may be additional restrictions on the inputs you can choose. See Position restrictions (https://docs.aws.amazon.com/location/latest/developerguide/calculate-route-matrix.html#matrix-routing-position-limits) in the Amazon Location Service Developer Guide. For route calculators that use Esri as the data provider, if you specify a destination that's not located on a road, Amazon Location moves the position to the nearest road (https://docs.aws.amazon.com/location/latest/developerguide/snap-to-nearby-road.html). The snapped value is available in the result in SnappedDestinationPositions. Valid Values: [-180 to 180,-90 to 90]
  --distance-unit: string@distance-unit-completer # Set the unit system to specify the distance. Default Value: Kilometers
  --travel-mode: string@travel-mode-completer # Specifies the mode of transport when calculating a route. Used in estimating the speed of travel and road compatibility. The TravelMode you specify also determines how you specify route preferences: If traveling by Car use the CarModeOptions parameter. If traveling by Truck use the TruckModeOptions parameter. Bicycle or Motorcycle are only valid when using Grab as a data provider, and only within Southeast Asia. Truck is not available for Grab. For more information about using Grab as a data provider, see GrabMaps (https://docs.aws.amazon.com/location/latest/developerguide/grab.html) in the Amazon Location Service Developer Guide. Default Value: Car
  --truck-mode-options: record # Contains details about additional route preferences for requests that specify TravelMode as Truck. — shape: {AvoidFerries?: any, AvoidTolls?: any, Dimensions?: any, Weight?: any}
]: any -> record<RouteMatrix: record, SnappedDeparturePositions: record, SnappedDestinationPositions: record, Summary: record<DataSource: record, DistanceUnit: record, ErrorCount: record, RouteCount: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calculator_name | is-empty) { error make --unspanned { msg: "path parameter 'CalculatorName' must be non-empty" } }
  let full_url = (build-url $base ({calculator_name: (encode-path-segment $calculator_name)} | format pattern "/routes/v0/calculators/{calculator_name}/calculate/route-matrix"))
  let req_body = {"CarModeOptions": $car_mode_options, "DepartNow": $depart_now, "DeparturePositions": $departure_positions, "DepartureTime": $departure_time, "DestinationPositions": $destination_positions, "DistanceUnit": $distance_unit, "TravelMode": $travel_mode, "TruckModeOptions": $truck_mode_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a geofence collection, which manages and stores geofences.
#
# POST /geofencing/v0/collections
# operationId: CreateGeofenceCollection
export def "geofencing-collections create-geofence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  collection_name: string # A custom name for the geofence collection. Requirements: Contain only alphanumeric characters (A–Z, a–z, 0–9), hyphens (-), periods (.), and underscores (_). Must be a unique geofence collection name. No spaces allowed. For example, ExampleGeofenceCollection.
  --description: string # An optional description for the geofence collection.
  --kms-key-id: string # A key identifier for an Amazon Web Services KMS customer managed key (https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html). Enter a key ID, key ARN, alias name, or alias ARN.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --pricing-plan-data-source: string # This parameter is no longer used.
  --tags: record # Applies one or more tags to the geofence collection. A tag is a key-value pair helps manage, identify, search, and filter your resources by labelling them. Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
]: any -> record<CollectionArn: record, CollectionName: record, CreateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geofencing/v0/collections")
  let req_body = {"CollectionName": $collection_name, "Description": $description, "KmsKeyId": $kms_key_id, "PricingPlan": $pricing_plan, "PricingPlanDataSource": $pricing_plan_data_source, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates an API key resource in your Amazon Web Services account, which lets you grant geo:GetMap* actions for Amazon Location Map resources to the API key bearer. The API keys feature is in preview. We may add, change, or remove features before announcing general availability. For more information, see Using API keys (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html).
#
# POST /metadata/v0/keys
# operationId: CreateKey
# --Restrictions shape: {AllowActions?: any, AllowReferers?: any, AllowResources?: any}
export def "metadata-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # An optional description for the API key resource.
  --expire-time: string # The optional timestamp for when the API key resource will expire in ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. One of NoExpiry or ExpireTime must be set. (format: date-time)
  key_name: string # A custom name for the API key resource. Requirements: Contain only alphanumeric characters (A–Z, a–z, 0–9), hyphens (-), periods (.), and underscores (_). Must be a unique API key name. No spaces allowed. For example, ExampleAPIKey.
  --no-expiry: oneof<nothing, bool> # Optionally set to true to set no expiration time for the API key. One of NoExpiry or ExpireTime must be set.
  restrictions: record # API Restrictions on the allowed actions, resources, and referers for an API key resource. — shape: {AllowActions?: any, AllowReferers?: any, AllowResources?: any}
  --tags: record # Applies one or more tags to the map resource. A tag is a key-value pair that helps manage, identify, search, and filter your resources by labelling them. Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
]: any -> record<CreateTime: record, Key: record, KeyArn: record, KeyName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata/v0/keys")
  let req_body = {"Description": $description, "ExpireTime": $expire_time, "KeyName": $key_name, "NoExpiry": $no_expiry, "Restrictions": $restrictions, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a map resource in your Amazon Web Services account, which provides map tiles of different styles sourced from global location data providers. If your application is tracking or routing assets you use in your business, such as delivery vehicles or employees, you must not use Esri as your geolocation provider. See section 82 of the Amazon Web Services service terms (http://aws.amazon.com/service-terms) for more details.
#
# POST /maps/v0/maps
# operationId: CreateMap
# --Configuration shape: {Style?: any}
export def "maps-maps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  configuration: record # Specifies the map tile style selected from an available provider. — shape: {Style?: any}
  --description: string # An optional description for the map resource.
  map_name: string # The name for the map resource. Requirements: Must contain only alphanumeric characters (A–Z, a–z, 0–9), hyphens (-), periods (.), and underscores (_). Must be a unique map resource name. No spaces allowed. For example, ExampleMap.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --tags: record # Applies one or more tags to the map resource. A tag is a key-value pair helps manage, identify, search, and filter your resources by labelling them. Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
]: any -> record<CreateTime: record, MapArn: record, MapName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/maps/v0/maps")
  let req_body = {"Configuration": $configuration, "Description": $description, "MapName": $map_name, "PricingPlan": $pricing_plan, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a place index resource in your Amazon Web Services account. Use a place index resource to geocode addresses and other text queries by using the SearchPlaceIndexForText operation, and reverse geocode coordinates by using the SearchPlaceIndexForPosition operation, and enable autosuggestions by using the SearchPlaceIndexForSuggestions operation. If your application is tracking or routing assets you use in your business, such as delivery vehicles or employees, you must not use Esri as your geolocation provider. See section 82 of the Amazon Web Services service terms (http://aws.amazon.com/service-terms) for more details.
#
# POST /places/v0/indexes
# operationId: CreatePlaceIndex
# --DataSourceConfiguration shape: {IntendedUse?: any}
export def "places-indexes create-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  data_source: string # Specifies the geospatial data provider for the new place index. This field is case-sensitive. Enter the valid values as shown. For example, entering HERE returns an error. Valid values include: Esri – For additional information about Esri (https://docs.aws.amazon.com/location/latest/developerguide/esri.html)'s coverage in your region of interest, see Esri details on geocoding coverage (https://developers.arcgis.com/rest/geocode/api-reference/geocode-coverage.htm). Grab – Grab provides place index functionality for Southeast Asia. For additional information about GrabMaps (https://docs.aws.amazon.com/location/latest/developerguide/grab.html)' coverage, see GrabMaps countries and areas covered (https://docs.aws.amazon.com/location/latest/developerguide/grab.html#grab-coverage-area). Here – For additional information about HERE Technologies (https://docs.aws.amazon.com/location/latest/developerguide/HERE.html)' coverage in your region of interest, see HERE details on goecoding coverage (https://developer.here.com/documentation/geocoder/dev_guide/topics/coverage-geocoder.html). If you specify HERE Technologies (Here) as the data provider, you may not store results (https://docs.aws.amazon.com/location-places/latest/APIReference/API_DataSourceConfiguration.html) for locations in Japan. For more information, see the Amazon Web Services Service Terms (http://aws.amazon.com/service-terms/) for Amazon Location Service. For additional information , see Data providers (https://docs.aws.amazon.com/location/latest/developerguide/what-is-data-provider.html) on the Amazon Location Service Developer Guide.
  --data-source-configuration: record # Specifies the data storage option chosen for requesting Places. When using Amazon Location Places: If using HERE Technologies as a data provider, you can't store results for locations in Japan by setting IntendedUse to Storage. parameter. Under the MobileAssetTracking or MobilAssetManagement pricing plan, you can't store results from your place index resources by setting IntendedUse to Storage. This returns a validation exception error. For more information, see the AWS Service Terms (https://aws.amazon.com/service-terms/) for Amazon Location Service. — shape: {IntendedUse?: any}
  --description: string # The optional description for the place index resource.
  index_name: string # The name of the place index resource. Requirements: Contain only alphanumeric characters (A–Z, a–z, 0–9), hyphens (-), periods (.), and underscores (_). Must be a unique place index resource name. No spaces allowed. For example, ExamplePlaceIndex.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --tags: record # Applies one or more tags to the place index resource. A tag is a key-value pair that helps you manage, identify, search, and filter your resources. Format: "key" : "value" Restrictions: Maximum 50 tags per resource. Each tag key must be unique and must have exactly one associated value. Maximum key length: 128 Unicode characters in UTF-8. Maximum value length: 256 Unicode characters in UTF-8. Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @ Cannot use "aws:" as a prefix for a key.
]: any -> record<CreateTime: record, IndexArn: record, IndexName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/places/v0/indexes")
  let req_body = {"DataSource": $data_source, "DataSourceConfiguration": $data_source_configuration, "Description": $description, "IndexName": $index_name, "PricingPlan": $pricing_plan, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a route calculator resource in your Amazon Web Services account. You can send requests to a route calculator resource to estimate travel time, distance, and get directions. A route calculator sources traffic and road network data from your chosen data provider. If your application is tracking or routing assets you use in your business, such as delivery vehicles or employees, you must not use Esri as your geolocation provider. See section 82 of the Amazon Web Services service terms (http://aws.amazon.com/service-terms) for more details.
#
# POST /routes/v0/calculators
# operationId: CreateRouteCalculator
export def "routes-calculators create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  calculator_name: string # The name of the route calculator resource. Requirements: Can use alphanumeric characters (A–Z, a–z, 0–9) , hyphens (-), periods (.), and underscores (_). Must be a unique Route calculator resource name. No spaces allowed. For example, ExampleRouteCalculator.
  data_source: string # Specifies the data provider of traffic and road network data. This field is case-sensitive. Enter the valid values as shown. For example, entering HERE returns an error. Valid values include: Esri – For additional information about Esri (https://docs.aws.amazon.com/location/latest/developerguide/esri.html)'s coverage in your region of interest, see Esri details on street networks and traffic coverage (https://doc.arcgis.com/en/arcgis-online/reference/network-coverage.htm). Route calculators that use Esri as a data source only calculate routes that are shorter than 400 km. Grab – Grab provides routing functionality for Southeast Asia. For additional information about GrabMaps (https://docs.aws.amazon.com/location/latest/developerguide/grab.html)' coverage, see GrabMaps countries and areas covered (https://docs.aws.amazon.com/location/latest/developerguide/grab.html#grab-coverage-area). Here – For additional information about HERE Technologies (https://docs.aws.amazon.com/location/latest/developerguide/HERE.html)' coverage in your region of interest, see HERE car routing coverage (https://developer.here.com/documentation/routing-api/dev_guide/topics/coverage/car-routing.html) and HERE truck routing coverage (https://developer.here.com/documentation/routing-api/dev_guide/topics/coverage/truck-routing.html). For additional information , see Data providers (https://docs.aws.amazon.com/location/latest/developerguide/what-is-data-provider.html) on the Amazon Location Service Developer Guide.
  --description: string # The optional description for the route calculator resource.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --tags: record # Applies one or more tags to the route calculator resource. A tag is a key-value pair helps manage, identify, search, and filter your resources by labelling them. For example: { "tag1" : "value1", "tag2" : "value2"} Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
]: any -> record<CalculatorArn: record, CalculatorName: record, CreateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/routes/v0/calculators")
  let req_body = {"CalculatorName": $calculator_name, "DataSource": $data_source, "Description": $description, "PricingPlan": $pricing_plan, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a tracker resource in your Amazon Web Services account, which lets you retrieve current and historical location of devices.
#
# POST /tracking/v0/trackers
# operationId: CreateTracker
export def "tracking-trackers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # An optional description for the tracker resource.
  --kms-key-id: string # A key identifier for an Amazon Web Services KMS customer managed key (https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html). Enter a key ID, key ARN, alias name, or alias ARN.
  --position-filtering: string@position-filtering-completer # Specifies the position filtering for the tracker resource. Valid values: TimeBased - Location updates are evaluated against linked geofence collections, but not every location update is stored. If your update frequency is more often than 30 seconds, only one update per 30 seconds is stored for each unique device ID. DistanceBased - If the device has moved less than 30 m (98.4 ft), location updates are ignored. Location updates within this area are neither evaluated against linked geofence collections, nor stored. This helps control costs by reducing the number of geofence evaluations and historical device positions to paginate through. Distance-based filtering can also reduce the effects of GPS noise when displaying device trajectories on a map. AccuracyBased - If the device has moved less than the measured accuracy, location updates are ignored. For example, if two consecutive updates from a device have a horizontal accuracy of 5 m and 10 m, the second update is ignored if the device has moved less than 15 m. Ignored location updates are neither evaluated against linked geofence collections, nor stored. This can reduce the effects of GPS noise when displaying device trajectories on a map, and can help control your costs by reducing the number of geofence evaluations. This field is optional. If not specified, the default value is TimeBased.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --pricing-plan-data-source: string # This parameter is no longer used.
  --tags: record # Applies one or more tags to the tracker resource. A tag is a key-value pair helps manage, identify, search, and filter your resources by labelling them. Format: "key" : "value" Restrictions: Maximum 50 tags per resource Each resource tag must be unique with a maximum of one value. Maximum key length: 128 Unicode characters in UTF-8 Maximum value length: 256 Unicode characters in UTF-8 Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @. Cannot use "aws:" as a prefix for a key.
  tracker_name: string # The name for the tracker resource. Requirements: Contain only alphanumeric characters (A-Z, a-z, 0-9) , hyphens (-), periods (.), and underscores (_). Must be a unique tracker resource name. No spaces allowed. For example, ExampleTracker.
]: any -> record<CreateTime: record, TrackerArn: record, TrackerName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tracking/v0/trackers")
  let req_body = {"Description": $description, "KmsKeyId": $kms_key_id, "PositionFiltering": $position_filtering, "PricingPlan": $pricing_plan, "PricingPlanDataSource": $pricing_plan_data_source, "Tags": $tags, "TrackerName": $tracker_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a geofence collection from your Amazon Web Services account. This operation deletes the resource permanently. If the geofence collection is the target of a tracker resource, the devices will no longer be monitored.
#
# DELETE /geofencing/v0/collections/{CollectionName}
# operationId: DeleteGeofenceCollection
export def "geofencing-collections delete-geofence" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name)} | format pattern "/geofencing/v0/collections/{collection_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the geofence collection details.
#
# GET /geofencing/v0/collections/{CollectionName}
# operationId: DescribeGeofenceCollection
export def "geofencing-collections get-geofence" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CollectionArn: record, CollectionName: record, CreateTime: record, Description: record, KmsKeyId: record, PricingPlan: record, PricingPlanDataSource: record, Tags: record, UpdateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name)} | format pattern "/geofencing/v0/collections/{collection_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the specified properties of a given geofence collection.
#
# PATCH /geofencing/v0/collections/{CollectionName}
# operationId: UpdateGeofenceCollection
export def "geofencing-collections update-geofence" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the geofence collection.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --pricing-plan-data-source: string # This parameter is no longer used.
]: any -> record<CollectionArn: record, CollectionName: record, UpdateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name)} | format pattern "/geofencing/v0/collections/{collection_name}"))
  let req_body = {"Description": $description, "PricingPlan": $pricing_plan, "PricingPlanDataSource": $pricing_plan_data_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the specified API key. The API key must have been deactivated more than 90 days previously.
#
# DELETE /metadata/v0/keys/{KeyName}
# operationId: DeleteKey
export def "metadata-keys delete" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'KeyName' must be non-empty" } }
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/metadata/v0/keys/{key_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the API key resource details. The API keys feature is in preview. We may add, change, or remove features before announcing general availability. For more information, see Using API keys (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html).
#
# GET /metadata/v0/keys/{KeyName}
# operationId: DescribeKey
export def "metadata-keys get" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CreateTime: record, Description: record, ExpireTime: record, Key: record, KeyArn: record, KeyName: record, Restrictions: record<AllowActions: record, AllowReferers: record, AllowResources: record>, Tags: record, UpdateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'KeyName' must be non-empty" } }
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/metadata/v0/keys/{key_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the specified properties of a given API key resource. The API keys feature is in preview. We may add, change, or remove features before announcing general availability. For more information, see Using API keys (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html).
#
# PATCH /metadata/v0/keys/{KeyName}
# operationId: UpdateKey
# --Restrictions shape: {AllowActions?: any, AllowReferers?: any, AllowResources?: any}
export def "metadata-keys update" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the API key resource.
  --expire-time: string # Updates the timestamp for when the API key resource will expire in ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. (format: date-time)
  --force-update: oneof<nothing, bool> # The boolean flag to be included for updating ExpireTime or Restrictions details. Must be set to true to update an API key resource that has been used in the past 7 days. False if force update is not preferred Default value: False
  --no-expiry: oneof<nothing, bool> # Whether the API key should expire. Set to true to set the API key to have no expiration time.
  --restrictions: record # API Restrictions on the allowed actions, resources, and referers for an API key resource. — shape: {AllowActions?: any, AllowReferers?: any, AllowResources?: any}
]: any -> record<KeyArn: record, KeyName: record, UpdateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'KeyName' must be non-empty" } }
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/metadata/v0/keys/{key_name}"))
  let req_body = {"Description": $description, "ExpireTime": $expire_time, "ForceUpdate": $force_update, "NoExpiry": $no_expiry, "Restrictions": $restrictions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a map resource from your Amazon Web Services account. This operation deletes the resource permanently. If the map is being used in an application, the map may not render.
#
# DELETE /maps/v0/maps/{MapName}
# operationId: DeleteMap
export def "maps-maps delete" [
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'MapName' must be non-empty" } }
  let full_url = (build-url $base ({map_name: (encode-path-segment $map_name)} | format pattern "/maps/v0/maps/{map_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the map resource details.
#
# GET /maps/v0/maps/{MapName}
# operationId: DescribeMap
export def "maps-maps get" [
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Configuration: record<Style: record>, CreateTime: record, DataSource: record, Description: record, MapArn: record, MapName: record, PricingPlan: record, Tags: record, UpdateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'MapName' must be non-empty" } }
  let full_url = (build-url $base ({map_name: (encode-path-segment $map_name)} | format pattern "/maps/v0/maps/{map_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the specified properties of a given map resource.
#
# PATCH /maps/v0/maps/{MapName}
# operationId: UpdateMap
export def "maps-maps update" [
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the map resource.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
]: any -> record<MapArn: record, MapName: record, UpdateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'MapName' must be non-empty" } }
  let full_url = (build-url $base ({map_name: (encode-path-segment $map_name)} | format pattern "/maps/v0/maps/{map_name}"))
  let req_body = {"Description": $description, "PricingPlan": $pricing_plan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a place index resource from your Amazon Web Services account. This operation deletes the resource permanently.
#
# DELETE /places/v0/indexes/{IndexName}
# operationId: DeletePlaceIndex
export def "places-indexes delete-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'IndexName' must be non-empty" } }
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/places/v0/indexes/{index_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the place index resource details.
#
# GET /places/v0/indexes/{IndexName}
# operationId: DescribePlaceIndex
export def "places-indexes get-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CreateTime: record, DataSource: record, DataSourceConfiguration: record<IntendedUse: record>, Description: record, IndexArn: record, IndexName: record, PricingPlan: record, Tags: record, UpdateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'IndexName' must be non-empty" } }
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/places/v0/indexes/{index_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the specified properties of a given place index resource.
#
# PATCH /places/v0/indexes/{IndexName}
# operationId: UpdatePlaceIndex
# --DataSourceConfiguration shape: {IntendedUse?: any}
export def "places-indexes update-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --data-source-configuration: record # Specifies the data storage option chosen for requesting Places. When using Amazon Location Places: If using HERE Technologies as a data provider, you can't store results for locations in Japan by setting IntendedUse to Storage. parameter. Under the MobileAssetTracking or MobilAssetManagement pricing plan, you can't store results from your place index resources by setting IntendedUse to Storage. This returns a validation exception error. For more information, see the AWS Service Terms (https://aws.amazon.com/service-terms/) for Amazon Location Service. — shape: {IntendedUse?: any}
  --description: string # Updates the description for the place index resource.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
]: any -> record<IndexArn: record, IndexName: record, UpdateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'IndexName' must be non-empty" } }
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/places/v0/indexes/{index_name}"))
  let req_body = {"DataSourceConfiguration": $data_source_configuration, "Description": $description, "PricingPlan": $pricing_plan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a route calculator resource from your Amazon Web Services account. This operation deletes the resource permanently.
#
# DELETE /routes/v0/calculators/{CalculatorName}
# operationId: DeleteRouteCalculator
export def "routes-calculators delete" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calculator_name | is-empty) { error make --unspanned { msg: "path parameter 'CalculatorName' must be non-empty" } }
  let full_url = (build-url $base ({calculator_name: (encode-path-segment $calculator_name)} | format pattern "/routes/v0/calculators/{calculator_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the route calculator resource details.
#
# GET /routes/v0/calculators/{CalculatorName}
# operationId: DescribeRouteCalculator
export def "routes-calculators get" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CalculatorArn: record, CalculatorName: record, CreateTime: record, DataSource: record, Description: record, PricingPlan: record, Tags: record, UpdateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calculator_name | is-empty) { error make --unspanned { msg: "path parameter 'CalculatorName' must be non-empty" } }
  let full_url = (build-url $base ({calculator_name: (encode-path-segment $calculator_name)} | format pattern "/routes/v0/calculators/{calculator_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the specified properties for a given route calculator resource.
#
# PATCH /routes/v0/calculators/{CalculatorName}
# operationId: UpdateRouteCalculator
export def "routes-calculators update" [
  calculator_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the route calculator resource.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
]: any -> record<CalculatorArn: record, CalculatorName: record, UpdateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($calculator_name | is-empty) { error make --unspanned { msg: "path parameter 'CalculatorName' must be non-empty" } }
  let full_url = (build-url $base ({calculator_name: (encode-path-segment $calculator_name)} | format pattern "/routes/v0/calculators/{calculator_name}"))
  let req_body = {"Description": $description, "PricingPlan": $pricing_plan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a tracker resource from your Amazon Web Services account. This operation deletes the resource permanently. If the tracker resource is in use, you may encounter an error. Make sure that the target resource isn't a dependency for your applications.
#
# DELETE /tracking/v0/trackers/{TrackerName}
# operationId: DeleteTracker
export def "tracking-trackers delete" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the tracker resource details.
#
# GET /tracking/v0/trackers/{TrackerName}
# operationId: DescribeTracker
export def "tracking-trackers get" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CreateTime: record, Description: record, KmsKeyId: record, PositionFiltering: record, PricingPlan: record, PricingPlanDataSource: record, Tags: record, TrackerArn: record, TrackerName: record, UpdateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the specified properties of a given tracker resource.
#
# PATCH /tracking/v0/trackers/{TrackerName}
# operationId: UpdateTracker
export def "tracking-trackers update" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Updates the description for the tracker resource.
  --position-filtering: string@position-filtering-completer # Updates the position filtering for the tracker resource. Valid values: TimeBased - Location updates are evaluated against linked geofence collections, but not every location update is stored. If your update frequency is more often than 30 seconds, only one update per 30 seconds is stored for each unique device ID. DistanceBased - If the device has moved less than 30 m (98.4 ft), location updates are ignored. Location updates within this distance are neither evaluated against linked geofence collections, nor stored. This helps control costs by reducing the number of geofence evaluations and historical device positions to paginate through. Distance-based filtering can also reduce the effects of GPS noise when displaying device trajectories on a map. AccuracyBased - If the device has moved less than the measured accuracy, location updates are ignored. For example, if two consecutive updates from a device have a horizontal accuracy of 5 m and 10 m, the second update is ignored if the device has moved less than 15 m. Ignored location updates are neither evaluated against linked geofence collections, nor stored. This helps educe the effects of GPS noise when displaying device trajectories on a map, and can help control costs by reducing the number of geofence evaluations.
  --pricing-plan: string@pricing-plan-completer # No longer used. If included, the only allowed value is RequestBasedUsage.
  --pricing-plan-data-source: string # This parameter is no longer used.
]: any -> record<TrackerArn: record, TrackerName: record, UpdateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}"))
  let req_body = {"Description": $description, "PositionFiltering": $position_filtering, "PricingPlan": $pricing_plan, "PricingPlanDataSource": $pricing_plan_data_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes the association between a tracker resource and a geofence collection. Once you unlink a tracker resource from a geofence collection, the tracker positions will no longer be automatically evaluated against geofences.
#
# DELETE /tracking/v0/trackers/{TrackerName}/consumers/{ConsumerArn}
# operationId: DisassociateTrackerConsumer
export def "tracking-trackers-consumers delete-disassociate" [
  tracker_name: string
  consumer_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  if ($consumer_arn | is-empty) { error make --unspanned { msg: "path parameter 'ConsumerArn' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name), consumer_arn: (encode-path-segment $consumer_arn)} | format pattern "/tracking/v0/trackers/{tracker_name}/consumers/{consumer_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves a device's most recent position according to its sample time. Device positions are deleted after 30 days.
#
# GET /tracking/v0/trackers/{TrackerName}/devices/{DeviceId}/positions/latest
# operationId: GetDevicePosition
export def "tracking-trackers-devices-positions-latest get" [
  tracker_name: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Accuracy: record<Horizontal: record>, DeviceId: record, Position: record, PositionProperties: record, ReceivedTime: record, SampleTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'DeviceId' must be non-empty" } }
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name), device_id: (encode-path-segment $device_id)} | format pattern "/tracking/v0/trackers/{tracker_name}/devices/{device_id}/positions/latest"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves the device position history from a tracker resource within a specified range of time. Device positions are deleted after 30 days.
#
# POST /tracking/v0/trackers/{TrackerName}/devices/{DeviceId}/list-positions
# operationId: GetDevicePositionHistory
export def "tracking-trackers-devices-list-positions get-history" [
  tracker_name: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --end-time-exclusive: string # Specify the end time for the position history in ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. By default, the value will be the time that the request is made. Requirement: The time specified for EndTimeExclusive must be after the time for StartTimeInclusive. (format: date-time)
  --max-results-body: int # An optional limit for the number of device positions returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
  --start-time-inclusive: string # Specify the start time for the position history in ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) format: YYYY-MM-DDThh:mm:ss.sssZ. By default, the value will be 24 hours prior to the time that the request is made. Requirement: The time specified for StartTimeInclusive must be before EndTimeExclusive. (format: date-time)
]: any -> record<DevicePositions: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'DeviceId' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name), device_id: (encode-path-segment $device_id)} | format pattern "/tracking/v0/trackers/{tracker_name}/devices/{device_id}/list-positions") $qp)
  let req_body = {"EndTimeExclusive": $end_time_exclusive, "MaxResults": $max_results_body, "NextToken": $next_token_body, "StartTimeInclusive": $start_time_inclusive} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Retrieves the geofence details from a geofence collection.
#
# GET /geofencing/v0/collections/{CollectionName}/geofences/{GeofenceId}
# operationId: GetGeofence
export def "geofencing-collections-geofences get" [
  collection_name: string
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<CreateTime: record, GeofenceId: record, Geometry: record<Circle: record<Center: record, Radius: record>, Polygon: record>, Status: record, UpdateTime: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  if ($geofence_id | is-empty) { error make --unspanned { msg: "path parameter 'GeofenceId' must be non-empty" } }
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name), geofence_id: (encode-path-segment $geofence_id)} | format pattern "/geofencing/v0/collections/{collection_name}/geofences/{geofence_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stores a geofence geometry in a given geofence collection, or updates the geometry of an existing geofence if a geofence ID is included in the request.
#
# PUT /geofencing/v0/collections/{CollectionName}/geofences/{GeofenceId}
# operationId: PutGeofence
# --Geometry shape: {Circle?: any, Polygon?: any}
export def "geofencing-collections-geofences update" [
  collection_name: string
  geofence_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  geometry: record # Contains the geofence geometry details. A geofence geometry is made up of either a polygon or a circle. Can be either a polygon or a circle. Including both will return a validation error. Amazon Location doesn't currently support polygons with holes, multipolygons, polygons that are wound clockwise, or that cross the antimeridian. — shape: {Circle?: any, Polygon?: any}
]: any -> record<CreateTime: record, GeofenceId: record, UpdateTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  if ($geofence_id | is-empty) { error make --unspanned { msg: "path parameter 'GeofenceId' must be non-empty" } }
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name), geofence_id: (encode-path-segment $geofence_id)} | format pattern "/geofencing/v0/collections/{collection_name}/geofences/{geofence_id}"))
  let req_body = {"Geometry": $geometry} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves glyphs used to display labels on a map.
#
# GET /maps/v0/maps/{MapName}/glyphs/{FontStack}/{FontUnicodeRange}
# operationId: GetMapGlyphs
export def "maps-maps-glyphs get" [
  map_name: string
  font_stack: string
  font_unicode_range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The optional API key (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request. (format: password)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Blob: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'MapName' must be non-empty" } }
  if ($font_stack | is-empty) { error make --unspanned { msg: "path parameter 'FontStack' must be non-empty" } }
  if ($font_unicode_range | is-empty) { error make --unspanned { msg: "path parameter 'FontUnicodeRange' must be non-empty" } }
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({map_name: (encode-path-segment $map_name), font_stack: (encode-path-segment $font_stack), font_unicode_range: (encode-path-segment $font_unicode_range)} | format pattern "/maps/v0/maps/{map_name}/glyphs/{font_stack}/{font_unicode_range}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"key": $key} | compact), body: null}
}

# Retrieves the sprite sheet corresponding to a map resource. The sprite sheet is a PNG image paired with a JSON document describing the offsets of individual icons that will be displayed on a rendered map.
#
# GET /maps/v0/maps/{MapName}/sprites/{FileName}
# operationId: GetMapSprites
export def "maps-maps-sprites get" [
  map_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The optional API key (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request. (format: password)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Blob: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'MapName' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'FileName' must be non-empty" } }
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({map_name: (encode-path-segment $map_name), file_name: (encode-path-segment $file_name)} | format pattern "/maps/v0/maps/{map_name}/sprites/{file_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"key": $key} | compact), body: null}
}

# Retrieves the map style descriptor from a map resource. The style descriptor contains speciﬁcations on how features render on a map. For example, what data to display, what order to display the data in, and the style for the data. Style descriptors follow the Mapbox Style Specification.
#
# GET /maps/v0/maps/{MapName}/style-descriptor
# operationId: GetMapStyleDescriptor
export def "maps-maps-style-descriptor get" [
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The optional API key (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request. (format: password)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Blob: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'MapName' must be non-empty" } }
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({map_name: (encode-path-segment $map_name)} | format pattern "/maps/v0/maps/{map_name}/style-descriptor") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"key": $key} | compact), body: null}
}

# Retrieves a vector data tile from the map resource. Map tiles are used by clients to render a map. they're addressed using a grid arrangement with an X coordinate, Y coordinate, and Z (zoom) level. The origin (0, 0) is the top left of the map. Increasing the zoom level by 1 doubles both the X and Y dimensions, so a tile containing data for the entire world at (0/0/0) will be split into 4 tiles at zoom 1 (1/0/0, 1/0/1, 1/1/0, 1/1/1).
#
# GET /maps/v0/maps/{MapName}/tiles/{Z}/{X}/{Y}
# operationId: GetMapTile
export def "maps-maps-tiles get" [
  map_name: string
  z: string
  x: string
  y: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # The optional API key (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html) to authorize the request. (format: password)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Blob: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($map_name | is-empty) { error make --unspanned { msg: "path parameter 'MapName' must be non-empty" } }
  if ($z | is-empty) { error make --unspanned { msg: "path parameter 'Z' must be non-empty" } }
  if ($x | is-empty) { error make --unspanned { msg: "path parameter 'X' must be non-empty" } }
  if ($y | is-empty) { error make --unspanned { msg: "path parameter 'Y' must be non-empty" } }
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({map_name: (encode-path-segment $map_name), z: (encode-path-segment $z), x: (encode-path-segment $x), y: (encode-path-segment $y)} | format pattern "/maps/v0/maps/{map_name}/tiles/{z}/{x}/{y}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"key": $key} | compact), body: null}
}

# Finds a place by its unique ID. A PlaceId is returned by other search operations. A PlaceId is valid only if all of the following are the same in the original search request and the call to GetPlace. Customer Amazon Web Services account Amazon Web Services Region Data provider specified in the place index resource
#
# GET /places/v0/indexes/{IndexName}/places/{PlaceId}
# operationId: GetPlace
export def "places-indexes-places get" [
  index_name: string
  place_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The preferred language used to return results. The value must be a valid BCP 47 (https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results, but not the results themselves. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for a location around Athens, Greece, with the language parameter set to en. The city in the results will most likely be returned as Athens. If you set the language parameter to el, for Greek, then the city in the results will more likely be returned as Αθήνα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Place: record<AddressNumber: record, Country: record, Geometry: record<Point: record>, Interpolated: record, Label: record, Municipality: record, Neighborhood: record, PostalCode: record, Region: record, Street: record, SubRegion: record, TimeZone: record<Name: record, Offset: record>, UnitNumber: record, UnitType: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'IndexName' must be non-empty" } }
  if ($place_id | is-empty) { error make --unspanned { msg: "path parameter 'PlaceId' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name), place_id: (encode-path-segment $place_id)} | format pattern "/places/v0/indexes/{index_name}/places/{place_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"language": $language} | compact), body: null}
}

# A batch request to retrieve all device positions.
#
# POST /tracking/v0/trackers/{TrackerName}/list-positions
# operationId: ListDevicePositions
export def "tracking-trackers-list-positions list-device" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # An optional limit for the number of entries returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
]: any -> record<Entries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}/list-positions") $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists geofence collections in your Amazon Web Services account.
#
# POST /geofencing/v0/list-collections
# operationId: ListGeofenceCollections
export def "geofencing-list-collections list-geofence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # An optional limit for the number of resources returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
]: any -> record<Entries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geofencing/v0/list-collections" $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists geofences stored in a given geofence collection.
#
# POST /geofencing/v0/collections/{CollectionName}/list-geofences
# operationId: ListGeofences
export def "geofencing-collections-list-geofences list" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # An optional limit for the number of geofences returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
]: any -> record<Entries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_name | is-empty) { error make --unspanned { msg: "path parameter 'CollectionName' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_name: (encode-path-segment $collection_name)} | format pattern "/geofencing/v0/collections/{collection_name}/list-geofences") $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists API key resources in your Amazon Web Services account. The API keys feature is in preview. We may add, change, or remove features before announcing general availability. For more information, see Using API keys (https://docs.aws.amazon.com/location/latest/developerguide/using-apikeys.html).
#
# POST /metadata/v0/list-keys
# operationId: ListKeys
# --Filter shape: {KeyStatus?: any}
export def "metadata-list-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filter: record # Options for filtering API keys. — shape: {KeyStatus?: any}
  --max-results-body: int # An optional limit for the number of resources returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
]: any -> record<Entries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata/v0/list-keys" $qp)
  let req_body = {"Filter": $filter, "MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists map resources in your Amazon Web Services account.
#
# POST /maps/v0/list-maps
# operationId: ListMaps
export def "maps-list-maps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # An optional limit for the number of resources returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
]: any -> record<Entries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/maps/v0/list-maps" $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists place index resources in your Amazon Web Services account.
#
# POST /places/v0/list-indexes
# operationId: ListPlaceIndexes
export def "places-list-indexes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # An optional limit for the maximum number of results returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
]: any -> record<Entries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places/v0/list-indexes" $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists route calculator resources in your Amazon Web Services account.
#
# POST /routes/v0/list-calculators
# operationId: ListRouteCalculators
export def "routes-list-calculators list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # An optional maximum number of results returned in a single call. Default Value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default Value: null (body field)
]: any -> record<Entries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/routes/v0/list-calculators" $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Returns a list of tags that are applied to the specified Amazon Location resource.
#
# GET /tags/{ResourceArn}
# operationId: ListTagsForResource
export def "tags list-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Assigns one or more tags (key-value pairs) to the specified Amazon Location Service resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the TagResource operation with an Amazon Location Service resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the tags already associated with the resource. If you specify a tag key that's already associated with the resource, the new tag value that you specify replaces the previous value for that tag. You can associate up to 50 tags with a resource.
#
# POST /tags/{ResourceArn}
# operationId: TagResource
export def "tags tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # Applies one or more tags to specific resource. A tag is a key-value pair that helps you manage, identify, search, and filter your resources. Format: "key" : "value" Restrictions: Maximum 50 tags per resource. Each tag key must be unique and must have exactly one associated value. Maximum key length: 128 Unicode characters in UTF-8. Maximum value length: 256 Unicode characters in UTF-8. Can use alphanumeric characters (A–Z, a–z, 0–9), and the following characters: + - = . _ : / @ Cannot use "aws:" as a prefix for a key.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}"))
  let req_body = {"Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists geofence collections currently associated to the given tracker resource.
#
# POST /tracking/v0/trackers/{TrackerName}/list-consumers
# operationId: ListTrackerConsumers
export def "tracking-trackers-list-consumers list" [
  tracker_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # An optional limit for the number of resources returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
]: any -> record<ConsumerArns: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'TrackerName' must be non-empty" } }
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracker_name: (encode-path-segment $tracker_name)} | format pattern "/tracking/v0/trackers/{tracker_name}/list-consumers") $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Lists tracker resources in your Amazon Web Services account.
#
# POST /tracking/v0/list-trackers
# operationId: ListTrackers
export def "tracking-list-trackers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --max-results-body: int # An optional limit for the number of resources returned in a single call. Default value: 100 (body field)
  --next-token-body: string # The pagination token specifying which page of results to return in the response. If no token is provided, the default page is the first page. Default value: null (body field)
]: any -> record<Entries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tracking/v0/list-trackers" $qp)
  let req_body = {"MaxResults": $max_results_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact), body: $req_body}
}

# Reverse geocodes a given coordinate and returns a legible address. Allows you to search for Places or points of interest near a given position.
#
# POST /places/v0/indexes/{IndexName}/search/position
# operationId: SearchPlaceIndexForPosition
export def "places-indexes-search-position list-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --language: string # The preferred language used to return results. The value must be a valid BCP 47 (https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results, but not the results themselves. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for a location around Athens, Greece, with the language parameter set to en. The city in the results will most likely be returned as Athens. If you set the language parameter to el, for Greek, then the city in the results will more likely be returned as Αθήνα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
  --max-results: int # An optional parameter. The maximum number of results returned per request. Default value: 50
  position: list<float> # Specifies the longitude and latitude of the position to query. This parameter must contain a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents a position with longitude -123.1174 and latitude 49.2847.
]: any -> record<Results: record, Summary: record<DataSource: record, Language: record, MaxResults: record, Position: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'IndexName' must be non-empty" } }
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/places/v0/indexes/{index_name}/search/position"))
  let req_body = {"Language": $language, "MaxResults": $max_results, "Position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generates suggestions for addresses and points of interest based on partial or misspelled free-form text. This operation is also known as autocomplete, autosuggest, or fuzzy matching. Optional parameters let you narrow your search results by bounding box or country, or bias your search toward a specific position on the globe. You can search for suggested place names near a specified position by using BiasPosition, or filter results within a bounding box by using FilterBBox. These parameters are mutually exclusive; using both BiasPosition and FilterBBox in the same command returns an error.
#
# POST /places/v0/indexes/{IndexName}/search/suggestions
# operationId: SearchPlaceIndexForSuggestions
export def "places-indexes-search-suggestions list-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --bias-position: list<float> # An optional parameter that indicates a preference for place suggestions that are closer to a specified position. If provided, this parameter must contain a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents the position with longitude -123.1174 and latitude 49.2847. BiasPosition and FilterBBox are mutually exclusive. Specifying both options results in an error.
  --filter-b-box: list<float> # An optional parameter that limits the search results by returning only suggestions within a specified bounding box. If provided, this parameter must contain a total of four consecutive numbers in two pairs. The first pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the southwest corner of the bounding box; the second pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the northeast corner of the bounding box. For example, [-12.7935, -37.4835, -12.0684, -36.9542] represents a bounding box where the southwest corner has longitude -12.7935 and latitude -37.4835, and the northeast corner has longitude -12.0684 and latitude -36.9542. FilterBBox and BiasPosition are mutually exclusive. Specifying both options results in an error.
  --filter-countries: list<string> # An optional parameter that limits the search results by returning only suggestions within the provided list of countries. Use the ISO 3166 (https://www.iso.org/iso-3166-country-codes.html) 3-digit country code. For example, Australia uses three upper-case characters: AUS.
  --language: string # The preferred language used to return results. The value must be a valid BCP 47 (https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for Athens, Gr to get suggestions with the language parameter set to en. The results found will most likely be returned as Athens, Greece. If you set the language parameter to el, for Greek, then the result found will more likely be returned as Αθήνα, Ελλάδα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
  --max-results: int # An optional parameter. The maximum number of results returned per request. The default: 5
  text: string # The free-form partial text to use to generate place suggestions. For example, eiffel tow. (format: password)
]: any -> record<Results: record, Summary: record<BiasPosition: record, DataSource: record, FilterBBox: record, FilterCountries: record, Language: record, MaxResults: record, Text: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'IndexName' must be non-empty" } }
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/places/v0/indexes/{index_name}/search/suggestions"))
  let req_body = {"BiasPosition": $bias_position, "FilterBBox": $filter_b_box, "FilterCountries": $filter_countries, "Language": $language, "MaxResults": $max_results, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Geocodes free-form text, such as an address, name, city, or region to allow you to search for Places or points of interest. Optional parameters let you narrow your search results by bounding box or country, or bias your search toward a specific position on the globe. You can search for places near a given position using BiasPosition, or filter results within a bounding box using FilterBBox. Providing both parameters simultaneously returns an error. Search results are returned in order of highest to lowest relevance.
#
# POST /places/v0/indexes/{IndexName}/search/text
# operationId: SearchPlaceIndexForText
export def "places-indexes-search-text list-index" [
  index_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --bias-position: list<float> # An optional parameter that indicates a preference for places that are closer to a specified position. If provided, this parameter must contain a pair of numbers. The first number represents the X coordinate, or longitude; the second number represents the Y coordinate, or latitude. For example, [-123.1174, 49.2847] represents the position with longitude -123.1174 and latitude 49.2847. BiasPosition and FilterBBox are mutually exclusive. Specifying both options results in an error.
  --filter-b-box: list<float> # An optional parameter that limits the search results by returning only places that are within the provided bounding box. If provided, this parameter must contain a total of four consecutive numbers in two pairs. The first pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the southwest corner of the bounding box; the second pair of numbers represents the X and Y coordinates (longitude and latitude, respectively) of the northeast corner of the bounding box. For example, [-12.7935, -37.4835, -12.0684, -36.9542] represents a bounding box where the southwest corner has longitude -12.7935 and latitude -37.4835, and the northeast corner has longitude -12.0684 and latitude -36.9542. FilterBBox and BiasPosition are mutually exclusive. Specifying both options results in an error.
  --filter-countries: list<string> # An optional parameter that limits the search results by returning only places that are in a specified list of countries. Valid values include ISO 3166 (https://www.iso.org/iso-3166-country-codes.html) 3-digit country codes. For example, Australia uses three upper-case characters: AUS.
  --language: string # The preferred language used to return results. The value must be a valid BCP 47 (https://tools.ietf.org/search/bcp47) language tag, for example, en for English. This setting affects the languages used in the results, but not the results themselves. If no language is specified, or not supported for a particular result, the partner automatically chooses a language for the result. For an example, we'll use the Greek language. You search for Athens, Greece, with the language parameter set to en. The result found will most likely be returned as Athens. If you set the language parameter to el, for Greek, then the result found will more likely be returned as Αθήνα. If the data provider does not have a value for Greek, the result will be in a language that the provider does support.
  --max-results: int # An optional parameter. The maximum number of results returned per request. The default: 50
  text: string # The address, name, city, or region to be used in the search in free-form text format. For example, 123 Any Street. (format: password)
]: any -> record<Results: record, Summary: record<BiasPosition: record, DataSource: record, FilterBBox: record, FilterCountries: record, Language: record, MaxResults: record, ResultBBox: record, Text: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index_name | is-empty) { error make --unspanned { msg: "path parameter 'IndexName' must be non-empty" } }
  let full_url = (build-url $base ({index_name: (encode-path-segment $index_name)} | format pattern "/places/v0/indexes/{index_name}/search/text"))
  let req_body = {"BiasPosition": $bias_position, "FilterBBox": $filter_b_box, "FilterCountries": $filter_countries, "Language": $language, "MaxResults": $max_results, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Removes one or more tags from the specified Amazon Location resource.
#
# DELETE /tags/{ResourceArn}
# operationId: UntagResource
export def "tags untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list # The list of tag keys to remove from the specified resource.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_arn | is-empty) { error make --unspanned { msg: "path parameter 'ResourceArn' must be non-empty" } }
  let qp = [(serialize-qp "tagKeys" $tag_keys "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_arn: (encode-path-segment $resource_arn)} | format pattern "/tags/{resource_arn}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tagKeys": $tag_keys} | compact), body: null}
}
