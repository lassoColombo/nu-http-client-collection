# Auto-generated client for Proximity Beacon API vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/proximitybeacon/v1beta1/openapi.json
# Auth: --token flag or $env.PROXIMITY_BEACON_API_TOKEN

const BASE_URL = "https://proximitybeacon.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PROXIMITY_BEACON_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://proximitybeacon.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def expected-stability-completer [] { ["MOBILE" "PORTABLE" "ROVING" "STABILITY_UNSPECIFIED" "STABLE"] }
def status-completer [] { ["ACTIVE" "DECOMMISSIONED" "INACTIVE" "STATUS_UNSPECIFIED"] }
def alert-filter-completer [] { ["ALERT_UNSPECIFIED" "LOW_ACTIVITY" "LOW_BATTERY" "WRONG_LOCATION"] }
def serving-visibility-completer [] { ["PUBLIC" "UNLISTED" "VISIBILITY_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1-beaconinfo-get-forobserved get" } } | get name | first)
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

# Given one or more beacon observations, returns any beacon information and attachments accessible to your application. Authorize by using the [API key](https://developers.google.com/beacons/proximity/get-started#request_a_browser_api_key) for the application.
#
# POST /v1beta1/beaconinfo:getforobserved
# operationId: proximitybeacon.beaconinfo.getforobserved
# --observations item shape: {advertisedId?: record, telemetry?: string, timestampMs?: string}
export def "v1beta1-beaconinfo-get-forobserved get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --namespaced-types: list<string> # Specifies what kind of attachments to include in the response. When given, the response will include only attachments of the given types. When empty, no attachments will be returned. Must be in the format namespace/type. Accepts `*` to specify all types in all namespaces owned by the client. Optional.
  --observations: list # The beacons that the client has encountered. At least one must be given. — item shape: {advertisedId?: record, telemetry?: string, timestampMs?: string}
]: any -> record<beacons: table<advertisedId: record, attachments: list, beaconName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/beaconinfo:getforobserved" $qp)
  let req_body = {"namespacedTypes": $namespaced_types, "observations": $observations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Searches the beacon registry for beacons that match the given search criteria. Only those beacons that the client has permission to list will be returned. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **viewer**, **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# GET /v1beta1/beacons
# operationId: proximitybeacon.beacons.list
export def "v1beta1-beacons list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # The maximum number of records to return for this request, up to a server-defined upper limit.
  --page-token: string # A pagination token obtained from a previous request to list beacons.
  --project-id: string # The project id to list beacons under. If not present then the project credential that made the request is used as the project. Optional.
  --q: string # Filter query string that supports the following field filters: * **description:`""`** For example: **description:"Room 3"** Returns beacons whose description matches tokens in the string "Room 3" (not necessarily that exact string). The string must be double-quoted. * **status:``** For example: **status:active** Returns beacons whose status matches the given value. Values must be one of the Beacon.Status enum values (case insensitive). Accepts multiple filters which will be combined with OR logic. * **stability:``** For example: **stability:mobile** Returns beacons whose expected stability matches the given value. Values must be one of the Beacon.Stability enum values (case insensitive). Accepts multiple filters which will be combined with OR logic. * **place\_id:`""`** For example: **place\_id:"ChIJVSZzVR8FdkgRXGmmm6SslKw="** Returns beacons explicitly registered at the given place, expressed as a Place ID obtained from [Google Places API](/places/place-id). Does not match places inside the given place. Does not consider the beacon's actual location (which may be different from its registered place). Accepts multiple filters that will be combined with OR logic. The place ID must be double-quoted. * **registration\_time`[<|>|<=|>=]`** For example: **registration\_time>=1433116800** Returns beacons whose registration time matches the given filter. Supports the operators: <, >, <=, and >=. Timestamp must be expressed as an integer number of seconds since midnight January 1, 1970 UTC. Accepts at most two filters that will be combined with AND logic, to support "between" semantics. If more than two are supplied, the latter ones are ignored. * **lat:` lng: radius:`** For example: **lat:51.1232343 lng:-1.093852 radius:1000** Returns beacons whose registered location is within the given circle. When any of these fields are given, all are required. Latitude and longitude must be decimal degrees between -90.0 and 90.0 and between -180.0 and 180.0 respectively. Radius must be an integer number of meters between 10 and 1,000,000 (1000 km). * **property:`"="`** For example: **property:"battery-type=CR2032"** Returns beacons which have a property of the given name and value. Supports multiple filters which will be combined with OR logic. The entire name=value string must be double-quoted as one string. * **attachment\_type:`""`** For example: **attachment_type:"my-namespace/my-type"** Returns beacons having at least one attachment of the given namespaced type. Supports "any within this namespace" via the partial wildcard syntax: "my-namespace/*". Supports multiple filters which will be combined with OR logic. The string must be double-quoted. * **indoor\_level:`""`** For example: **indoor\_level:"1"** Returns beacons which are located on the given indoor level. Accepts multiple filters that will be combined with OR logic. Multiple filters on the same field are combined with OR logic (except registration_time which is combined with AND logic). Multiple filters on different fields are combined with AND logic. Filters should be separated by spaces. As with any HTTP query string parameter, the whole filter expression must be URL-encoded. Example REST request: `GET /v1beta1/beacons?q=status:active%20lat:51.123%20lng:-1.095%20radius:1000`
]: nothing -> record<beacons: table<advertisedId: record, beaconName: string, description: string, ephemeralIdRegistration: record, expectedStability: string, indoorLevel: record, latLng: record, placeId: string, properties: record, provisioningKey: string, status: string>, nextPageToken: string, totalCount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/beacons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token, "projectId": $project_id, "q": $q} | compact), body: null}
}

# Registers a previously unregistered beacon given its `advertisedId`. These IDs are unique within the system. An ID can be registered only once. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# POST /v1beta1/beacons:register
# operationId: proximitybeacon.beacons.register
# --advertisedId shape: {id?: string, type?: "TYPE_UNSPECIFIED"|"EDDYSTONE"|"IBEACON"|"ALTBEACON"|"EDDYSTONE_EID"}
# --ephemeralIdRegistration shape: {beaconEcdhPublicKey?: string, beaconIdentityKey?: string, initialClockValue?: string, initialEid?: string, rotationPeriodExponent?: int, serviceEcdhPublicKey?: string}
# --indoorLevel shape: {name?: string}
# --latLng shape: {latitude?: float, longitude?: float}
export def "v1beta1-beacons-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the project the beacon will be registered to. If the project id is not specified then the project making the request is used. Optional.
  --advertised-id: record # Defines a unique identifier of a beacon as broadcast by the device. — shape: {id?: string, type?: "TYPE_UNSPECIFIED"|"EDDYSTONE"|"IBEACON"|"ALTBEACON"|"EDDYSTONE_EID"}
  --beacon-name: string # Resource name of this beacon. A beacon name has the format "beacons/N!beaconId" where the beaconId is the base16 ID broadcast by the beacon and N is a code for the beacon's type. Possible values are `3` for Eddystone, `1` for iBeacon, or `5` for AltBeacon. This field must be left empty when registering. After reading a beacon, clients can use the name for future operations.
  --description: string # Free text used to identify and describe the beacon. Maximum length 140 characters. Optional.
  --ephemeral-id-registration: record # Write-only registration parameters for beacons using Eddystone-EID format. Two ways of securely registering an Eddystone-EID beacon with the service are supported: 1. Perform an ECDH key exchange via this API, including a previous call to `GET /v1beta1/eidparams`. In this case the fields `beacon_ecdh_public_key` and `service_ecdh_public_key` should be populated and `beacon_identity_key` should not be populated. This method ensures that only the two parties in the ECDH key exchange can compute the identity key, which becomes a secret between them. 2. Derive or obtain the beacon's identity key via other secure means (perhaps an ECDH key exchange between the beacon and a mobile device or any other secure method), and then submit the resulting identity key to the service. In this case `beacon_identity_key` field should be populated, and neither of `beacon_ecdh_public_key` nor `service_ecdh_public_key` fields should be. The security of this method depends on how securely the parties involved (in particular the bluetooth client) handle the identity key, and obviously on how securely the identity key was generated. See [the Eddystone specification](https://github.com/google/eddystone/tree/master/eddystone-eid) at GitHub. — shape: {beaconEcdhPublicKey?: string, beaconIdentityKey?: string, initialClockValue?: string, initialEid?: string, rotationPeriodExponent?: int, serviceEcdhPublicKey?: string}
  --expected-stability: string@expected-stability-completer # Expected location stability. This is set when the beacon is registered or updated, not automatically detected in any way. Optional.
  --indoor-level: record # Indoor level, a human-readable string as returned by Google Maps APIs, useful to indicate which floor of a building a beacon is located on. — shape: {name?: string}
  --lat-lng: record # An object that represents a latitude/longitude pair. This is expressed as a pair of doubles to represent degrees latitude and degrees longitude. Unless specified otherwise, this must conform to the WGS84 standard. Values must be within normalized ranges. — shape: {latitude?: float, longitude?: float}
  --place-id: string # The [Google Places API](/places/place-id) Place ID of the place where the beacon is deployed. This is given when the beacon is registered or updated, not automatically detected in any way. Optional.
  --properties: record # Properties of the beacon device, for example battery type or firmware version. Optional.
  --provisioning-key: string # Some beacons may require a user to provide an authorization key before changing any of its configuration (e.g. broadcast frames, transmit power). This field provides a place to store and control access to that key. This field is populated in responses to `GET /v1beta1/beacons/3!beaconId` from users with write access to the given beacon. That is to say: If the user is authorized to write the beacon's confidential data in the service, the service considers them authorized to configure the beacon. Note that this key grants nothing on the service, only on the beacon itself. (format: byte)
  --status: string@status-completer # Current status of the beacon. Required.
]: any -> record<advertisedId: record<id: string, type: string>, beaconName: string, description: string, ephemeralIdRegistration: record<beaconEcdhPublicKey: string, beaconIdentityKey: string, initialClockValue: string, initialEid: string, rotationPeriodExponent: int, serviceEcdhPublicKey: string>, expectedStability: string, indoorLevel: record<name: string>, latLng: record<latitude: float, longitude: float>, placeId: string, properties: record, provisioningKey: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/beacons:register" $qp)
  let req_body = {"advertisedId": $advertised_id, "beaconName": $beacon_name, "description": $description, "ephemeralIdRegistration": $ephemeral_id_registration, "expectedStability": $expected_stability, "indoorLevel": $indoor_level, "latLng": $lat_lng, "placeId": $place_id, "properties": $properties, "provisioningKey": $provisioning_key, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: $req_body}
}

# Gets the Proximity Beacon API's current public key and associated parameters used to initiate the Diffie-Hellman key exchange required to register a beacon that broadcasts the Eddystone-EID format. This key changes periodically; clients may cache it and re-use the same public key to provision and register multiple beacons. However, clients should be prepared to refresh this key when they encounter an error registering an Eddystone-EID beacon.
#
# GET /v1beta1/eidparams
# operationId: proximitybeacon.getEidparams
export def "v1beta1-eidparams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<maxRotationPeriodExponent: int, minRotationPeriodExponent: int, serviceEcdhPublicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/eidparams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists all attachment namespaces owned by your Google Developers Console project. Attachment data associated with a beacon must include a namespaced type, and the namespace must be owned by your project. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **viewer**, **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# GET /v1beta1/namespaces
# operationId: proximitybeacon.namespaces.list
export def "v1beta1-namespaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id to list namespaces under. Optional.
]: nothing -> record<namespaces: table<namespaceName: string, servingVisibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: null}
}

# Deletes the specified attachment for the given beacon. Each attachment has a unique attachment name (`attachmentName`) which is returned when you fetch the attachment data via this API. You specify this with the delete request to control which attachment is removed. This operation cannot be undone. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# DELETE /v1beta1/{attachmentName}
# operationId: proximitybeacon.beacons.attachments.delete
export def "v1beta1 delete-by-attachment-name" [
  attachment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the attachment to delete. If not provided, the project that is making the request is used. Optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($attachment_name | is-empty) { error make --unspanned { msg: "path parameter 'attachmentName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attachment_name: (encode-path-segment $attachment_name)} | format pattern "/v1beta1/{attachment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: null}
}

# Deletes the specified beacon including all diagnostics data for the beacon as well as any attachments on the beacon (including those belonging to other projects). This operation cannot be undone. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# DELETE /v1beta1/{beaconName}
# operationId: proximitybeacon.beacons.delete
export def "v1beta1 delete-by-beacon-name" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the beacon to delete. If not provided, the project that is making the request is used. Optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: null}
}

# Returns detailed information about the specified beacon. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **viewer**, **Is owner** or **Can edit** permissions in the Google Developers Console project. Requests may supply an Eddystone-EID beacon name in the form: `beacons/4!beaconId` where the `beaconId` is the base16 ephemeral ID broadcast by the beacon. The returned `Beacon` object will contain the beacon's stable Eddystone-UID. Clients not authorized to resolve the beacon's ephemeral Eddystone-EID broadcast will receive an error.
#
# GET /v1beta1/{beaconName}
# operationId: proximitybeacon.beacons.get
export def "v1beta1 get" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the beacon to request. If the project id is not specified then the project making the request is used. The project id must match the project that owns the beacon. Optional.
]: nothing -> record<advertisedId: record<id: string, type: string>, beaconName: string, description: string, ephemeralIdRegistration: record<beaconEcdhPublicKey: string, beaconIdentityKey: string, initialClockValue: string, initialEid: string, rotationPeriodExponent: int, serviceEcdhPublicKey: string>, expectedStability: string, indoorLevel: record<name: string>, latLng: record<latitude: float, longitude: float>, placeId: string, properties: record, provisioningKey: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: null}
}

# Updates the information about the specified beacon. **Any field that you do not populate in the submitted beacon will be permanently erased**, so you should follow the "read, modify, write" pattern to avoid inadvertently destroying data. Changes to the beacon status via this method will be silently ignored. To update beacon status, use the separate methods on this API for activation, deactivation, and decommissioning. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# PUT /v1beta1/{beaconName}
# operationId: proximitybeacon.beacons.update
# --advertisedId shape: {id?: string, type?: "TYPE_UNSPECIFIED"|"EDDYSTONE"|"IBEACON"|"ALTBEACON"|"EDDYSTONE_EID"}
# --ephemeralIdRegistration shape: {beaconEcdhPublicKey?: string, beaconIdentityKey?: string, initialClockValue?: string, initialEid?: string, rotationPeriodExponent?: int, serviceEcdhPublicKey?: string}
# --indoorLevel shape: {name?: string}
# --latLng shape: {latitude?: float, longitude?: float}
export def "v1beta1 update-by-beacon-name" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the beacon to update. If the project id is not specified then the project making the request is used. The project id must match the project that owns the beacon. Optional.
  --advertised-id: record # Defines a unique identifier of a beacon as broadcast by the device. — shape: {id?: string, type?: "TYPE_UNSPECIFIED"|"EDDYSTONE"|"IBEACON"|"ALTBEACON"|"EDDYSTONE_EID"}
  --body-beacon-name: string # Resource name of this beacon. A beacon name has the format "beacons/N!beaconId" where the beaconId is the base16 ID broadcast by the beacon and N is a code for the beacon's type. Possible values are `3` for Eddystone, `1` for iBeacon, or `5` for AltBeacon. This field must be left empty when registering. After reading a beacon, clients can use the name for future operations.
  --description: string # Free text used to identify and describe the beacon. Maximum length 140 characters. Optional.
  --ephemeral-id-registration: record # Write-only registration parameters for beacons using Eddystone-EID format. Two ways of securely registering an Eddystone-EID beacon with the service are supported: 1. Perform an ECDH key exchange via this API, including a previous call to `GET /v1beta1/eidparams`. In this case the fields `beacon_ecdh_public_key` and `service_ecdh_public_key` should be populated and `beacon_identity_key` should not be populated. This method ensures that only the two parties in the ECDH key exchange can compute the identity key, which becomes a secret between them. 2. Derive or obtain the beacon's identity key via other secure means (perhaps an ECDH key exchange between the beacon and a mobile device or any other secure method), and then submit the resulting identity key to the service. In this case `beacon_identity_key` field should be populated, and neither of `beacon_ecdh_public_key` nor `service_ecdh_public_key` fields should be. The security of this method depends on how securely the parties involved (in particular the bluetooth client) handle the identity key, and obviously on how securely the identity key was generated. See [the Eddystone specification](https://github.com/google/eddystone/tree/master/eddystone-eid) at GitHub. — shape: {beaconEcdhPublicKey?: string, beaconIdentityKey?: string, initialClockValue?: string, initialEid?: string, rotationPeriodExponent?: int, serviceEcdhPublicKey?: string}
  --expected-stability: string@expected-stability-completer # Expected location stability. This is set when the beacon is registered or updated, not automatically detected in any way. Optional.
  --indoor-level: record # Indoor level, a human-readable string as returned by Google Maps APIs, useful to indicate which floor of a building a beacon is located on. — shape: {name?: string}
  --lat-lng: record # An object that represents a latitude/longitude pair. This is expressed as a pair of doubles to represent degrees latitude and degrees longitude. Unless specified otherwise, this must conform to the WGS84 standard. Values must be within normalized ranges. — shape: {latitude?: float, longitude?: float}
  --place-id: string # The [Google Places API](/places/place-id) Place ID of the place where the beacon is deployed. This is given when the beacon is registered or updated, not automatically detected in any way. Optional.
  --properties: record # Properties of the beacon device, for example battery type or firmware version. Optional.
  --provisioning-key: string # Some beacons may require a user to provide an authorization key before changing any of its configuration (e.g. broadcast frames, transmit power). This field provides a place to store and control access to that key. This field is populated in responses to `GET /v1beta1/beacons/3!beaconId` from users with write access to the given beacon. That is to say: If the user is authorized to write the beacon's confidential data in the service, the service considers them authorized to configure the beacon. Note that this key grants nothing on the service, only on the beacon itself. (format: byte)
  --status: string@status-completer # Current status of the beacon. Required.
]: any -> record<advertisedId: record<id: string, type: string>, beaconName: string, description: string, ephemeralIdRegistration: record<beaconEcdhPublicKey: string, beaconIdentityKey: string, initialClockValue: string, initialEid: string, rotationPeriodExponent: int, serviceEcdhPublicKey: string>, expectedStability: string, indoorLevel: record<name: string>, latLng: record<latitude: float, longitude: float>, placeId: string, properties: record, provisioningKey: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}") $qp)
  let req_body = {"advertisedId": $advertised_id, "beaconName": $body_beacon_name, "description": $description, "ephemeralIdRegistration": $ephemeral_id_registration, "expectedStability": $expected_stability, "indoorLevel": $indoor_level, "latLng": $lat_lng, "placeId": $place_id, "properties": $properties, "provisioningKey": $provisioning_key, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: $req_body}
}

# Returns the attachments for the specified beacon that match the specified namespaced-type pattern. To control which namespaced types are returned, you add the `namespacedType` query parameter to the request. You must either use `*/*`, to return all attachments, or the namespace must be one of the ones returned from the `namespaces` endpoint. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **viewer**, **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# GET /v1beta1/{beaconName}/attachments
# operationId: proximitybeacon.beacons.attachments.list
export def "v1beta1-attachments list" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --namespaced-type: string # Specifies the namespace and type of attachment to include in response in namespace/type format. Accepts `*/*` to specify "all types in all namespaces".
  --project-id: string # The project id to list beacon attachments under. This field can be used when "*" is specified to mean all attachment namespaces. Projects may have multiple attachments with multiple namespaces. If "*" is specified and the projectId string is empty, then the project making the request is used. Optional.
]: nothing -> record<attachments: table<attachmentName: string, creationTimeMs: string, data: string, maxDistanceMeters: float, namespacedType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "namespacedType" $namespaced_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}/attachments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "namespacedType": $namespaced_type, "projectId": $project_id} | compact), body: null}
}

# Associates the given data with the specified beacon. Attachment data must contain two parts: - A namespaced type. - The actual attachment data itself. The namespaced type consists of two parts, the namespace and the type. The namespace must be one of the values returned by the `namespaces` endpoint, while the type can be a string of any characters except for the forward slash (`/`) up to 100 characters in length. Attachment data can be up to 1024 bytes long. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# POST /v1beta1/{beaconName}/attachments
# operationId: proximitybeacon.beacons.attachments.create
export def "v1beta1-attachments create" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the project the attachment will belong to. If the project id is not specified then the project making the request is used. Optional.
  --attachment-name: string # Resource name of this attachment. Attachment names have the format: beacons/ beacon_id/attachments/attachment_id. Leave this empty on creation.
  --creation-time-ms: string # The UTC time when this attachment was created, in milliseconds since the UNIX epoch. (format: google-datetime)
  --data: string # An opaque data container for client-provided data. Must be [base64](http://tools.ietf.org/html/rfc4648#section-4) encoded in HTTP requests, and will be so encoded (with padding) in responses. Required. (format: byte)
  --max-distance-meters: float # The distance away from the beacon at which this attachment should be delivered to a mobile app. Setting this to a value greater than zero indicates that the app should behave as if the beacon is "seen" when the mobile device is less than this distance away from the beacon. Different attachments on the same beacon can have different max distances. Note that even though this value is expressed with fractional meter precision, real-world behavior is likley to be much less precise than one meter, due to the nature of current Bluetooth radio technology. Optional. When not set or zero, the attachment should be delivered at the beacon's outer limit of detection. Negative values are invalid and return an error. (format: double)
  --namespaced-type: string # Specifies what kind of attachment this is. Tells a client how to interpret the `data` field. Format is namespace/type. Namespace provides type separation between clients. Type describes the type of `data`, for use by the client when parsing the `data` field. Required.
]: any -> record<attachmentName: string, creationTimeMs: string, data: string, maxDistanceMeters: float, namespacedType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}/attachments") $qp)
  let req_body = {"attachmentName": $attachment_name, "creationTimeMs": $creation_time_ms, "data": $data, "maxDistanceMeters": $max_distance_meters, "namespacedType": $namespaced_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: $req_body}
}

# Deletes multiple attachments on a given beacon. This operation is permanent and cannot be undone. You can optionally specify `namespacedType` to choose which attachments should be deleted. If you do not specify `namespacedType`, all your attachments on the given beacon will be deleted. You also may explicitly specify `*/*` to delete all. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# POST /v1beta1/{beaconName}/attachments:batchDelete
# operationId: proximitybeacon.beacons.attachments.batchDelete
export def "v1beta1-attachments-batch-delete delete" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --namespaced-type: string # Specifies the namespace and type of attachments to delete in `namespace/type` format. Accepts `*/*` to specify "all types in all namespaces". Optional.
  --project-id: string # The project id to delete beacon attachments under. This field can be used when "*" is specified to mean all attachment namespaces. Projects may have multiple attachments with multiple namespaces. If "*" is specified and the projectId string is empty, then the project making the request is used. Optional.
]: nothing -> record<numDeleted: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "namespacedType" $namespaced_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}/attachments:batchDelete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "namespacedType": $namespaced_type, "projectId": $project_id} | compact), body: null}
}

# List the diagnostics for a single beacon. You can also list diagnostics for all the beacons owned by your Google Developers Console project by using the beacon name `beacons/-`. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **viewer**, **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# GET /v1beta1/{beaconName}/diagnostics
# operationId: proximitybeacon.beacons.diagnostics.list
export def "v1beta1-diagnostics list" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --alert-filter: string@alert-filter-completer # Requests only beacons that have the given alert. For example, to find beacons that have low batteries use `alert_filter=LOW_BATTERY`.
  --page-size: int # Specifies the maximum number of results to return. Defaults to 10. Maximum 1000. Optional.
  --page-token: string # Requests results that occur after the `page_token`, obtained from the response to a previous request. Optional.
  --project-id: string # Requests only diagnostic records for the given project id. If not set, then the project making the request will be used for looking up diagnostic records. Optional.
]: nothing -> record<diagnostics: table<alerts: list, beaconName: string, estimatedLowBatteryDate: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "alertFilter" $alert_filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}/diagnostics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "alertFilter": $alert_filter, "pageSize": $page_size, "pageToken": $page_token, "projectId": $project_id} | compact), body: null}
}

# Activates a beacon. A beacon that is active will return information and attachment data when queried via `beaconinfo.getforobserved`. Calling this method on an already active beacon will do nothing (but will return a successful response code). Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# POST /v1beta1/{beaconName}:activate
# operationId: proximitybeacon.beacons.activate
export def "v1beta1 create-activate" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the beacon to activate. If the project id is not specified then the project making the request is used. The project id must match the project that owns the beacon. Optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}:activate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: null}
}

# Deactivates a beacon. Once deactivated, the API will not return information nor attachment data for the beacon when queried via `beaconinfo.getforobserved`. Calling this method on an already inactive beacon will do nothing (but will return a successful response code). Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# POST /v1beta1/{beaconName}:deactivate
# operationId: proximitybeacon.beacons.deactivate
export def "v1beta1 create-deactivate" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the beacon to deactivate. If the project id is not specified then the project making the request is used. The project id must match the project that owns the beacon. Optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}:deactivate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: null}
}

# Decommissions the specified beacon in the service. This beacon will no longer be returned from `beaconinfo.getforobserved`. This operation is permanent -- you will not be able to re-register a beacon with this ID again. Authenticate using an [OAuth access token](https://developers.google.com/identity/protocols/OAuth2) from a signed-in user with **Is owner** or **Can edit** permissions in the Google Developers Console project.
#
# POST /v1beta1/{beaconName}:decommission
# operationId: proximitybeacon.beacons.decommission
export def "v1beta1 create-decommission" [
  beacon_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the beacon to decommission. If the project id is not specified then the project making the request is used. The project id must match the project that owns the beacon. Optional.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($beacon_name | is-empty) { error make --unspanned { msg: "path parameter 'beaconName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({beacon_name: (encode-path-segment $beacon_name)} | format pattern "/v1beta1/{beacon_name}:decommission") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: null}
}

# Updates the information about the specified namespace. Only the namespace visibility can be updated.
#
# PUT /v1beta1/{namespaceName}
# operationId: proximitybeacon.namespaces.update
export def "v1beta1 update-by-namespace-name" [
  namespace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project-id: string # The project id of the namespace to update. If the project id is not specified then the project making the request is used. The project id must match the project that owns the beacon. Optional.
  --body-namespace-name: string # Resource name of this namespace. Namespaces names have the format: namespaces/namespace.
  --serving-visibility: string@serving-visibility-completer # Specifies what clients may receive attachments under this namespace via `beaconinfo.getforobserved`.
]: any -> record<namespaceName: string, servingVisibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({namespace_name: (encode-path-segment $namespace_name)} | format pattern "/v1beta1/{namespace_name}") $qp)
  let req_body = {"namespaceName": $body_namespace_name, "servingVisibility": $serving_visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: $req_body}
}
