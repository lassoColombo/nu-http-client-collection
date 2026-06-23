# Auto-generated client for Admin SDK API vdirectory_v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/admin/directory_v1/openapi.json
# Auth: --token flag or $env.ADMIN_SDK_API_TOKEN

const BASE_URL = "https://admin.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADMIN_SDK_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://admin.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def order-by-completer [] { ["annotatedLocation" "annotatedUser" "lastSync" "notes" "serialNumber" "status"] }
def projection-completer [] { ["BASIC" "FULL"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def deprovision-reason-completer [] { ["deprovisionReasonDifferentModelReplacement" "deprovisionReasonDomainMove" "deprovisionReasonNotRequired" "deprovisionReasonOther" "deprovisionReasonRepairCenter" "deprovisionReasonRetiringDevice" "deprovisionReasonSameModelReplacement" "deprovisionReasonServiceExpiration" "deprovisionReasonUnspecified" "deprovisionReasonUpgrade" "deprovisionReasonUpgradeTransfer"] }
def command-type-completer [] { ["CAPTURE_LOGS" "COMMAND_TYPE_UNSPECIFIED" "DEVICE_START_CRD_SESSION" "REBOOT" "REMOTE_POWERWASH" "SET_VOLUME" "TAKE_A_SCREENSHOT" "WIPE_USERS"] }
def order-by-completer-1 [] { ["deviceId" "email" "lastSync" "model" "name" "os" "status" "type"] }
def type-completer [] { ["all" "children"] }
def coordinates-source-completer [] { ["CLIENT_SPECIFIED" "RESOLVED_FROM_ADDRESS" "SOURCE_UNSPECIFIED"] }
def order-by-completer-2 [] { ["email"] }
def event-completer [] { ["add" "delete" "makeAdmin" "undelete" "update"] }
def order-by-completer-3 [] { ["email" "familyName" "givenName"] }
def projection-completer-1 [] { ["basic" "custom" "full"] }
def view-type-completer [] { ["admin_view" "domain_public"] }
def event-completer-1 [] { ["add" "delete"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-directory-customer-devices-chromeos list" } } | get name | first)
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

# Retrieves a paginated list of Chrome OS devices within an account.
#
# GET /admin/directory/v1/customer/{customerId}/devices/chromeos
# operationId: directory.chromeosdevices.list
export def "admin-directory-customer-devices-chromeos list" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --include-child-orgunits: oneof<nothing, bool> # Return devices from all child orgunits, as well as the specified org unit. If this is set to true, 'orgUnitPath' must be provided.
  --max-results: int # Maximum number of results to return.
  --order-by: string@order-by-completer # Device property to use for sorting results.
  --org-unit-path: string # The full path of the organizational unit (minus the leading `/`) or its unique ID.
  --page-token: string # The `pageToken` query parameter is used to request the next page of query results. The follow-on request's `pageToken` query parameter is the `nextPageToken` from your previous response.
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --query: string # Search string in the format given at https://developers.google.com/admin-sdk/directory/v1/list-query-operators
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order. Must be used with the `orderBy` parameter.
]: nothing -> record<chromeosdevices: table<activeTimeRanges: list, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: list, cpuStatusReports: list, deprovisionReason: string, deviceFiles: list, deviceId: string, diskVolumeReports: list, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: list, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record, osVersion: string, platformVersion: string, recentUsers: list, screenshotFiles: list, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: list, systemRamTotal: string, tpmVersionInfo: record, willAutoRenew: bool>, etag: string, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "includeChildOrgunits" $include_child_orgunits "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "orgUnitPath" $org_unit_path "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sortOrder" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/chromeos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "includeChildOrgunits": $include_child_orgunits, "maxResults": $max_results, "orderBy": $order_by, "orgUnitPath": $org_unit_path, "pageToken": $page_token, "projection": $projection, "query": $query, "sortOrder": $sort_order} | compact), body: null}
}

# Moves or inserts multiple Chrome OS devices to an organizational unit. You can move up to 50 devices at once.
#
# POST /admin/directory/v1/customer/{customerId}/devices/chromeos/moveDevicesToOu
# operationId: directory.chromeosdevices.moveDevicesToOu
export def "admin-directory-customer-devices-chromeos-move-devices-to-ou move" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --org-unit-path: string # Full path of the target organizational unit or its ID
  --device-ids: list<string> # Chrome OS devices to be moved to OU
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "orgUnitPath" $org_unit_path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/chromeos/moveDevicesToOu") $qp)
  let req_body = {"deviceIds": $device_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "orgUnitPath": $org_unit_path} | compact), body: $req_body}
}

# Retrieves a Chrome OS device's properties.
#
# GET /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}
# operationId: directory.chromeosdevices.get
export def "admin-directory-customer-devices-chromeos get" [
  customer_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --projection: string@projection-completer # Determines whether the response contains the full list of properties or only a subset.
]: nothing -> record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projection" $projection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), device_id: (encode-path-segment $device_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/chromeos/{device_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projection": $projection} | compact), body: null}
}

# Updates a device's updatable properties, such as `annotatedUser`, `annotatedLocation`, `notes`, `orgUnitPath`, or `annotatedAssetId`. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch).
#
# PATCH /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}
# operationId: directory.chromeosdevices.patch
# --activeTimeRanges item shape: {activeTime?: int, date?: string}
# --cpuInfo item shape: {architecture?: string, logicalCpus?: list, maxClockSpeedKhz?: int, model?: string}
# --cpuStatusReports item shape: {cpuTemperatureInfo?: list, cpuUtilizationPercentageInfo?: list<int>, reportTime?: string}
# --deviceFiles item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
# --diskVolumeReports item shape: {volumeInfo?: list}
# --lastKnownNetwork item shape: {ipAddress?: string, wanIpAddress?: string}
# --osUpdateStatus shape: {rebootTime?: string, state?: "updateStateUnspecified"|"updateStateNotStarted"|"updateStateDownloadInProgress"|"updateStateNeedReboot", targetKioskAppVersion?: string, targetOsVersion?: string, updateCheckTime?: string, updateTime?: string}
# --recentUsers item shape: {email?: string, type?: string}
# --screenshotFiles item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
# --systemRamFreeReports item shape: {reportTime?: string, systemRamFreeInfo?: list<string>}
# --tpmVersionInfo shape: {family?: string, firmwareVersion?: string, manufacturer?: string, specLevel?: string, tpmModel?: string, vendorSpecific?: string}
export def "admin-directory-customer-devices-chromeos update-by-customer-id-device-id" [
  customer_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --active-time-ranges: list # A list of active time ranges (Read-only). — item shape: {activeTime?: int, date?: string}
  --annotated-asset-id: string # The asset identifier as noted by an administrator or specified during enrollment.
  --annotated-location: string # The address or location of the device as noted by the administrator. Maximum length is `200` characters. Empty values are allowed.
  --annotated-user: string # The user of the device as noted by the administrator. Maximum length is 100 characters. Empty values are allowed.
  --auto-update-expiration: string # (Read-only) The timestamp after which the device will stop receiving Chrome updates or support (format: int64)
  --boot-mode: string # The boot mode for the device. The possible values are: * `Verified`: The device is running a valid version of the Chrome OS. * `Dev`: The devices's developer hardware switch is enabled. When booted, the device has a command line shell. For an example of a developer switch, see the [Chromebook developer information](https://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices/samsung-series-5-chromebook#TOC-Developer-switch).
  --cpu-info: list # Information regarding CPU specs in the device. — item shape: {architecture?: string, logicalCpus?: list, maxClockSpeedKhz?: int, model?: string}
  --cpu-status-reports: list # Reports of CPU utilization and temperature (Read-only) — item shape: {cpuTemperatureInfo?: list, cpuUtilizationPercentageInfo?: list<int>, reportTime?: string}
  --deprovision-reason: string@deprovision-reason-completer # (Read-only) Deprovision reason.
  --device-files: list # A list of device files to download (Read-only) — item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
  --body-device-id: string # The unique ID of the Chrome device.
  --disk-volume-reports: list # Reports of disk space and other info about mounted/connected volumes. — item shape: {volumeInfo?: list}
  --dock-mac-address: string # (Read-only) Built-in MAC address for the docking station that the device connected to. Factory sets Media access control address (MAC address) assigned for use by a dock. It is reserved specifically for MAC pass through device policy. The format is twelve (12) hexadecimal digits without any delimiter (uppercase letters). This is only relevant for some devices.
  --etag: string # ETag of the resource.
  --ethernet-mac-address: string # The device's MAC address on the ethernet network interface.
  --ethernet-mac-address0: string # (Read-only) MAC address used by the Chromebook’s internal ethernet port, and for onboard network (ethernet) interface. The format is twelve (12) hexadecimal digits without any delimiter (uppercase letters). This is only relevant for some devices.
  --firmware-version: string # The Chrome device's firmware version.
  --first-enrollment-time: string # Date and time for the first time the device was enrolled.
  --kind: string # The type of resource. For the Chromeosdevices resource, the value is `admin#directory#chromeosdevice`. (default: admin#directory#chromeosdevice)
  --last-deprovision-timestamp: string # (Read-only) Date and time for the last deprovision of the device.
  --last-enrollment-time: string # Date and time the device was last enrolled (Read-only) (format: date-time)
  --last-known-network: list # Contains last known network (Read-only) — item shape: {ipAddress?: string, wanIpAddress?: string}
  --last-sync: string # Date and time the device was last synchronized with the policy settings in the G Suite administrator control panel (Read-only) (format: date-time)
  --mac-address: string # The device's wireless MAC address. If the device does not have this information, it is not included in the response.
  --manufacture-date: string # (Read-only) The date the device was manufactured in yyyy-mm-dd format.
  --meid: string # The Mobile Equipment Identifier (MEID) or the International Mobile Equipment Identity (IMEI) for the 3G mobile card in a mobile device. A MEID/IMEI is typically used when adding a device to a wireless carrier's post-pay service plan. If the device does not have this information, this property is not included in the response. For more information on how to export a MEID/IMEI list, see the [Developer's Guide](/admin-sdk/directory/v1/guides/manage-chrome-devices.html#export_meid).
  --model: string # The device's model information. If the device does not have this information, this property is not included in the response.
  --notes: string # Notes about this device added by the administrator. This property can be [searched](https://support.google.com/chrome/a/answer/1698333) with the [list](/admin-sdk/directory/v1/reference/chromeosdevices/list) method's `query` parameter. Maximum length is 500 characters. Empty values are allowed.
  --order-number: string # The device's order number. Only devices directly purchased from Google have an order number.
  --org-unit-id: string # The unique ID of the organizational unit. orgUnitPath is the human readable version of orgUnitId. While orgUnitPath may change by renaming an organizational unit within the path, orgUnitId is unchangeable for one organizational unit. This property can be [updated](/admin-sdk/directory/v1/guides/manage-chrome-devices#move_chrome_devices_to_ou) using the API. For more information about how to create an organizational structure for your device, see the [administration help center](https://support.google.com/a/answer/182433).
  --org-unit-path: string # The full parent path with the organizational unit's name associated with the device. Path names are case insensitive. If the parent organizational unit is the top-level organization, it is represented as a forward slash, `/`. This property can be [updated](/admin-sdk/directory/v1/guides/manage-chrome-devices#move_chrome_devices_to_ou) using the API. For more information about how to create an organizational structure for your device, see the [administration help center](https://support.google.com/a/answer/182433).
  --os-update-status: record # Contains information regarding the current OS update status. — shape: {rebootTime?: string, state?: "updateStateUnspecified"|"updateStateNotStarted"|"updateStateDownloadInProgress"|"updateStateNeedReboot", targetKioskAppVersion?: string, targetOsVersion?: string, updateCheckTime?: string, updateTime?: string}
  --os-version: string # The Chrome device's operating system version.
  --platform-version: string # The Chrome device's platform version.
  --recent-users: list # A list of recent device users, in descending order, by last login time. — item shape: {email?: string, type?: string}
  --screenshot-files: list # A list of screenshot files to download. Type is always "SCREENSHOT_FILE". (Read-only) — item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
  --serial-number: string # The Chrome device serial number entered when the device was enabled. This value is the same as the Admin console's *Serial Number* in the *Chrome OS Devices* tab.
  --status: string # The status of the device.
  --support-end-date: string # Final date the device will be supported (Read-only) (format: date-time)
  --system-ram-free-reports: list # Reports of amounts of available RAM memory (Read-only) — item shape: {reportTime?: string, systemRamFreeInfo?: list<string>}
  --system-ram-total: string # Total RAM on the device [in bytes] (Read-only) (format: int64)
  --tpm-version-info: record # Trusted Platform Module (TPM) (Read-only) — shape: {family?: string, firmwareVersion?: string, manufacturer?: string, specLevel?: string, tpmModel?: string, vendorSpecific?: string}
  --will-auto-renew: oneof<nothing, bool> # Determines if the device will auto renew its support after the support end date. This is a read-only property.
]: any -> record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projection" $projection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), device_id: (encode-path-segment $device_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/chromeos/{device_id}") $qp)
  let req_body = {"activeTimeRanges": $active_time_ranges, "annotatedAssetId": $annotated_asset_id, "annotatedLocation": $annotated_location, "annotatedUser": $annotated_user, "autoUpdateExpiration": $auto_update_expiration, "bootMode": $boot_mode, "cpuInfo": $cpu_info, "cpuStatusReports": $cpu_status_reports, "deprovisionReason": $deprovision_reason, "deviceFiles": $device_files, "deviceId": $body_device_id, "diskVolumeReports": $disk_volume_reports, "dockMacAddress": $dock_mac_address, "etag": $etag, "ethernetMacAddress": $ethernet_mac_address, "ethernetMacAddress0": $ethernet_mac_address0, "firmwareVersion": $firmware_version, "firstEnrollmentTime": $first_enrollment_time, "kind": $kind, "lastDeprovisionTimestamp": $last_deprovision_timestamp, "lastEnrollmentTime": $last_enrollment_time, "lastKnownNetwork": $last_known_network, "lastSync": $last_sync, "macAddress": $mac_address, "manufactureDate": $manufacture_date, "meid": $meid, "model": $model, "notes": $notes, "orderNumber": $order_number, "orgUnitId": $org_unit_id, "orgUnitPath": $org_unit_path, "osUpdateStatus": $os_update_status, "osVersion": $os_version, "platformVersion": $platform_version, "recentUsers": $recent_users, "screenshotFiles": $screenshot_files, "serialNumber": $serial_number, "status": $status, "supportEndDate": $support_end_date, "systemRamFreeReports": $system_ram_free_reports, "systemRamTotal": $system_ram_total, "tpmVersionInfo": $tpm_version_info, "willAutoRenew": $will_auto_renew} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projection": $projection} | compact), body: $req_body}
}

# Updates a device's updatable properties, such as `annotatedUser`, `annotatedLocation`, `notes`, `orgUnitPath`, or `annotatedAssetId`.
#
# PUT /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}
# operationId: directory.chromeosdevices.update
# --activeTimeRanges item shape: {activeTime?: int, date?: string}
# --cpuInfo item shape: {architecture?: string, logicalCpus?: list, maxClockSpeedKhz?: int, model?: string}
# --cpuStatusReports item shape: {cpuTemperatureInfo?: list, cpuUtilizationPercentageInfo?: list<int>, reportTime?: string}
# --deviceFiles item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
# --diskVolumeReports item shape: {volumeInfo?: list}
# --lastKnownNetwork item shape: {ipAddress?: string, wanIpAddress?: string}
# --osUpdateStatus shape: {rebootTime?: string, state?: "updateStateUnspecified"|"updateStateNotStarted"|"updateStateDownloadInProgress"|"updateStateNeedReboot", targetKioskAppVersion?: string, targetOsVersion?: string, updateCheckTime?: string, updateTime?: string}
# --recentUsers item shape: {email?: string, type?: string}
# --screenshotFiles item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
# --systemRamFreeReports item shape: {reportTime?: string, systemRamFreeInfo?: list<string>}
# --tpmVersionInfo shape: {family?: string, firmwareVersion?: string, manufacturer?: string, specLevel?: string, tpmModel?: string, vendorSpecific?: string}
export def "admin-directory-customer-devices-chromeos update-by-customer-id-device-id-1" [
  customer_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --active-time-ranges: list # A list of active time ranges (Read-only). — item shape: {activeTime?: int, date?: string}
  --annotated-asset-id: string # The asset identifier as noted by an administrator or specified during enrollment.
  --annotated-location: string # The address or location of the device as noted by the administrator. Maximum length is `200` characters. Empty values are allowed.
  --annotated-user: string # The user of the device as noted by the administrator. Maximum length is 100 characters. Empty values are allowed.
  --auto-update-expiration: string # (Read-only) The timestamp after which the device will stop receiving Chrome updates or support (format: int64)
  --boot-mode: string # The boot mode for the device. The possible values are: * `Verified`: The device is running a valid version of the Chrome OS. * `Dev`: The devices's developer hardware switch is enabled. When booted, the device has a command line shell. For an example of a developer switch, see the [Chromebook developer information](https://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices/samsung-series-5-chromebook#TOC-Developer-switch).
  --cpu-info: list # Information regarding CPU specs in the device. — item shape: {architecture?: string, logicalCpus?: list, maxClockSpeedKhz?: int, model?: string}
  --cpu-status-reports: list # Reports of CPU utilization and temperature (Read-only) — item shape: {cpuTemperatureInfo?: list, cpuUtilizationPercentageInfo?: list<int>, reportTime?: string}
  --deprovision-reason: string@deprovision-reason-completer # (Read-only) Deprovision reason.
  --device-files: list # A list of device files to download (Read-only) — item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
  --body-device-id: string # The unique ID of the Chrome device.
  --disk-volume-reports: list # Reports of disk space and other info about mounted/connected volumes. — item shape: {volumeInfo?: list}
  --dock-mac-address: string # (Read-only) Built-in MAC address for the docking station that the device connected to. Factory sets Media access control address (MAC address) assigned for use by a dock. It is reserved specifically for MAC pass through device policy. The format is twelve (12) hexadecimal digits without any delimiter (uppercase letters). This is only relevant for some devices.
  --etag: string # ETag of the resource.
  --ethernet-mac-address: string # The device's MAC address on the ethernet network interface.
  --ethernet-mac-address0: string # (Read-only) MAC address used by the Chromebook’s internal ethernet port, and for onboard network (ethernet) interface. The format is twelve (12) hexadecimal digits without any delimiter (uppercase letters). This is only relevant for some devices.
  --firmware-version: string # The Chrome device's firmware version.
  --first-enrollment-time: string # Date and time for the first time the device was enrolled.
  --kind: string # The type of resource. For the Chromeosdevices resource, the value is `admin#directory#chromeosdevice`. (default: admin#directory#chromeosdevice)
  --last-deprovision-timestamp: string # (Read-only) Date and time for the last deprovision of the device.
  --last-enrollment-time: string # Date and time the device was last enrolled (Read-only) (format: date-time)
  --last-known-network: list # Contains last known network (Read-only) — item shape: {ipAddress?: string, wanIpAddress?: string}
  --last-sync: string # Date and time the device was last synchronized with the policy settings in the G Suite administrator control panel (Read-only) (format: date-time)
  --mac-address: string # The device's wireless MAC address. If the device does not have this information, it is not included in the response.
  --manufacture-date: string # (Read-only) The date the device was manufactured in yyyy-mm-dd format.
  --meid: string # The Mobile Equipment Identifier (MEID) or the International Mobile Equipment Identity (IMEI) for the 3G mobile card in a mobile device. A MEID/IMEI is typically used when adding a device to a wireless carrier's post-pay service plan. If the device does not have this information, this property is not included in the response. For more information on how to export a MEID/IMEI list, see the [Developer's Guide](/admin-sdk/directory/v1/guides/manage-chrome-devices.html#export_meid).
  --model: string # The device's model information. If the device does not have this information, this property is not included in the response.
  --notes: string # Notes about this device added by the administrator. This property can be [searched](https://support.google.com/chrome/a/answer/1698333) with the [list](/admin-sdk/directory/v1/reference/chromeosdevices/list) method's `query` parameter. Maximum length is 500 characters. Empty values are allowed.
  --order-number: string # The device's order number. Only devices directly purchased from Google have an order number.
  --org-unit-id: string # The unique ID of the organizational unit. orgUnitPath is the human readable version of orgUnitId. While orgUnitPath may change by renaming an organizational unit within the path, orgUnitId is unchangeable for one organizational unit. This property can be [updated](/admin-sdk/directory/v1/guides/manage-chrome-devices#move_chrome_devices_to_ou) using the API. For more information about how to create an organizational structure for your device, see the [administration help center](https://support.google.com/a/answer/182433).
  --org-unit-path: string # The full parent path with the organizational unit's name associated with the device. Path names are case insensitive. If the parent organizational unit is the top-level organization, it is represented as a forward slash, `/`. This property can be [updated](/admin-sdk/directory/v1/guides/manage-chrome-devices#move_chrome_devices_to_ou) using the API. For more information about how to create an organizational structure for your device, see the [administration help center](https://support.google.com/a/answer/182433).
  --os-update-status: record # Contains information regarding the current OS update status. — shape: {rebootTime?: string, state?: "updateStateUnspecified"|"updateStateNotStarted"|"updateStateDownloadInProgress"|"updateStateNeedReboot", targetKioskAppVersion?: string, targetOsVersion?: string, updateCheckTime?: string, updateTime?: string}
  --os-version: string # The Chrome device's operating system version.
  --platform-version: string # The Chrome device's platform version.
  --recent-users: list # A list of recent device users, in descending order, by last login time. — item shape: {email?: string, type?: string}
  --screenshot-files: list # A list of screenshot files to download. Type is always "SCREENSHOT_FILE". (Read-only) — item shape: {createTime?: string, downloadUrl?: string, name?: string, type?: string}
  --serial-number: string # The Chrome device serial number entered when the device was enabled. This value is the same as the Admin console's *Serial Number* in the *Chrome OS Devices* tab.
  --status: string # The status of the device.
  --support-end-date: string # Final date the device will be supported (Read-only) (format: date-time)
  --system-ram-free-reports: list # Reports of amounts of available RAM memory (Read-only) — item shape: {reportTime?: string, systemRamFreeInfo?: list<string>}
  --system-ram-total: string # Total RAM on the device [in bytes] (Read-only) (format: int64)
  --tpm-version-info: record # Trusted Platform Module (TPM) (Read-only) — shape: {family?: string, firmwareVersion?: string, manufacturer?: string, specLevel?: string, tpmModel?: string, vendorSpecific?: string}
  --will-auto-renew: oneof<nothing, bool> # Determines if the device will auto renew its support after the support end date. This is a read-only property.
]: any -> record<activeTimeRanges: table<activeTime: int, date: string>, annotatedAssetId: string, annotatedLocation: string, annotatedUser: string, autoUpdateExpiration: string, bootMode: string, cpuInfo: table<architecture: string, logicalCpus: list, maxClockSpeedKhz: int, model: string>, cpuStatusReports: table<cpuTemperatureInfo: list, cpuUtilizationPercentageInfo: list, reportTime: string>, deprovisionReason: string, deviceFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, deviceId: string, diskVolumeReports: table<volumeInfo: list>, dockMacAddress: string, etag: string, ethernetMacAddress: string, ethernetMacAddress0: string, firmwareVersion: string, firstEnrollmentTime: string, kind: string, lastDeprovisionTimestamp: string, lastEnrollmentTime: string, lastKnownNetwork: table<ipAddress: string, wanIpAddress: string>, lastSync: string, macAddress: string, manufactureDate: string, meid: string, model: string, notes: string, orderNumber: string, orgUnitId: string, orgUnitPath: string, osUpdateStatus: record<rebootTime: string, state: string, targetKioskAppVersion: string, targetOsVersion: string, updateCheckTime: string, updateTime: string>, osVersion: string, platformVersion: string, recentUsers: table<email: string, type: string>, screenshotFiles: table<createTime: string, downloadUrl: string, name: string, type: string>, serialNumber: string, status: string, supportEndDate: string, systemRamFreeReports: table<reportTime: string, systemRamFreeInfo: list>, systemRamTotal: string, tpmVersionInfo: record<family: string, firmwareVersion: string, manufacturer: string, specLevel: string, tpmModel: string, vendorSpecific: string>, willAutoRenew: bool> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projection" $projection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), device_id: (encode-path-segment $device_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/chromeos/{device_id}") $qp)
  let req_body = {"activeTimeRanges": $active_time_ranges, "annotatedAssetId": $annotated_asset_id, "annotatedLocation": $annotated_location, "annotatedUser": $annotated_user, "autoUpdateExpiration": $auto_update_expiration, "bootMode": $boot_mode, "cpuInfo": $cpu_info, "cpuStatusReports": $cpu_status_reports, "deprovisionReason": $deprovision_reason, "deviceFiles": $device_files, "deviceId": $body_device_id, "diskVolumeReports": $disk_volume_reports, "dockMacAddress": $dock_mac_address, "etag": $etag, "ethernetMacAddress": $ethernet_mac_address, "ethernetMacAddress0": $ethernet_mac_address0, "firmwareVersion": $firmware_version, "firstEnrollmentTime": $first_enrollment_time, "kind": $kind, "lastDeprovisionTimestamp": $last_deprovision_timestamp, "lastEnrollmentTime": $last_enrollment_time, "lastKnownNetwork": $last_known_network, "lastSync": $last_sync, "macAddress": $mac_address, "manufactureDate": $manufacture_date, "meid": $meid, "model": $model, "notes": $notes, "orderNumber": $order_number, "orgUnitId": $org_unit_id, "orgUnitPath": $org_unit_path, "osUpdateStatus": $os_update_status, "osVersion": $os_version, "platformVersion": $platform_version, "recentUsers": $recent_users, "screenshotFiles": $screenshot_files, "serialNumber": $serial_number, "status": $status, "supportEndDate": $support_end_date, "systemRamFreeReports": $system_ram_free_reports, "systemRamTotal": $system_ram_total, "tpmVersionInfo": $tpm_version_info, "willAutoRenew": $will_auto_renew} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projection": $projection} | compact), body: $req_body}
}

# Gets command data a specific command issued to the device.
#
# GET /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}/commands/{commandId}
# operationId: admin.customer.devices.chromeos.commands.get
export def "admin-directory-customer-devices-chromeos-commands get" [
  customer_id: string
  device_id: string
  command_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<commandExpireTime: string, commandId: string, commandResult: record<commandResultPayload: string, errorMessage: string, executeTime: string, result: string>, issueTime: string, payload: string, state: string, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  if ($command_id | is-empty) { error make --unspanned { msg: "path parameter 'commandId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), device_id: (encode-path-segment $device_id), command_id: (encode-path-segment $command_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/chromeos/{device_id}/commands/{command_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Issues a command for the device to execute.
#
# POST /admin/directory/v1/customer/{customerId}/devices/chromeos/{deviceId}:issueCommand
# operationId: admin.customer.devices.chromeos.issueCommand
export def "admin-directory-customer-devices-chromeos create-issue-command" [
  customer_id: string
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --command-type: string@command-type-completer # The type of command.
  --payload: string # The payload for the command, provide it only if command supports it. The following commands support adding payload: * `SET_VOLUME`: Payload is a stringified JSON object in the form: { "volume": 50 }. The volume has to be an integer in the range [0,100]. * `DEVICE_START_CRD_SESSION`: Payload is optionally a stringified JSON object in the form: { "ackedUserPresence": true }. `ackedUserPresence` is a boolean. By default, `ackedUserPresence` is set to `false`. To start a Chrome Remote Desktop session for an active device, set `ackedUserPresence` to `true`.
]: any -> record<commandId: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'deviceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), device_id: (encode-path-segment $device_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/chromeos/{device_id}:issueCommand") $qp)
  let req_body = {"commandType": $command_type, "payload": $payload} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Takes an action that affects a Chrome OS Device. This includes deprovisioning, disabling, and re-enabling devices. *Warning:* * Deprovisioning a device will stop device policy syncing and remove device-level printers. After a device is deprovisioned, it must be wiped before it can be re-enrolled. * Lost or stolen devices should use the disable action. * Re-enabling a disabled device will consume a device license. If you do not have sufficient licenses available when completing the re-enable action, you will receive an error. For more information about deprovisioning and disabling devices, visit the [help center](https://support.google.com/chrome/a/answer/3523633).
#
# POST /admin/directory/v1/customer/{customerId}/devices/chromeos/{resourceId}/action
# operationId: directory.chromeosdevices.action
export def "admin-directory-customer-devices-chromeos-action create" [
  customer_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --action: string # Action to be taken on the Chrome OS device.
  --deprovision-reason: string # Only used when the action is `deprovision`. With the `deprovision` action, this field is required. *Note*: The deprovision reason is audited because it might have implications on licenses for perpetual subscription customers.
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/chromeos/{resource_id}/action") $qp)
  let req_body = {"action": $action, "deprovisionReason": $deprovision_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves a paginated list of all user-owned mobile devices for an account. To retrieve a list that includes company-owned devices, use the Cloud Identity [Devices API](https://cloud.google.com/identity/docs/concepts/overview-devices) instead. This method times out after 60 minutes. For more information, see [Troubleshoot error codes](https://developers.google.com/admin-sdk/directory/v1/guides/troubleshoot-error-codes).
#
# GET /admin/directory/v1/customer/{customerId}/devices/mobile
# operationId: directory.mobiledevices.list
export def "admin-directory-customer-devices-mobile list" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --max-results: int # Maximum number of results to return. Max allowed value is 100.
  --order-by: string@order-by-completer-1 # Device property to use for sorting results.
  --page-token: string # Token to specify next page in the list
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
  --query: string # Search string in the format given at https://developers.google.com/admin-sdk/directory/v1/search-operators
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order. Must be used with the `orderBy` parameter.
]: nothing -> record<etag: string, kind: string, mobiledevices: table<adbStatus: bool, applications: list, basebandVersion: string, bootloaderVersion: string, brand: string, buildNumber: string, defaultLanguage: string, developerOptionsStatus: bool, deviceCompromisedStatus: string, deviceId: string, devicePasswordStatus: string, email: list, encryptionStatus: string, etag: string, firstSync: string, hardware: string, hardwareId: string, imei: string, kernelVersion: string, kind: string, lastSync: string, managedAccountIsOnOwnerProfile: bool, manufacturer: string, meid: string, model: string, name: list, networkOperator: string, os: string, otherAccountsInfo: list, privilege: string, releaseVersion: string, resourceId: string, securityPatchLevel: string, serialNumber: string, status: string, supportsWorkProfile: bool, type: string, unknownSourcesStatus: bool, userAgent: string, wifiMacAddress: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sortOrder" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/mobile") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "orderBy": $order_by, "pageToken": $page_token, "projection": $projection, "query": $query, "sortOrder": $sort_order} | compact), body: null}
}

# Removes a mobile device.
#
# DELETE /admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}
# operationId: directory.mobiledevices.delete
export def "admin-directory-customer-devices-mobile delete" [
  customer_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/mobile/{resource_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a mobile device's properties.
#
# GET /admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}
# operationId: directory.mobiledevices.get
export def "admin-directory-customer-devices-mobile get" [
  customer_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --projection: string@projection-completer # Restrict information returned to a set of selected fields.
]: nothing -> record<adbStatus: bool, applications: table<displayName: string, packageName: string, permission: list, versionCode: int, versionName: string>, basebandVersion: string, bootloaderVersion: string, brand: string, buildNumber: string, defaultLanguage: string, developerOptionsStatus: bool, deviceCompromisedStatus: string, deviceId: string, devicePasswordStatus: string, email: list<string>, encryptionStatus: string, etag: string, firstSync: string, hardware: string, hardwareId: string, imei: string, kernelVersion: string, kind: string, lastSync: string, managedAccountIsOnOwnerProfile: bool, manufacturer: string, meid: string, model: string, name: list<string>, networkOperator: string, os: string, otherAccountsInfo: list<string>, privilege: string, releaseVersion: string, resourceId: string, securityPatchLevel: string, serialNumber: string, status: string, supportsWorkProfile: bool, type: string, unknownSourcesStatus: bool, userAgent: string, wifiMacAddress: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projection" $projection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/mobile/{resource_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projection": $projection} | compact), body: null}
}

# Takes an action that affects a mobile device. For example, remotely wiping a device.
#
# POST /admin/directory/v1/customer/{customerId}/devices/mobile/{resourceId}/action
# operationId: directory.mobiledevices.action
export def "admin-directory-customer-devices-mobile-action create" [
  customer_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --action: string # The action to be performed on the device.
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), resource_id: (encode-path-segment $resource_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/devices/mobile/{resource_id}/action") $qp)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves a list of all organizational units for an account.
#
# GET /admin/directory/v1/customer/{customerId}/orgunits
# operationId: directory.orgunits.list
export def "admin-directory-customer-orgunits list" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --org-unit-path: string # The full path to the organizational unit or its unique ID. Returns the children of the specified organizational unit.
  --type: string@type-completer # Whether to return all sub-organizations or just immediate children.
]: nothing -> record<etag: string, kind: string, organizationUnits: table<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "orgUnitPath" $org_unit_path "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/orgunits") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "orgUnitPath": $org_unit_path, "type": $type} | compact), body: null}
}

# Adds an organizational unit.
#
# POST /admin/directory/v1/customer/{customerId}/orgunits
# operationId: directory.orgunits.insert
export def "admin-directory-customer-orgunits create" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --block-inheritance: oneof<nothing, bool> # Determines if a sub-organizational unit can inherit the settings of the parent organization. The default value is `false`, meaning a sub-organizational unit inherits the settings of the nearest parent organizational unit. For more information on inheritance and users in an organization structure, see the [administration help center](https://support.google.com/a/answer/4352075).
  --description: string # Description of the organizational unit.
  --etag: string # ETag of the resource.
  --kind: string # The type of the API resource. For Orgunits resources, the value is `admin#directory#orgUnit`. (default: admin#directory#orgUnit)
  --name: string # The organizational unit's path name. For example, an organizational unit's name within the /corp/support/sales_support parent path is sales_support. Required.
  --org-unit-id: string # The unique ID of the organizational unit.
  --org-unit-path: string # The full path to the organizational unit. The `orgUnitPath` is a derived property. When listed, it is derived from `parentOrgunitPath` and organizational unit's `name`. For example, for an organizational unit named 'apps' under parent organization '/engineering', the orgUnitPath is '/engineering/apps'. In order to edit an `orgUnitPath`, either update the name of the organization or the `parentOrgunitPath`. A user's organizational unit determines which Google Workspace services the user has access to. If the user is moved to a new organization, the user's access changes. For more information about organization structures, see the [administration help center](https://support.google.com/a/answer/4352075). For more information about moving a user to a different organization, see [Update a user](/admin-sdk/directory/v1/guides/manage-users.html#update_user).
  --parent-org-unit-id: string # The unique ID of the parent organizational unit. Required, unless `parentOrgUnitPath` is set.
  --parent-org-unit-path: string # The organizational unit's parent path. For example, /corp/sales is the parent path for /corp/sales/sales_support organizational unit. Required, unless `parentOrgUnitId` is set.
]: any -> record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/orgunits") $qp)
  let req_body = {"blockInheritance": $block_inheritance, "description": $description, "etag": $etag, "kind": $kind, "name": $name, "orgUnitId": $org_unit_id, "orgUnitPath": $org_unit_path, "parentOrgUnitId": $parent_org_unit_id, "parentOrgUnitPath": $parent_org_unit_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Removes an organizational unit.
#
# DELETE /admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}
# operationId: directory.orgunits.delete
export def "admin-directory-customer-orgunits delete" [
  customer_id: string
  org_unit_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($org_unit_path | is-empty) { error make --unspanned { msg: "path parameter 'orgUnitPath' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), org_unit_path: (encode-path-segment $org_unit_path)} | format pattern "/admin/directory/v1/customer/{customer_id}/orgunits/{org_unit_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves an organizational unit.
#
# GET /admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}
# operationId: directory.orgunits.get
export def "admin-directory-customer-orgunits get" [
  customer_id: string
  org_unit_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($org_unit_path | is-empty) { error make --unspanned { msg: "path parameter 'orgUnitPath' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), org_unit_path: (encode-path-segment $org_unit_path)} | format pattern "/admin/directory/v1/customer/{customer_id}/orgunits/{org_unit_path}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates an organizational unit. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch)
#
# PATCH /admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}
# operationId: directory.orgunits.patch
export def "admin-directory-customer-orgunits update-by-customer-id-org-unit-path" [
  customer_id: string
  org_unit_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --block-inheritance: oneof<nothing, bool> # Determines if a sub-organizational unit can inherit the settings of the parent organization. The default value is `false`, meaning a sub-organizational unit inherits the settings of the nearest parent organizational unit. For more information on inheritance and users in an organization structure, see the [administration help center](https://support.google.com/a/answer/4352075).
  --description: string # Description of the organizational unit.
  --etag: string # ETag of the resource.
  --kind: string # The type of the API resource. For Orgunits resources, the value is `admin#directory#orgUnit`. (default: admin#directory#orgUnit)
  --name: string # The organizational unit's path name. For example, an organizational unit's name within the /corp/support/sales_support parent path is sales_support. Required.
  --org-unit-id: string # The unique ID of the organizational unit.
  --body-org-unit-path: string # The full path to the organizational unit. The `orgUnitPath` is a derived property. When listed, it is derived from `parentOrgunitPath` and organizational unit's `name`. For example, for an organizational unit named 'apps' under parent organization '/engineering', the orgUnitPath is '/engineering/apps'. In order to edit an `orgUnitPath`, either update the name of the organization or the `parentOrgunitPath`. A user's organizational unit determines which Google Workspace services the user has access to. If the user is moved to a new organization, the user's access changes. For more information about organization structures, see the [administration help center](https://support.google.com/a/answer/4352075). For more information about moving a user to a different organization, see [Update a user](/admin-sdk/directory/v1/guides/manage-users.html#update_user).
  --parent-org-unit-id: string # The unique ID of the parent organizational unit. Required, unless `parentOrgUnitPath` is set.
  --parent-org-unit-path: string # The organizational unit's parent path. For example, /corp/sales is the parent path for /corp/sales/sales_support organizational unit. Required, unless `parentOrgUnitId` is set.
]: any -> record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($org_unit_path | is-empty) { error make --unspanned { msg: "path parameter 'orgUnitPath' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), org_unit_path: (encode-path-segment $org_unit_path)} | format pattern "/admin/directory/v1/customer/{customer_id}/orgunits/{org_unit_path}") $qp)
  let req_body = {"blockInheritance": $block_inheritance, "description": $description, "etag": $etag, "kind": $kind, "name": $name, "orgUnitId": $org_unit_id, "orgUnitPath": $body_org_unit_path, "parentOrgUnitId": $parent_org_unit_id, "parentOrgUnitPath": $parent_org_unit_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates an organizational unit.
#
# PUT /admin/directory/v1/customer/{customerId}/orgunits/{orgUnitPath}
# operationId: directory.orgunits.update
export def "admin-directory-customer-orgunits update-by-customer-id-org-unit-path-1" [
  customer_id: string
  org_unit_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --block-inheritance: oneof<nothing, bool> # Determines if a sub-organizational unit can inherit the settings of the parent organization. The default value is `false`, meaning a sub-organizational unit inherits the settings of the nearest parent organizational unit. For more information on inheritance and users in an organization structure, see the [administration help center](https://support.google.com/a/answer/4352075).
  --description: string # Description of the organizational unit.
  --etag: string # ETag of the resource.
  --kind: string # The type of the API resource. For Orgunits resources, the value is `admin#directory#orgUnit`. (default: admin#directory#orgUnit)
  --name: string # The organizational unit's path name. For example, an organizational unit's name within the /corp/support/sales_support parent path is sales_support. Required.
  --org-unit-id: string # The unique ID of the organizational unit.
  --body-org-unit-path: string # The full path to the organizational unit. The `orgUnitPath` is a derived property. When listed, it is derived from `parentOrgunitPath` and organizational unit's `name`. For example, for an organizational unit named 'apps' under parent organization '/engineering', the orgUnitPath is '/engineering/apps'. In order to edit an `orgUnitPath`, either update the name of the organization or the `parentOrgunitPath`. A user's organizational unit determines which Google Workspace services the user has access to. If the user is moved to a new organization, the user's access changes. For more information about organization structures, see the [administration help center](https://support.google.com/a/answer/4352075). For more information about moving a user to a different organization, see [Update a user](/admin-sdk/directory/v1/guides/manage-users.html#update_user).
  --parent-org-unit-id: string # The unique ID of the parent organizational unit. Required, unless `parentOrgUnitPath` is set.
  --parent-org-unit-path: string # The organizational unit's parent path. For example, /corp/sales is the parent path for /corp/sales/sales_support organizational unit. Required, unless `parentOrgUnitId` is set.
]: any -> record<blockInheritance: bool, description: string, etag: string, kind: string, name: string, orgUnitId: string, orgUnitPath: string, parentOrgUnitId: string, parentOrgUnitPath: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($org_unit_path | is-empty) { error make --unspanned { msg: "path parameter 'orgUnitPath' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), org_unit_path: (encode-path-segment $org_unit_path)} | format pattern "/admin/directory/v1/customer/{customer_id}/orgunits/{org_unit_path}") $qp)
  let req_body = {"blockInheritance": $block_inheritance, "description": $description, "etag": $etag, "kind": $kind, "name": $name, "orgUnitId": $org_unit_id, "orgUnitPath": $body_org_unit_path, "parentOrgUnitId": $parent_org_unit_id, "parentOrgUnitPath": $parent_org_unit_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves all schemas for a customer.
#
# GET /admin/directory/v1/customer/{customerId}/schemas
# operationId: directory.schemas.list
export def "admin-directory-customer-schemas list" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<etag: string, kind: string, schemas: table<displayName: string, etag: string, fields: list, kind: string, schemaId: string, schemaName: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/schemas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Creates a schema.
#
# POST /admin/directory/v1/customer/{customerId}/schemas
# operationId: directory.schemas.insert
# --fields item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string}
export def "admin-directory-customer-schemas create" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --fields: string # Selector specifying which fields to include in a partial response. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string}
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --display-name: string # Display name for the schema.
  --etag: string # The ETag of the resource.
  --fields-body: list # A list of fields in the schema. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string} (body field)
  --kind: string # Kind of resource this is. (default: admin#directory#schema)
  --schema-id: string # The unique identifier of the schema (Read-only)
  --schema-name: string # The schema's name. Each `schema_name` must be unique within a customer. Reusing a name results in a `409: Entity already exists` error.
]: any -> record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/admin/directory/v1/customer/{customer_id}/schemas") $qp)
  let req_body = {"displayName": $display_name, "etag": $etag, "fields": $fields_body, "kind": $kind, "schemaId": $schema_id, "schemaName": $schema_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a schema.
#
# DELETE /admin/directory/v1/customer/{customerId}/schemas/{schemaKey}
# operationId: directory.schemas.delete
export def "admin-directory-customer-schemas delete" [
  customer_id: string
  schema_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($schema_key | is-empty) { error make --unspanned { msg: "path parameter 'schemaKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), schema_key: (encode-path-segment $schema_key)} | format pattern "/admin/directory/v1/customer/{customer_id}/schemas/{schema_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a schema.
#
# GET /admin/directory/v1/customer/{customerId}/schemas/{schemaKey}
# operationId: directory.schemas.get
export def "admin-directory-customer-schemas get" [
  customer_id: string
  schema_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($schema_key | is-empty) { error make --unspanned { msg: "path parameter 'schemaKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), schema_key: (encode-path-segment $schema_key)} | format pattern "/admin/directory/v1/customer/{customer_id}/schemas/{schema_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Patches a schema.
#
# PATCH /admin/directory/v1/customer/{customerId}/schemas/{schemaKey}
# operationId: directory.schemas.patch
# --fields item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string}
export def "admin-directory-customer-schemas update-by-customer-id-schema-key" [
  customer_id: string
  schema_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --fields: string # Selector specifying which fields to include in a partial response. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string}
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --display-name: string # Display name for the schema.
  --etag: string # The ETag of the resource.
  --fields-body: list # A list of fields in the schema. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string} (body field)
  --kind: string # Kind of resource this is. (default: admin#directory#schema)
  --schema-id: string # The unique identifier of the schema (Read-only)
  --schema-name: string # The schema's name. Each `schema_name` must be unique within a customer. Reusing a name results in a `409: Entity already exists` error.
]: any -> record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($schema_key | is-empty) { error make --unspanned { msg: "path parameter 'schemaKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), schema_key: (encode-path-segment $schema_key)} | format pattern "/admin/directory/v1/customer/{customer_id}/schemas/{schema_key}") $qp)
  let req_body = {"displayName": $display_name, "etag": $etag, "fields": $fields_body, "kind": $kind, "schemaId": $schema_id, "schemaName": $schema_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates a schema.
#
# PUT /admin/directory/v1/customer/{customerId}/schemas/{schemaKey}
# operationId: directory.schemas.update
# --fields item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string}
export def "admin-directory-customer-schemas update-by-customer-id-schema-key-1" [
  customer_id: string
  schema_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --fields: string # Selector specifying which fields to include in a partial response. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string}
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --display-name: string # Display name for the schema.
  --etag: string # The ETag of the resource.
  --fields-body: list # A list of fields in the schema. — item shape: {displayName?: string, etag?: string, fieldId?: string, fieldName?: string, fieldType?: string, indexed?: bool, kind?: string, multiValued?: bool, numericIndexingSpec?: record, readAccessType?: string} (body field)
  --kind: string # Kind of resource this is. (default: admin#directory#schema)
  --schema-id: string # The unique identifier of the schema (Read-only)
  --schema-name: string # The schema's name. Each `schema_name` must be unique within a customer. Reusing a name results in a `409: Entity already exists` error.
]: any -> record<displayName: string, etag: string, fields: table<displayName: string, etag: string, fieldId: string, fieldName: string, fieldType: string, indexed: bool, kind: string, multiValued: bool, numericIndexingSpec: record, readAccessType: string>, kind: string, schemaId: string, schemaName: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($schema_key | is-empty) { error make --unspanned { msg: "path parameter 'schemaKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), schema_key: (encode-path-segment $schema_key)} | format pattern "/admin/directory/v1/customer/{customer_id}/schemas/{schema_key}") $qp)
  let req_body = {"displayName": $display_name, "etag": $etag, "fields": $fields_body, "kind": $kind, "schemaId": $schema_id, "schemaName": $schema_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists the domain aliases of the customer.
#
# GET /admin/directory/v1/customer/{customer}/domainaliases
# operationId: directory.domainAliases.list
export def "admin-directory-customer-domainaliases list" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --parent-domain-name: string # Name of the parent domain for which domain aliases are to be fetched.
]: nothing -> record<domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, etag: string, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "parentDomainName" $parent_domain_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/domainaliases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "parentDomainName": $parent_domain_name} | compact), body: null}
}

# Inserts a domain alias of the customer.
#
# POST /admin/directory/v1/customer/{customer}/domainaliases
# operationId: directory.domainAliases.insert
export def "admin-directory-customer-domainaliases create" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --creation-time: string # The creation time of the domain alias. (Read-only). (format: int64)
  --domain-alias-name: string # The domain alias name.
  --etag: string # ETag of the resource.
  --kind: string # Kind of resource this is. (default: admin#directory#domainAlias)
  --parent-domain-name: string # The parent domain name that the domain alias is associated with. This can either be a primary or secondary domain name within a customer.
  --verified: oneof<nothing, bool> # Indicates the verification state of a domain alias. (Read-only)
]: any -> record<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/domainaliases") $qp)
  let req_body = {"creationTime": $creation_time, "domainAliasName": $domain_alias_name, "etag": $etag, "kind": $kind, "parentDomainName": $parent_domain_name, "verified": $verified} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a domain Alias of the customer.
#
# DELETE /admin/directory/v1/customer/{customer}/domainaliases/{domainAliasName}
# operationId: directory.domainAliases.delete
export def "admin-directory-customer-domainaliases delete" [
  customer: string
  domain_alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($domain_alias_name | is-empty) { error make --unspanned { msg: "path parameter 'domainAliasName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), domain_alias_name: (encode-path-segment $domain_alias_name)} | format pattern "/admin/directory/v1/customer/{customer}/domainaliases/{domain_alias_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a domain alias of the customer.
#
# GET /admin/directory/v1/customer/{customer}/domainaliases/{domainAliasName}
# operationId: directory.domainAliases.get
export def "admin-directory-customer-domainaliases get" [
  customer: string
  domain_alias_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($domain_alias_name | is-empty) { error make --unspanned { msg: "path parameter 'domainAliasName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), domain_alias_name: (encode-path-segment $domain_alias_name)} | format pattern "/admin/directory/v1/customer/{customer}/domainaliases/{domain_alias_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists the domains of the customer.
#
# GET /admin/directory/v1/customer/{customer}/domains
# operationId: directory.domains.list
export def "admin-directory-customer-domains list" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<domains: table<creationTime: string, domainAliases: list, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool>, etag: string, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/domains") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Inserts a domain of the customer.
#
# POST /admin/directory/v1/customer/{customer}/domains
# operationId: directory.domains.insert
# --domainAliases item shape: {creationTime?: string, domainAliasName?: string, etag?: string, kind?: string, parentDomainName?: string, verified?: bool}
export def "admin-directory-customer-domains create" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --creation-time: string # Creation time of the domain. Expressed in [Unix time](https://en.wikipedia.org/wiki/Epoch_time) format. (Read-only). (format: int64)
  --domain-aliases: list # A list of domain alias objects. (Read-only) — item shape: {creationTime?: string, domainAliasName?: string, etag?: string, kind?: string, parentDomainName?: string, verified?: bool}
  --domain-name: string # The domain name of the customer.
  --etag: string # ETag of the resource.
  --is-primary: oneof<nothing, bool> # Indicates if the domain is a primary domain (Read-only).
  --kind: string # Kind of resource this is. (default: admin#directory#domain)
  --verified: oneof<nothing, bool> # Indicates the verification state of a domain. (Read-only).
]: any -> record<creationTime: string, domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/domains") $qp)
  let req_body = {"creationTime": $creation_time, "domainAliases": $domain_aliases, "domainName": $domain_name, "etag": $etag, "isPrimary": $is_primary, "kind": $kind, "verified": $verified} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a domain of the customer.
#
# DELETE /admin/directory/v1/customer/{customer}/domains/{domainName}
# operationId: directory.domains.delete
export def "admin-directory-customer-domains delete" [
  customer: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), domain_name: (encode-path-segment $domain_name)} | format pattern "/admin/directory/v1/customer/{customer}/domains/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a domain of the customer.
#
# GET /admin/directory/v1/customer/{customer}/domains/{domainName}
# operationId: directory.domains.get
export def "admin-directory-customer-domains get" [
  customer: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<creationTime: string, domainAliases: table<creationTime: string, domainAliasName: string, etag: string, kind: string, parentDomainName: string, verified: bool>, domainName: string, etag: string, isPrimary: bool, kind: string, verified: bool> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), domain_name: (encode-path-segment $domain_name)} | format pattern "/admin/directory/v1/customer/{customer}/domains/{domain_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a list of buildings for an account.
#
# GET /admin/directory/v1/customer/{customer}/resources/buildings
# operationId: directory.resources.buildings.list
export def "admin-directory-customer-resources-buildings list" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --max-results: int # Maximum number of results to return.
  --page-token: string # Token to specify the next page in the list.
]: nothing -> record<buildings: table<address: record, buildingId: string, buildingName: string, coordinates: record, description: string, etags: string, floorNames: list, kind: string>, etag: string, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/resources/buildings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Inserts a building.
#
# POST /admin/directory/v1/customer/{customer}/resources/buildings
# operationId: directory.resources.buildings.insert
# --address shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
# --coordinates shape: {latitude?: float, longitude?: float}
export def "admin-directory-customer-resources-buildings create" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --coordinates-source: string@coordinates-source-completer # Source from which Building.coordinates are derived.
  --address: record # Public API: Resources.buildings — shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
  --building-id: string # Unique identifier for the building. The maximum length is 100 characters.
  --building-name: string # The building name as seen by users in Calendar. Must be unique for the customer. For example, "NYC-CHEL". The maximum length is 100 characters.
  --coordinates: record # Public API: Resources.buildings — shape: {latitude?: float, longitude?: float}
  --description: string # A brief description of the building. For example, "Chelsea Market".
  --etags: string # ETag of the resource.
  --floor-names: list<string> # The display names for all floors in this building. The floors are expected to be sorted in ascending order, from lowest floor to highest floor. For example, ["B2", "B1", "L", "1", "2", "2M", "3", "PH"] Must contain at least one entry.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#buildings#Building)
]: any -> record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "coordinatesSource" $coordinates_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/resources/buildings") $qp)
  let req_body = {"address": $address, "buildingId": $building_id, "buildingName": $building_name, "coordinates": $coordinates, "description": $description, "etags": $etags, "floorNames": $floor_names, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "coordinatesSource": $coordinates_source} | compact), body: $req_body}
}

# Deletes a building.
#
# DELETE /admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}
# operationId: directory.resources.buildings.delete
export def "admin-directory-customer-resources-buildings delete" [
  customer: string
  building_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($building_id | is-empty) { error make --unspanned { msg: "path parameter 'buildingId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), building_id: (encode-path-segment $building_id)} | format pattern "/admin/directory/v1/customer/{customer}/resources/buildings/{building_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a building.
#
# GET /admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}
# operationId: directory.resources.buildings.get
export def "admin-directory-customer-resources-buildings get" [
  customer: string
  building_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($building_id | is-empty) { error make --unspanned { msg: "path parameter 'buildingId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), building_id: (encode-path-segment $building_id)} | format pattern "/admin/directory/v1/customer/{customer}/resources/buildings/{building_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Patches a building.
#
# PATCH /admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}
# operationId: directory.resources.buildings.patch
# --address shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
# --coordinates shape: {latitude?: float, longitude?: float}
export def "admin-directory-customer-resources-buildings update-by-customer-building-id" [
  customer: string
  building_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --coordinates-source: string@coordinates-source-completer # Source from which Building.coordinates are derived.
  --address: record # Public API: Resources.buildings — shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
  --body-building-id: string # Unique identifier for the building. The maximum length is 100 characters.
  --building-name: string # The building name as seen by users in Calendar. Must be unique for the customer. For example, "NYC-CHEL". The maximum length is 100 characters.
  --coordinates: record # Public API: Resources.buildings — shape: {latitude?: float, longitude?: float}
  --description: string # A brief description of the building. For example, "Chelsea Market".
  --etags: string # ETag of the resource.
  --floor-names: list<string> # The display names for all floors in this building. The floors are expected to be sorted in ascending order, from lowest floor to highest floor. For example, ["B2", "B1", "L", "1", "2", "2M", "3", "PH"] Must contain at least one entry.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#buildings#Building)
]: any -> record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($building_id | is-empty) { error make --unspanned { msg: "path parameter 'buildingId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "coordinatesSource" $coordinates_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), building_id: (encode-path-segment $building_id)} | format pattern "/admin/directory/v1/customer/{customer}/resources/buildings/{building_id}") $qp)
  let req_body = {"address": $address, "buildingId": $body_building_id, "buildingName": $building_name, "coordinates": $coordinates, "description": $description, "etags": $etags, "floorNames": $floor_names, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "coordinatesSource": $coordinates_source} | compact), body: $req_body}
}

# Updates a building.
#
# PUT /admin/directory/v1/customer/{customer}/resources/buildings/{buildingId}
# operationId: directory.resources.buildings.update
# --address shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
# --coordinates shape: {latitude?: float, longitude?: float}
export def "admin-directory-customer-resources-buildings update-by-customer-building-id-1" [
  customer: string
  building_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --coordinates-source: string@coordinates-source-completer # Source from which Building.coordinates are derived.
  --address: record # Public API: Resources.buildings — shape: {addressLines?: list<string>, administrativeArea?: string, languageCode?: string, locality?: string, postalCode?: string, regionCode?: string, sublocality?: string}
  --body-building-id: string # Unique identifier for the building. The maximum length is 100 characters.
  --building-name: string # The building name as seen by users in Calendar. Must be unique for the customer. For example, "NYC-CHEL". The maximum length is 100 characters.
  --coordinates: record # Public API: Resources.buildings — shape: {latitude?: float, longitude?: float}
  --description: string # A brief description of the building. For example, "Chelsea Market".
  --etags: string # ETag of the resource.
  --floor-names: list<string> # The display names for all floors in this building. The floors are expected to be sorted in ascending order, from lowest floor to highest floor. For example, ["B2", "B1", "L", "1", "2", "2M", "3", "PH"] Must contain at least one entry.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#buildings#Building)
]: any -> record<address: record<addressLines: list<string>, administrativeArea: string, languageCode: string, locality: string, postalCode: string, regionCode: string, sublocality: string>, buildingId: string, buildingName: string, coordinates: record<latitude: float, longitude: float>, description: string, etags: string, floorNames: list<string>, kind: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($building_id | is-empty) { error make --unspanned { msg: "path parameter 'buildingId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "coordinatesSource" $coordinates_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), building_id: (encode-path-segment $building_id)} | format pattern "/admin/directory/v1/customer/{customer}/resources/buildings/{building_id}") $qp)
  let req_body = {"address": $address, "buildingId": $body_building_id, "buildingName": $building_name, "coordinates": $coordinates, "description": $description, "etags": $etags, "floorNames": $floor_names, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "coordinatesSource": $coordinates_source} | compact), body: $req_body}
}

# Retrieves a list of calendar resources for an account.
#
# GET /admin/directory/v1/customer/{customer}/resources/calendars
# operationId: directory.resources.calendars.list
export def "admin-directory-customer-resources-calendars list" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --max-results: int # Maximum number of results to return.
  --order-by: string # Field(s) to sort results by in either ascending or descending order. Supported fields include `resourceId`, `resourceName`, `capacity`, `buildingId`, and `floorName`. If no order is specified, defaults to ascending. Should be of the form "field [asc|desc], field [asc|desc], ...". For example `buildingId, capacity desc` would return results sorted first by `buildingId` in ascending order then by `capacity` in descending order.
  --page-token: string # Token to specify the next page in the list.
  --query: string # String query used to filter results. Should be of the form "field operator value" where field can be any of supported fields and operators can be any of supported operations. Operators include '=' for exact match, '!=' for mismatch and ':' for prefix match or HAS match where applicable. For prefix match, the value should always be followed by a *. Logical operators NOT and AND are supported (in this order of precedence). Supported fields include `generatedResourceName`, `name`, `buildingId`, `floor_name`, `capacity`, `featureInstances.feature.name`, `resourceEmail`, `resourceCategory`. For example `buildingId=US-NYC-9TH AND featureInstances.feature.name:Phone`.
]: nothing -> record<etag: string, items: table<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string>, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/resources/calendars") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "orderBy": $order_by, "pageToken": $page_token, "query": $query} | compact), body: null}
}

# Inserts a calendar resource.
#
# POST /admin/directory/v1/customer/{customer}/resources/calendars
# operationId: directory.resources.calendars.insert
export def "admin-directory-customer-resources-calendars create" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --building-id: string # Unique ID for the building a resource is located in.
  --capacity: int # Capacity of a resource, number of seats in a room. (format: int32)
  --etags: string # ETag of the resource.
  --feature-instances: any # Instances of features for the calendar resource.
  --floor-name: string # Name of the floor a resource is located on.
  --floor-section: string # Name of the section within a floor a resource is located in.
  --generated-resource-name: string # The read-only auto-generated name of the calendar resource which includes metadata about the resource such as building name, floor, capacity, etc. For example, "NYC-2-Training Room 1A (16)".
  --kind: string # The type of the resource. For calendar resources, the value is `admin#directory#resources#calendars#CalendarResource`. (default: admin#directory#resources#calendars#CalendarResource)
  --resource-category: string # The category of the calendar resource. Either CONFERENCE_ROOM or OTHER. Legacy data is set to CATEGORY_UNKNOWN.
  --resource-description: string # Description of the resource, visible only to admins.
  --resource-email: string # The read-only email for the calendar resource. Generated as part of creating a new calendar resource.
  --resource-id: string # The unique ID for the calendar resource.
  --resource-name: string # The name of the calendar resource. For example, "Training Room 1A".
  --resource-type: string # The type of the calendar resource, intended for non-room resources.
  --user-visible-description: string # Description of the resource, visible to users and admins.
]: any -> record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/resources/calendars") $qp)
  let req_body = {"buildingId": $building_id, "capacity": $capacity, "etags": $etags, "featureInstances": $feature_instances, "floorName": $floor_name, "floorSection": $floor_section, "generatedResourceName": $generated_resource_name, "kind": $kind, "resourceCategory": $resource_category, "resourceDescription": $resource_description, "resourceEmail": $resource_email, "resourceId": $resource_id, "resourceName": $resource_name, "resourceType": $resource_type, "userVisibleDescription": $user_visible_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a calendar resource.
#
# DELETE /admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}
# operationId: directory.resources.calendars.delete
export def "admin-directory-customer-resources-calendars delete" [
  customer: string
  calendar_resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($calendar_resource_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarResourceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), calendar_resource_id: (encode-path-segment $calendar_resource_id)} | format pattern "/admin/directory/v1/customer/{customer}/resources/calendars/{calendar_resource_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a calendar resource.
#
# GET /admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}
# operationId: directory.resources.calendars.get
export def "admin-directory-customer-resources-calendars get" [
  customer: string
  calendar_resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($calendar_resource_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarResourceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), calendar_resource_id: (encode-path-segment $calendar_resource_id)} | format pattern "/admin/directory/v1/customer/{customer}/resources/calendars/{calendar_resource_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Patches a calendar resource.
#
# PATCH /admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}
# operationId: directory.resources.calendars.patch
export def "admin-directory-customer-resources-calendars update-by-customer-calendar-resource-id" [
  customer: string
  calendar_resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --building-id: string # Unique ID for the building a resource is located in.
  --capacity: int # Capacity of a resource, number of seats in a room. (format: int32)
  --etags: string # ETag of the resource.
  --feature-instances: any # Instances of features for the calendar resource.
  --floor-name: string # Name of the floor a resource is located on.
  --floor-section: string # Name of the section within a floor a resource is located in.
  --generated-resource-name: string # The read-only auto-generated name of the calendar resource which includes metadata about the resource such as building name, floor, capacity, etc. For example, "NYC-2-Training Room 1A (16)".
  --kind: string # The type of the resource. For calendar resources, the value is `admin#directory#resources#calendars#CalendarResource`. (default: admin#directory#resources#calendars#CalendarResource)
  --resource-category: string # The category of the calendar resource. Either CONFERENCE_ROOM or OTHER. Legacy data is set to CATEGORY_UNKNOWN.
  --resource-description: string # Description of the resource, visible only to admins.
  --resource-email: string # The read-only email for the calendar resource. Generated as part of creating a new calendar resource.
  --resource-id: string # The unique ID for the calendar resource.
  --resource-name: string # The name of the calendar resource. For example, "Training Room 1A".
  --resource-type: string # The type of the calendar resource, intended for non-room resources.
  --user-visible-description: string # Description of the resource, visible to users and admins.
]: any -> record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($calendar_resource_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarResourceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), calendar_resource_id: (encode-path-segment $calendar_resource_id)} | format pattern "/admin/directory/v1/customer/{customer}/resources/calendars/{calendar_resource_id}") $qp)
  let req_body = {"buildingId": $building_id, "capacity": $capacity, "etags": $etags, "featureInstances": $feature_instances, "floorName": $floor_name, "floorSection": $floor_section, "generatedResourceName": $generated_resource_name, "kind": $kind, "resourceCategory": $resource_category, "resourceDescription": $resource_description, "resourceEmail": $resource_email, "resourceId": $resource_id, "resourceName": $resource_name, "resourceType": $resource_type, "userVisibleDescription": $user_visible_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates a calendar resource. This method supports patch semantics, meaning you only need to include the fields you wish to update. Fields that are not present in the request will be preserved.
#
# PUT /admin/directory/v1/customer/{customer}/resources/calendars/{calendarResourceId}
# operationId: directory.resources.calendars.update
export def "admin-directory-customer-resources-calendars update-by-customer-calendar-resource-id-1" [
  customer: string
  calendar_resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --building-id: string # Unique ID for the building a resource is located in.
  --capacity: int # Capacity of a resource, number of seats in a room. (format: int32)
  --etags: string # ETag of the resource.
  --feature-instances: any # Instances of features for the calendar resource.
  --floor-name: string # Name of the floor a resource is located on.
  --floor-section: string # Name of the section within a floor a resource is located in.
  --generated-resource-name: string # The read-only auto-generated name of the calendar resource which includes metadata about the resource such as building name, floor, capacity, etc. For example, "NYC-2-Training Room 1A (16)".
  --kind: string # The type of the resource. For calendar resources, the value is `admin#directory#resources#calendars#CalendarResource`. (default: admin#directory#resources#calendars#CalendarResource)
  --resource-category: string # The category of the calendar resource. Either CONFERENCE_ROOM or OTHER. Legacy data is set to CATEGORY_UNKNOWN.
  --resource-description: string # Description of the resource, visible only to admins.
  --resource-email: string # The read-only email for the calendar resource. Generated as part of creating a new calendar resource.
  --resource-id: string # The unique ID for the calendar resource.
  --resource-name: string # The name of the calendar resource. For example, "Training Room 1A".
  --resource-type: string # The type of the calendar resource, intended for non-room resources.
  --user-visible-description: string # Description of the resource, visible to users and admins.
]: any -> record<buildingId: string, capacity: int, etags: string, featureInstances: any, floorName: string, floorSection: string, generatedResourceName: string, kind: string, resourceCategory: string, resourceDescription: string, resourceEmail: string, resourceId: string, resourceName: string, resourceType: string, userVisibleDescription: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($calendar_resource_id | is-empty) { error make --unspanned { msg: "path parameter 'calendarResourceId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), calendar_resource_id: (encode-path-segment $calendar_resource_id)} | format pattern "/admin/directory/v1/customer/{customer}/resources/calendars/{calendar_resource_id}") $qp)
  let req_body = {"buildingId": $building_id, "capacity": $capacity, "etags": $etags, "featureInstances": $feature_instances, "floorName": $floor_name, "floorSection": $floor_section, "generatedResourceName": $generated_resource_name, "kind": $kind, "resourceCategory": $resource_category, "resourceDescription": $resource_description, "resourceEmail": $resource_email, "resourceId": $resource_id, "resourceName": $resource_name, "resourceType": $resource_type, "userVisibleDescription": $user_visible_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves a list of features for an account.
#
# GET /admin/directory/v1/customer/{customer}/resources/features
# operationId: directory.resources.features.list
export def "admin-directory-customer-resources-features list" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --max-results: int # Maximum number of results to return.
  --page-token: string # Token to specify the next page in the list.
]: nothing -> record<etag: string, features: table<etags: string, kind: string, name: string>, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/resources/features") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Inserts a feature.
#
# POST /admin/directory/v1/customer/{customer}/resources/features
# operationId: directory.resources.features.insert
export def "admin-directory-customer-resources-features create" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --etags: string # ETag of the resource.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#features#Feature)
  --name: string # The name of the feature.
]: any -> record<etags: string, kind: string, name: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/resources/features") $qp)
  let req_body = {"etags": $etags, "kind": $kind, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a feature.
#
# DELETE /admin/directory/v1/customer/{customer}/resources/features/{featureKey}
# operationId: directory.resources.features.delete
export def "admin-directory-customer-resources-features delete" [
  customer: string
  feature_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($feature_key | is-empty) { error make --unspanned { msg: "path parameter 'featureKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), feature_key: (encode-path-segment $feature_key)} | format pattern "/admin/directory/v1/customer/{customer}/resources/features/{feature_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a feature.
#
# GET /admin/directory/v1/customer/{customer}/resources/features/{featureKey}
# operationId: directory.resources.features.get
export def "admin-directory-customer-resources-features get" [
  customer: string
  feature_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<etags: string, kind: string, name: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($feature_key | is-empty) { error make --unspanned { msg: "path parameter 'featureKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), feature_key: (encode-path-segment $feature_key)} | format pattern "/admin/directory/v1/customer/{customer}/resources/features/{feature_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Patches a feature.
#
# PATCH /admin/directory/v1/customer/{customer}/resources/features/{featureKey}
# operationId: directory.resources.features.patch
export def "admin-directory-customer-resources-features update-by-customer-feature-key" [
  customer: string
  feature_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --etags: string # ETag of the resource.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#features#Feature)
  --name: string # The name of the feature.
]: any -> record<etags: string, kind: string, name: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($feature_key | is-empty) { error make --unspanned { msg: "path parameter 'featureKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), feature_key: (encode-path-segment $feature_key)} | format pattern "/admin/directory/v1/customer/{customer}/resources/features/{feature_key}") $qp)
  let req_body = {"etags": $etags, "kind": $kind, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates a feature.
#
# PUT /admin/directory/v1/customer/{customer}/resources/features/{featureKey}
# operationId: directory.resources.features.update
export def "admin-directory-customer-resources-features update-by-customer-feature-key-1" [
  customer: string
  feature_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --etags: string # ETag of the resource.
  --kind: string # Kind of resource this is. (default: admin#directory#resources#features#Feature)
  --name: string # The name of the feature.
]: any -> record<etags: string, kind: string, name: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($feature_key | is-empty) { error make --unspanned { msg: "path parameter 'featureKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), feature_key: (encode-path-segment $feature_key)} | format pattern "/admin/directory/v1/customer/{customer}/resources/features/{feature_key}") $qp)
  let req_body = {"etags": $etags, "kind": $kind, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Renames a feature.
#
# POST /admin/directory/v1/customer/{customer}/resources/features/{oldName}/rename
# operationId: directory.resources.features.rename
export def "admin-directory-customer-resources-features-rename rename" [
  customer: string
  old_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --new-name: string # New name of the feature.
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($old_name | is-empty) { error make --unspanned { msg: "path parameter 'oldName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), old_name: (encode-path-segment $old_name)} | format pattern "/admin/directory/v1/customer/{customer}/resources/features/{old_name}/rename") $qp)
  let req_body = {"newName": $new_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves a paginated list of all roleAssignments.
#
# GET /admin/directory/v1/customer/{customer}/roleassignments
# operationId: directory.roleAssignments.list
export def "admin-directory-customer-roleassignments list" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --include-indirect-role-assignments: oneof<nothing, bool> # When set to `true`, fetches indirect role assignments (i.e. role assignment via a group) as well as direct ones. Defaults to `false`. You must specify `user_key` or the indirect role assignments will not be included.
  --max-results: int # Maximum number of results to return.
  --page-token: string # Token to specify the next page in the list.
  --role-id: string # Immutable ID of a role. If included in the request, returns only role assignments containing this role ID.
  --user-key: string # The primary email address, alias email address, or unique user or group ID. If included in the request, returns role assignments only for this user or group.
]: nothing -> record<etag: string, items: table<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string>, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "includeIndirectRoleAssignments" $include_indirect_role_assignments "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "roleId" $role_id "scalar") (serialize-qp "userKey" $user_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/roleassignments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "includeIndirectRoleAssignments": $include_indirect_role_assignments, "maxResults": $max_results, "pageToken": $page_token, "roleId": $role_id, "userKey": $user_key} | compact), body: null}
}

# Creates a role assignment.
#
# POST /admin/directory/v1/customer/{customer}/roleassignments
# operationId: directory.roleAssignments.insert
export def "admin-directory-customer-roleassignments create" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --assigned-to: string # The unique ID of the entity this role is assigned to—either the `user_id` of a user, the `group_id` of a group, or the `uniqueId` of a service account as defined in [Identity and Access Management (IAM)](https://cloud.google.com/iam/docs/reference/rest/v1/projects.serviceAccounts).
  --etag: string # ETag of the resource.
  --kind: string # The type of the API resource. This is always `admin#directory#roleAssignment`. (default: admin#directory#roleAssignment)
  --org-unit-id: string # If the role is restricted to an organization unit, this contains the ID for the organization unit the exercise of this role is restricted to.
  --role-assignment-id: string # ID of this roleAssignment. (format: int64)
  --role-id: string # The ID of the role that is assigned. (format: int64)
  --scope-type: string # The scope in which this role is assigned.
]: any -> record<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/roleassignments") $qp)
  let req_body = {"assignedTo": $assigned_to, "etag": $etag, "kind": $kind, "orgUnitId": $org_unit_id, "roleAssignmentId": $role_assignment_id, "roleId": $role_id, "scopeType": $scope_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a role assignment.
#
# DELETE /admin/directory/v1/customer/{customer}/roleassignments/{roleAssignmentId}
# operationId: directory.roleAssignments.delete
export def "admin-directory-customer-roleassignments delete" [
  customer: string
  role_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($role_assignment_id | is-empty) { error make --unspanned { msg: "path parameter 'roleAssignmentId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), role_assignment_id: (encode-path-segment $role_assignment_id)} | format pattern "/admin/directory/v1/customer/{customer}/roleassignments/{role_assignment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a role assignment.
#
# GET /admin/directory/v1/customer/{customer}/roleassignments/{roleAssignmentId}
# operationId: directory.roleAssignments.get
export def "admin-directory-customer-roleassignments get" [
  customer: string
  role_assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<assignedTo: string, assigneeType: string, etag: string, kind: string, orgUnitId: string, roleAssignmentId: string, roleId: string, scopeType: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($role_assignment_id | is-empty) { error make --unspanned { msg: "path parameter 'roleAssignmentId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), role_assignment_id: (encode-path-segment $role_assignment_id)} | format pattern "/admin/directory/v1/customer/{customer}/roleassignments/{role_assignment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a paginated list of all the roles in a domain.
#
# GET /admin/directory/v1/customer/{customer}/roles
# operationId: directory.roles.list
export def "admin-directory-customer-roles list" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --max-results: int # Maximum number of results to return.
  --page-token: string # Token to specify the next page in the list.
]: nothing -> record<etag: string, items: table<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: list>, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/roles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "maxResults": $max_results, "pageToken": $page_token} | compact), body: null}
}

# Creates a role.
#
# POST /admin/directory/v1/customer/{customer}/roles
# operationId: directory.roles.insert
# --rolePrivileges item shape: {privilegeName?: string, serviceId?: string}
export def "admin-directory-customer-roles create" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --etag: string # ETag of the resource.
  --is-super-admin-role: oneof<nothing, bool> # Returns `true` if the role is a super admin role.
  --is-system-role: oneof<nothing, bool> # Returns `true` if this is a pre-defined system role.
  --kind: string # The type of the API resource. This is always `admin#directory#role`. (default: admin#directory#role)
  --role-description: string # A short description of the role.
  --role-id: string # ID of the role. (format: int64)
  --role-name: string # Name of the role.
  --role-privileges: list # The set of privileges that are granted to this role. — item shape: {privilegeName?: string, serviceId?: string}
]: any -> record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/roles") $qp)
  let req_body = {"etag": $etag, "isSuperAdminRole": $is_super_admin_role, "isSystemRole": $is_system_role, "kind": $kind, "roleDescription": $role_description, "roleId": $role_id, "roleName": $role_name, "rolePrivileges": $role_privileges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves a paginated list of all privileges for a customer.
#
# GET /admin/directory/v1/customer/{customer}/roles/ALL/privileges
# operationId: directory.privileges.list
export def "admin-directory-customer-roles-all-privileges list" [
  customer: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<etag: string, items: table<childPrivileges: list, etag: string, isOuScopable: bool, kind: string, privilegeName: string, serviceId: string, serviceName: string>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer)} | format pattern "/admin/directory/v1/customer/{customer}/roles/ALL/privileges") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Deletes a role.
#
# DELETE /admin/directory/v1/customer/{customer}/roles/{roleId}
# operationId: directory.roles.delete
export def "admin-directory-customer-roles delete" [
  customer: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), role_id: (encode-path-segment $role_id)} | format pattern "/admin/directory/v1/customer/{customer}/roles/{role_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a role.
#
# GET /admin/directory/v1/customer/{customer}/roles/{roleId}
# operationId: directory.roles.get
export def "admin-directory-customer-roles get" [
  customer: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), role_id: (encode-path-segment $role_id)} | format pattern "/admin/directory/v1/customer/{customer}/roles/{role_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Patches a role.
#
# PATCH /admin/directory/v1/customer/{customer}/roles/{roleId}
# operationId: directory.roles.patch
# --rolePrivileges item shape: {privilegeName?: string, serviceId?: string}
export def "admin-directory-customer-roles update-by-customer-role-id" [
  customer: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --etag: string # ETag of the resource.
  --is-super-admin-role: oneof<nothing, bool> # Returns `true` if the role is a super admin role.
  --is-system-role: oneof<nothing, bool> # Returns `true` if this is a pre-defined system role.
  --kind: string # The type of the API resource. This is always `admin#directory#role`. (default: admin#directory#role)
  --role-description: string # A short description of the role.
  --body-role-id: string # ID of the role. (format: int64)
  --role-name: string # Name of the role.
  --role-privileges: list # The set of privileges that are granted to this role. — item shape: {privilegeName?: string, serviceId?: string}
]: any -> record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), role_id: (encode-path-segment $role_id)} | format pattern "/admin/directory/v1/customer/{customer}/roles/{role_id}") $qp)
  let req_body = {"etag": $etag, "isSuperAdminRole": $is_super_admin_role, "isSystemRole": $is_system_role, "kind": $kind, "roleDescription": $role_description, "roleId": $body_role_id, "roleName": $role_name, "rolePrivileges": $role_privileges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates a role.
#
# PUT /admin/directory/v1/customer/{customer}/roles/{roleId}
# operationId: directory.roles.update
# --rolePrivileges item shape: {privilegeName?: string, serviceId?: string}
export def "admin-directory-customer-roles update-by-customer-role-id-1" [
  customer: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --etag: string # ETag of the resource.
  --is-super-admin-role: oneof<nothing, bool> # Returns `true` if the role is a super admin role.
  --is-system-role: oneof<nothing, bool> # Returns `true` if this is a pre-defined system role.
  --kind: string # The type of the API resource. This is always `admin#directory#role`. (default: admin#directory#role)
  --role-description: string # A short description of the role.
  --body-role-id: string # ID of the role. (format: int64)
  --role-name: string # Name of the role.
  --role-privileges: list # The set of privileges that are granted to this role. — item shape: {privilegeName?: string, serviceId?: string}
]: any -> record<etag: string, isSuperAdminRole: bool, isSystemRole: bool, kind: string, roleDescription: string, roleId: string, roleName: string, rolePrivileges: table<privilegeName: string, serviceId: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer | is-empty) { error make --unspanned { msg: "path parameter 'customer' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer: (encode-path-segment $customer), role_id: (encode-path-segment $role_id)} | format pattern "/admin/directory/v1/customer/{customer}/roles/{role_id}") $qp)
  let req_body = {"etag": $etag, "isSuperAdminRole": $is_super_admin_role, "isSystemRole": $is_system_role, "kind": $kind, "roleDescription": $role_description, "roleId": $body_role_id, "roleName": $role_name, "rolePrivileges": $role_privileges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves a customer.
#
# GET /admin/directory/v1/customers/{customerKey}
# operationId: directory.customers.get
export def "admin-directory-customers get" [
  customer_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_key | is-empty) { error make --unspanned { msg: "path parameter 'customerKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_key: (encode-path-segment $customer_key)} | format pattern "/admin/directory/v1/customers/{customer_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Patches a customer.
#
# PATCH /admin/directory/v1/customers/{customerKey}
# operationId: directory.customers.patch
# --postalAddress shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
export def "admin-directory-customers update-by-customer-key" [
  customer_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --alternate-email: string # The customer's secondary contact email address. This email address cannot be on the same domain as the `customerDomain`
  --customer-creation-time: string # The customer's creation time (Readonly) (format: date-time)
  --customer-domain: string # The customer's primary domain name string. Do not include the `www` prefix when creating a new customer.
  --etag: string # ETag of the resource.
  --id: string # The unique ID for the customer's Google Workspace account. (Readonly)
  --kind: string # Identifies the resource as a customer. Value: `admin#directory#customer` (default: admin#directory#customer)
  --language: string # The customer's ISO 639-2 language code. See the [Language Codes](/admin-sdk/directory/v1/languages) page for the list of supported codes. Valid language codes outside the supported set will be accepted by the API but may lead to unexpected behavior. The default value is `en`.
  --phone-number: string # The customer's contact phone number in [E.164](https://en.wikipedia.org/wiki/E.164) format.
  --postal-address: record # shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
]: any -> record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_key | is-empty) { error make --unspanned { msg: "path parameter 'customerKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_key: (encode-path-segment $customer_key)} | format pattern "/admin/directory/v1/customers/{customer_key}") $qp)
  let req_body = {"alternateEmail": $alternate_email, "customerCreationTime": $customer_creation_time, "customerDomain": $customer_domain, "etag": $etag, "id": $id, "kind": $kind, "language": $language, "phoneNumber": $phone_number, "postalAddress": $postal_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates a customer.
#
# PUT /admin/directory/v1/customers/{customerKey}
# operationId: directory.customers.update
# --postalAddress shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
export def "admin-directory-customers update-by-customer-key-1" [
  customer_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --alternate-email: string # The customer's secondary contact email address. This email address cannot be on the same domain as the `customerDomain`
  --customer-creation-time: string # The customer's creation time (Readonly) (format: date-time)
  --customer-domain: string # The customer's primary domain name string. Do not include the `www` prefix when creating a new customer.
  --etag: string # ETag of the resource.
  --id: string # The unique ID for the customer's Google Workspace account. (Readonly)
  --kind: string # Identifies the resource as a customer. Value: `admin#directory#customer` (default: admin#directory#customer)
  --language: string # The customer's ISO 639-2 language code. See the [Language Codes](/admin-sdk/directory/v1/languages) page for the list of supported codes. Valid language codes outside the supported set will be accepted by the API but may lead to unexpected behavior. The default value is `en`.
  --phone-number: string # The customer's contact phone number in [E.164](https://en.wikipedia.org/wiki/E.164) format.
  --postal-address: record # shape: {addressLine1?: string, addressLine2?: string, addressLine3?: string, contactName?: string, countryCode?: string, locality?: string, organizationName?: string, postalCode?: string, region?: string}
]: any -> record<alternateEmail: string, customerCreationTime: string, customerDomain: string, etag: string, id: string, kind: string, language: string, phoneNumber: string, postalAddress: record<addressLine1: string, addressLine2: string, addressLine3: string, contactName: string, countryCode: string, locality: string, organizationName: string, postalCode: string, region: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($customer_key | is-empty) { error make --unspanned { msg: "path parameter 'customerKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_key: (encode-path-segment $customer_key)} | format pattern "/admin/directory/v1/customers/{customer_key}") $qp)
  let req_body = {"alternateEmail": $alternate_email, "customerCreationTime": $customer_creation_time, "customerDomain": $customer_domain, "etag": $etag, "id": $id, "kind": $kind, "language": $language, "phoneNumber": $phone_number, "postalAddress": $postal_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves all groups of a domain or of a user given a userKey (paginated).
#
# GET /admin/directory/v1/groups
# operationId: directory.groups.list
export def "admin-directory-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --customer: string # The unique ID for the customer's Google Workspace account. In case of a multi-domain account, to fetch all groups for a customer, use this field instead of `domain`. You can also use the `my_customer` alias to represent your account's `customerId`. The `customerId` is also returned as part of the [Users](/admin-sdk/directory/v1/reference/users) resource. You must provide either the `customer` or the `domain` parameter.
  --domain: string # The domain name. Use this field to get groups from only one domain. To return all domains for a customer account, use the `customer` query parameter instead.
  --max-results: int # Maximum number of results to return. Max allowed value is 200.
  --order-by: string@order-by-completer-2 # Column to use for sorting results
  --page-token: string # Token to specify next page in the list
  --query: string # Query string search. Should be of the form "". Complete documentation is at https: //developers.google.com/admin-sdk/directory/v1/guides/search-groups
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order. Only of use when orderBy is also used
  --user-key: string # Email or immutable ID of the user if only those groups are to be listed, the given user is a member of. If it's an ID, it should match with the ID of the user object.
]: nothing -> record<etag: string, groups: table<adminCreated: bool, aliases: list, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list>, kind: string, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "userKey" $user_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/directory/v1/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "customer": $customer, "domain": $domain, "maxResults": $max_results, "orderBy": $order_by, "pageToken": $page_token, "query": $query, "sortOrder": $sort_order, "userKey": $user_key} | compact), body: null}
}

# Creates a group.
#
# POST /admin/directory/v1/groups
# operationId: directory.groups.insert
export def "admin-directory-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --admin-created: oneof<nothing, bool> # Read-only. Value is `true` if this group was created by an administrator rather than a user.
  --aliases: list<string> # Read-only. The list of a group's alias email addresses. To add, update, or remove a group's aliases, use the `groups.aliases` methods. If edited in a group's POST or PUT request, the edit is ignored.
  --description: string # An extended description to help users determine the purpose of a group. For example, you can include information about who should join the group, the types of messages to send to the group, links to FAQs about the group, or related groups. Maximum length is `4,096` characters.
  --direct-members-count: string # The number of users that are direct members of the group. If a group is a member (child) of this group (the parent), members of the child group are not counted in the `directMembersCount` property of the parent group. (format: int64)
  --email: string # The group's email address. If your account has multiple domains, select the appropriate domain for the email address. The `email` must be unique. This property is required when creating a group. Group email addresses are subject to the same character usage rules as usernames, see the [help center](https://support.google.com/a/answer/9193374) for details.
  --etag: string # ETag of the resource.
  --id: string # Read-only. The unique ID of a group. A group `id` can be used as a group request URI's `groupKey`.
  --kind: string # The type of the API resource. For Groups resources, the value is `admin#directory#group`. (default: admin#directory#group)
  --name: string # The group's display name.
  --non-editable-aliases: list<string> # Read-only. The list of the group's non-editable alias email addresses that are outside of the account's primary domain or subdomains. These are functioning email addresses used by the group. This is a read-only property returned in the API's response for a group. If edited in a group's POST or PUT request, the edit is ignored.
]: any -> record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/directory/v1/groups" $qp)
  let req_body = {"adminCreated": $admin_created, "aliases": $aliases, "description": $description, "directMembersCount": $direct_members_count, "email": $email, "etag": $etag, "id": $id, "kind": $kind, "name": $name, "nonEditableAliases": $non_editable_aliases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes a group.
#
# DELETE /admin/directory/v1/groups/{groupKey}
# operationId: directory.groups.delete
export def "admin-directory-groups delete" [
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/admin/directory/v1/groups/{group_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a group's properties.
#
# GET /admin/directory/v1/groups/{groupKey}
# operationId: directory.groups.get
export def "admin-directory-groups get" [
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/admin/directory/v1/groups/{group_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates a group's properties. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch).
#
# PATCH /admin/directory/v1/groups/{groupKey}
# operationId: directory.groups.patch
export def "admin-directory-groups update-by-group-key" [
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --admin-created: oneof<nothing, bool> # Read-only. Value is `true` if this group was created by an administrator rather than a user.
  --aliases: list<string> # Read-only. The list of a group's alias email addresses. To add, update, or remove a group's aliases, use the `groups.aliases` methods. If edited in a group's POST or PUT request, the edit is ignored.
  --description: string # An extended description to help users determine the purpose of a group. For example, you can include information about who should join the group, the types of messages to send to the group, links to FAQs about the group, or related groups. Maximum length is `4,096` characters.
  --direct-members-count: string # The number of users that are direct members of the group. If a group is a member (child) of this group (the parent), members of the child group are not counted in the `directMembersCount` property of the parent group. (format: int64)
  --email: string # The group's email address. If your account has multiple domains, select the appropriate domain for the email address. The `email` must be unique. This property is required when creating a group. Group email addresses are subject to the same character usage rules as usernames, see the [help center](https://support.google.com/a/answer/9193374) for details.
  --etag: string # ETag of the resource.
  --id: string # Read-only. The unique ID of a group. A group `id` can be used as a group request URI's `groupKey`.
  --kind: string # The type of the API resource. For Groups resources, the value is `admin#directory#group`. (default: admin#directory#group)
  --name: string # The group's display name.
  --non-editable-aliases: list<string> # Read-only. The list of the group's non-editable alias email addresses that are outside of the account's primary domain or subdomains. These are functioning email addresses used by the group. This is a read-only property returned in the API's response for a group. If edited in a group's POST or PUT request, the edit is ignored.
]: any -> record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/admin/directory/v1/groups/{group_key}") $qp)
  let req_body = {"adminCreated": $admin_created, "aliases": $aliases, "description": $description, "directMembersCount": $direct_members_count, "email": $email, "etag": $etag, "id": $id, "kind": $kind, "name": $name, "nonEditableAliases": $non_editable_aliases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates a group's properties.
#
# PUT /admin/directory/v1/groups/{groupKey}
# operationId: directory.groups.update
export def "admin-directory-groups update-by-group-key-1" [
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --admin-created: oneof<nothing, bool> # Read-only. Value is `true` if this group was created by an administrator rather than a user.
  --aliases: list<string> # Read-only. The list of a group's alias email addresses. To add, update, or remove a group's aliases, use the `groups.aliases` methods. If edited in a group's POST or PUT request, the edit is ignored.
  --description: string # An extended description to help users determine the purpose of a group. For example, you can include information about who should join the group, the types of messages to send to the group, links to FAQs about the group, or related groups. Maximum length is `4,096` characters.
  --direct-members-count: string # The number of users that are direct members of the group. If a group is a member (child) of this group (the parent), members of the child group are not counted in the `directMembersCount` property of the parent group. (format: int64)
  --email: string # The group's email address. If your account has multiple domains, select the appropriate domain for the email address. The `email` must be unique. This property is required when creating a group. Group email addresses are subject to the same character usage rules as usernames, see the [help center](https://support.google.com/a/answer/9193374) for details.
  --etag: string # ETag of the resource.
  --id: string # Read-only. The unique ID of a group. A group `id` can be used as a group request URI's `groupKey`.
  --kind: string # The type of the API resource. For Groups resources, the value is `admin#directory#group`. (default: admin#directory#group)
  --name: string # The group's display name.
  --non-editable-aliases: list<string> # Read-only. The list of the group's non-editable alias email addresses that are outside of the account's primary domain or subdomains. These are functioning email addresses used by the group. This is a read-only property returned in the API's response for a group. If edited in a group's POST or PUT request, the edit is ignored.
]: any -> record<adminCreated: bool, aliases: list<string>, description: string, directMembersCount: string, email: string, etag: string, id: string, kind: string, name: string, nonEditableAliases: list<string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/admin/directory/v1/groups/{group_key}") $qp)
  let req_body = {"adminCreated": $admin_created, "aliases": $aliases, "description": $description, "directMembersCount": $direct_members_count, "email": $email, "etag": $etag, "id": $id, "kind": $kind, "name": $name, "nonEditableAliases": $non_editable_aliases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists all aliases for a group.
#
# GET /admin/directory/v1/groups/{groupKey}/aliases
# operationId: directory.groups.aliases.list
export def "admin-directory-groups-aliases list" [
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<aliases: list<any>, etag: string, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/admin/directory/v1/groups/{group_key}/aliases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Adds an alias for the group.
#
# POST /admin/directory/v1/groups/{groupKey}/aliases
# operationId: directory.groups.aliases.insert
export def "admin-directory-groups-aliases create" [
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --alias: string
  --etag: string
  --id: string
  --kind: string # default: admin#directory#alias
  --primary-email: string
]: any -> record<alias: string, etag: string, id: string, kind: string, primaryEmail: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/admin/directory/v1/groups/{group_key}/aliases") $qp)
  let req_body = {"alias": $alias, "etag": $etag, "id": $id, "kind": $kind, "primaryEmail": $primary_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Removes an alias.
#
# DELETE /admin/directory/v1/groups/{groupKey}/aliases/{alias}
# operationId: directory.groups.aliases.delete
export def "admin-directory-groups-aliases delete" [
  group_key: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key), alias: (encode-path-segment $alias)} | format pattern "/admin/directory/v1/groups/{group_key}/aliases/{alias}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Checks whether the given user is a member of the group. Membership can be direct or nested, but if nested, the `memberKey` and `groupKey` must be entities in the same domain or an `Invalid input` error is returned. To check for nested memberships that include entities outside of the group's domain, use the [`checkTransitiveMembership()`](https://cloud.google.com/identity/docs/reference/rest/v1/groups.memberships/checkTransitiveMembership) method in the Cloud Identity Groups API.
#
# GET /admin/directory/v1/groups/{groupKey}/hasMember/{memberKey}
# operationId: directory.members.hasMember
export def "admin-directory-groups-has-member get" [
  group_key: string
  member_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<isMember: bool> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  if ($member_key | is-empty) { error make --unspanned { msg: "path parameter 'memberKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key), member_key: (encode-path-segment $member_key)} | format pattern "/admin/directory/v1/groups/{group_key}/hasMember/{member_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a paginated list of all members in a group. This method times out after 60 minutes. For more information, see [Troubleshoot error codes](https://developers.google.com/admin-sdk/directory/v1/guides/troubleshoot-error-codes).
#
# GET /admin/directory/v1/groups/{groupKey}/members
# operationId: directory.members.list
export def "admin-directory-groups-members list" [
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --include-derived-membership: oneof<nothing, bool> # Whether to list indirect memberships. Default: false.
  --max-results: int # Maximum number of results to return. Max allowed value is 200.
  --page-token: string # Token to specify next page in the list.
  --roles: string # The `roles` query parameter allows you to retrieve group members by role. Allowed values are `OWNER`, `MANAGER`, and `MEMBER`.
]: nothing -> record<etag: string, kind: string, members: table<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "includeDerivedMembership" $include_derived_membership "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "roles" $roles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/admin/directory/v1/groups/{group_key}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "includeDerivedMembership": $include_derived_membership, "maxResults": $max_results, "pageToken": $page_token, "roles": $roles} | compact), body: null}
}

# Adds a user to the specified group.
#
# POST /admin/directory/v1/groups/{groupKey}/members
# operationId: directory.members.insert
export def "admin-directory-groups-members create" [
  group_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --delivery-settings: string # Defines mail delivery preferences of member. This is only supported by create/update/get.
  --email: string # The member's email address. A member can be a user or another group. This property is required when adding a member to a group. The `email` must be unique and cannot be an alias of another group. If the email address is changed, the API automatically reflects the email address changes.
  --etag: string # ETag of the resource.
  --id: string # The unique ID of the group member. A member `id` can be used as a member request URI's `memberKey`.
  --kind: string # The type of the API resource. For Members resources, the value is `admin#directory#member`. (default: admin#directory#member)
  --role: string # The member's role in a group. The API returns an error for cycles in group memberships. For example, if `group1` is a member of `group2`, `group2` cannot be a member of `group1`. For more information about a member's role, see the [administration help center](https://support.google.com/a/answer/167094).
  --status: string # Status of member (Immutable)
  --type: string # The type of group member.
]: any -> record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key)} | format pattern "/admin/directory/v1/groups/{group_key}/members") $qp)
  let req_body = {"delivery_settings": $delivery_settings, "email": $email, "etag": $etag, "id": $id, "kind": $kind, "role": $role, "status": $status, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Removes a member from a group.
#
# DELETE /admin/directory/v1/groups/{groupKey}/members/{memberKey}
# operationId: directory.members.delete
export def "admin-directory-groups-members delete" [
  group_key: string
  member_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  if ($member_key | is-empty) { error make --unspanned { msg: "path parameter 'memberKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key), member_key: (encode-path-segment $member_key)} | format pattern "/admin/directory/v1/groups/{group_key}/members/{member_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a group member's properties.
#
# GET /admin/directory/v1/groups/{groupKey}/members/{memberKey}
# operationId: directory.members.get
export def "admin-directory-groups-members get" [
  group_key: string
  member_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  if ($member_key | is-empty) { error make --unspanned { msg: "path parameter 'memberKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key), member_key: (encode-path-segment $member_key)} | format pattern "/admin/directory/v1/groups/{group_key}/members/{member_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates the membership properties of a user in the specified group. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch).
#
# PATCH /admin/directory/v1/groups/{groupKey}/members/{memberKey}
# operationId: directory.members.patch
export def "admin-directory-groups-members update-by-group-key-member-key" [
  group_key: string
  member_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --delivery-settings: string # Defines mail delivery preferences of member. This is only supported by create/update/get.
  --email: string # The member's email address. A member can be a user or another group. This property is required when adding a member to a group. The `email` must be unique and cannot be an alias of another group. If the email address is changed, the API automatically reflects the email address changes.
  --etag: string # ETag of the resource.
  --id: string # The unique ID of the group member. A member `id` can be used as a member request URI's `memberKey`.
  --kind: string # The type of the API resource. For Members resources, the value is `admin#directory#member`. (default: admin#directory#member)
  --role: string # The member's role in a group. The API returns an error for cycles in group memberships. For example, if `group1` is a member of `group2`, `group2` cannot be a member of `group1`. For more information about a member's role, see the [administration help center](https://support.google.com/a/answer/167094).
  --status: string # Status of member (Immutable)
  --type: string # The type of group member.
]: any -> record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  if ($member_key | is-empty) { error make --unspanned { msg: "path parameter 'memberKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key), member_key: (encode-path-segment $member_key)} | format pattern "/admin/directory/v1/groups/{group_key}/members/{member_key}") $qp)
  let req_body = {"delivery_settings": $delivery_settings, "email": $email, "etag": $etag, "id": $id, "kind": $kind, "role": $role, "status": $status, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates the membership of a user in the specified group.
#
# PUT /admin/directory/v1/groups/{groupKey}/members/{memberKey}
# operationId: directory.members.update
export def "admin-directory-groups-members update-by-group-key-member-key-1" [
  group_key: string
  member_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --delivery-settings: string # Defines mail delivery preferences of member. This is only supported by create/update/get.
  --email: string # The member's email address. A member can be a user or another group. This property is required when adding a member to a group. The `email` must be unique and cannot be an alias of another group. If the email address is changed, the API automatically reflects the email address changes.
  --etag: string # ETag of the resource.
  --id: string # The unique ID of the group member. A member `id` can be used as a member request URI's `memberKey`.
  --kind: string # The type of the API resource. For Members resources, the value is `admin#directory#member`. (default: admin#directory#member)
  --role: string # The member's role in a group. The API returns an error for cycles in group memberships. For example, if `group1` is a member of `group2`, `group2` cannot be a member of `group1`. For more information about a member's role, see the [administration help center](https://support.google.com/a/answer/167094).
  --status: string # Status of member (Immutable)
  --type: string # The type of group member.
]: any -> record<delivery_settings: string, email: string, etag: string, id: string, kind: string, role: string, status: string, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($group_key | is-empty) { error make --unspanned { msg: "path parameter 'groupKey' must be non-empty" } }
  if ($member_key | is-empty) { error make --unspanned { msg: "path parameter 'memberKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_key: (encode-path-segment $group_key), member_key: (encode-path-segment $member_key)} | format pattern "/admin/directory/v1/groups/{group_key}/members/{member_key}") $qp)
  let req_body = {"delivery_settings": $delivery_settings, "email": $email, "etag": $etag, "id": $id, "kind": $kind, "role": $role, "status": $status, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Retrieves a paginated list of either deleted users or all users in a domain.
#
# GET /admin/directory/v1/users
# operationId: directory.users.list
export def "admin-directory-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --custom-field-mask: string # A comma-separated list of schema names. All fields from these schemas are fetched. This should only be set when `projection=custom`.
  --customer: string # The unique ID for the customer's Google Workspace account. In case of a multi-domain account, to fetch all groups for a customer, use this field instead of `domain`. You can also use the `my_customer` alias to represent your account's `customerId`. The `customerId` is also returned as part of the [Users](/admin-sdk/directory/v1/reference/users) resource. You must provide either the `customer` or the `domain` parameter.
  --domain: string # The domain name. Use this field to get groups from only one domain. To return all domains for a customer account, use the `customer` query parameter instead. Either the `customer` or the `domain` parameter must be provided.
  --event: string@event-completer # Event on which subscription is intended (if subscribing)
  --max-results: int # Maximum number of results to return.
  --order-by: string@order-by-completer-3 # Property to use for sorting results.
  --page-token: string # Token to specify next page in the list
  --projection: string@projection-completer-1 # What subset of fields to fetch for this user.
  --query: string # Query string for searching user fields. For more information on constructing user queries, see [Search for Users](/admin-sdk/directory/v1/guides/search-users).
  --show-deleted: string # If set to `true`, retrieves the list of deleted users. (Default: `false`)
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order, ignoring case.
  --view-type: string@view-type-completer # Whether to fetch the administrator-only or domain-wide public view of the user. For more information, see [Retrieve a user as a non-administrator](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
]: nothing -> record<etag: string, kind: string, nextPageToken: string, trigger_event: string, users: table<addresses: any, agreedToTerms: bool, aliases: list, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record, nonEditableAliases: list, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "customFieldMask" $custom_field_mask "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "viewType" $view_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/directory/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "customFieldMask": $custom_field_mask, "customer": $customer, "domain": $domain, "event": $event, "maxResults": $max_results, "orderBy": $order_by, "pageToken": $page_token, "projection": $projection, "query": $query, "showDeleted": $show_deleted, "sortOrder": $sort_order, "viewType": $view_type} | compact), body: null}
}

# Creates a user.
#
# POST /admin/directory/v1/users
# operationId: directory.users.insert
# --name shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
export def "admin-directory-users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --addresses: any # The list of the user's addresses. The maximum allowed data size for this field is 10KB.
  --archived: oneof<nothing, bool> # Indicates if user is archived.
  --change-password-at-next-login: oneof<nothing, bool> # Indicates if the user is forced to change their password at next login. This setting doesn't apply when [the user signs in via a third-party identity provider](https://support.google.com/a/answer/60224).
  --custom-schemas: record # Custom fields of the user. The key is a `schema_name` and its values are `'field_name': 'field_value'`.
  --emails: any # The list of the user's email addresses. The maximum allowed data size for this field is 10KB.
  --external-ids: any # The list of external IDs for the user, such as an employee or network ID. The maximum allowed data size for this field is 2KB.
  --gender: any # The user's gender. The maximum allowed data size for this field is 1KB.
  --hash-function: string # Stores the hash format of the `password` property. The following `hashFunction` values are allowed: * `MD5` - Accepts simple hex-encoded values. * `SHA-1` - Accepts simple hex-encoded values. * `crypt` - Compliant with the [C crypt library](https://en.wikipedia.org/wiki/Crypt_%28C%29). Supports the DES, MD5 (hash prefix `$1$`), SHA-256 (hash prefix `$5$`), and SHA-512 (hash prefix `$6$`) hash algorithms. If rounds are specified as part of the prefix, they must be 10,000 or fewer.
  --id: string # The unique ID for the user. A user `id` can be used as a user request URI's `userKey`.
  --ims: any # The list of the user's Instant Messenger (IM) accounts. A user account can have multiple ims properties. But, only one of these ims properties can be the primary IM contact. The maximum allowed data size for this field is 2KB.
  --include-in-global-address-list: oneof<nothing, bool> # Indicates if the user's profile is visible in the Google Workspace global address list when the contact sharing feature is enabled for the domain. For more information about excluding user profiles, see the [administration help center](https://support.google.com/a/answer/1285988).
  --ip-whitelisted: oneof<nothing, bool> # If `true`, the user's IP address is subject to a deprecated IP address [`allowlist`](https://support.google.com/a/answer/60752) configuration.
  --keywords: any # The list of the user's keywords. The maximum allowed data size for this field is 1KB.
  --languages: any # The user's languages. The maximum allowed data size for this field is 1KB.
  --locations: any # The user's locations. The maximum allowed data size for this field is 10KB.
  --name: record # shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
  --notes: any # Notes for the user.
  --org-unit-path: string # The full path of the parent organization associated with the user. If the parent organization is the top-level, it is represented as a forward slash (`/`).
  --organizations: any # The list of organizations the user belongs to. The maximum allowed data size for this field is 10KB.
  --password: string # User's password
  --phones: any # The list of the user's phone numbers. The maximum allowed data size for this field is 1KB.
  --posix-accounts: any # The list of [POSIX](https://www.opengroup.org/austin/papers/posix_faq.html) account information for the user.
  --primary-email: string # The user's primary email address. This property is required in a request to create a user account. The `primaryEmail` must be unique and cannot be an alias of another user.
  --recovery-email: string # Recovery email of the user.
  --recovery-phone: string # Recovery phone of the user. The phone number must be in the E.164 format, starting with the plus sign (+). Example: *+16506661212*.
  --relations: any # The list of the user's relationships to other users. The maximum allowed data size for this field is 2KB.
  --ssh-public-keys: any # A list of SSH public keys.
  --suspended: oneof<nothing, bool> # Indicates if user is suspended.
  --websites: any # The user's websites. The maximum allowed data size for this field is 2KB.
]: any -> record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/directory/v1/users" $qp)
  let req_body = {"addresses": $addresses, "archived": $archived, "changePasswordAtNextLogin": $change_password_at_next_login, "customSchemas": $custom_schemas, "emails": $emails, "externalIds": $external_ids, "gender": $gender, "hashFunction": $hash_function, "id": $id, "ims": $ims, "includeInGlobalAddressList": $include_in_global_address_list, "ipWhitelisted": $ip_whitelisted, "keywords": $keywords, "languages": $languages, "locations": $locations, "name": $name, "notes": $notes, "orgUnitPath": $org_unit_path, "organizations": $organizations, "password": $password, "phones": $phones, "posixAccounts": $posix_accounts, "primaryEmail": $primary_email, "recoveryEmail": $recovery_email, "recoveryPhone": $recovery_phone, "relations": $relations, "sshPublicKeys": $ssh_public_keys, "suspended": $suspended, "websites": $websites} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Watches for changes in users list.
#
# POST /admin/directory/v1/users/watch
# operationId: directory.users.watch
export def "admin-directory-users-watch watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --custom-field-mask: string # Comma-separated list of schema names. All fields from these schemas are fetched. This should only be set when projection=custom.
  --customer: string # Immutable ID of the Google Workspace account. In case of multi-domain, to fetch all users for a customer, fill this field instead of domain.
  --domain: string # Name of the domain. Fill this field to get users from only this domain. To return all users in a multi-domain fill customer field instead."
  --event: string@event-completer # Events to watch for.
  --max-results: int # Maximum number of results to return.
  --order-by: string@order-by-completer-3 # Column to use for sorting results
  --page-token: string # Token to specify next page in the list
  --projection: string@projection-completer-1 # What subset of fields to fetch for this user.
  --query: string # Query string search. Should be of the form "". Complete documentation is at https: //developers.google.com/admin-sdk/directory/v1/guides/search-users
  --show-deleted: string # If set to true, retrieves the list of deleted users. (Default: false)
  --sort-order: string@sort-order-completer # Whether to return results in ascending or descending order.
  --view-type: string@view-type-completer # Whether to fetch the administrator-only or domain-wide public view of the user. For more information, see [Retrieve a user as a non-administrator](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is `api#channel`. (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional. For example, `params.ttl` specifies the time-to-live in seconds for the notification channel, where the default is 2 hours and the maximum TTL is 2 days.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "customFieldMask" $custom_field_mask "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "showDeleted" $show_deleted "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "viewType" $view_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/directory/v1/users/watch" $qp)
  let req_body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "customFieldMask": $custom_field_mask, "customer": $customer, "domain": $domain, "event": $event, "maxResults": $max_results, "orderBy": $order_by, "pageToken": $page_token, "projection": $projection, "query": $query, "showDeleted": $show_deleted, "sortOrder": $sort_order, "viewType": $view_type} | compact), body: $req_body}
}

# Deletes a user.
#
# DELETE /admin/directory/v1/users/{userKey}
# operationId: directory.users.delete
export def "admin-directory-users delete" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves a user.
#
# GET /admin/directory/v1/users/{userKey}
# operationId: directory.users.get
export def "admin-directory-users get" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --custom-field-mask: string # A comma-separated list of schema names. All fields from these schemas are fetched. This should only be set when `projection=custom`.
  --projection: string@projection-completer-1 # What subset of fields to fetch for this user.
  --view-type: string@view-type-completer # Whether to fetch the administrator-only or domain-wide public view of the user. For more information, see [Retrieve a user as a non-administrator](/admin-sdk/directory/v1/guides/manage-users#retrieve_users_non_admin).
]: nothing -> record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "customFieldMask" $custom_field_mask "scalar") (serialize-qp "projection" $projection "scalar") (serialize-qp "viewType" $view_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "customFieldMask": $custom_field_mask, "projection": $projection, "viewType": $view_type} | compact), body: null}
}

# Updates a user using patch semantics. The update method should be used instead, because it also supports patch semantics and has better performance. If you're mapping an external identity to a Google identity, use the [`update`](https://developers.google.com/admin-sdk/directory/v1/reference/users/update) method instead of the `patch` method. This method is unable to clear fields that contain repeated objects (`addresses`, `phones`, etc). Use the update method instead.
#
# PATCH /admin/directory/v1/users/{userKey}
# operationId: directory.users.patch
# --name shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
export def "admin-directory-users update-by-user-key" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --addresses: any # The list of the user's addresses. The maximum allowed data size for this field is 10KB.
  --archived: oneof<nothing, bool> # Indicates if user is archived.
  --change-password-at-next-login: oneof<nothing, bool> # Indicates if the user is forced to change their password at next login. This setting doesn't apply when [the user signs in via a third-party identity provider](https://support.google.com/a/answer/60224).
  --custom-schemas: record # Custom fields of the user. The key is a `schema_name` and its values are `'field_name': 'field_value'`.
  --emails: any # The list of the user's email addresses. The maximum allowed data size for this field is 10KB.
  --external-ids: any # The list of external IDs for the user, such as an employee or network ID. The maximum allowed data size for this field is 2KB.
  --gender: any # The user's gender. The maximum allowed data size for this field is 1KB.
  --hash-function: string # Stores the hash format of the `password` property. The following `hashFunction` values are allowed: * `MD5` - Accepts simple hex-encoded values. * `SHA-1` - Accepts simple hex-encoded values. * `crypt` - Compliant with the [C crypt library](https://en.wikipedia.org/wiki/Crypt_%28C%29). Supports the DES, MD5 (hash prefix `$1$`), SHA-256 (hash prefix `$5$`), and SHA-512 (hash prefix `$6$`) hash algorithms. If rounds are specified as part of the prefix, they must be 10,000 or fewer.
  --id: string # The unique ID for the user. A user `id` can be used as a user request URI's `userKey`.
  --ims: any # The list of the user's Instant Messenger (IM) accounts. A user account can have multiple ims properties. But, only one of these ims properties can be the primary IM contact. The maximum allowed data size for this field is 2KB.
  --include-in-global-address-list: oneof<nothing, bool> # Indicates if the user's profile is visible in the Google Workspace global address list when the contact sharing feature is enabled for the domain. For more information about excluding user profiles, see the [administration help center](https://support.google.com/a/answer/1285988).
  --ip-whitelisted: oneof<nothing, bool> # If `true`, the user's IP address is subject to a deprecated IP address [`allowlist`](https://support.google.com/a/answer/60752) configuration.
  --keywords: any # The list of the user's keywords. The maximum allowed data size for this field is 1KB.
  --languages: any # The user's languages. The maximum allowed data size for this field is 1KB.
  --locations: any # The user's locations. The maximum allowed data size for this field is 10KB.
  --name: record # shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
  --notes: any # Notes for the user.
  --org-unit-path: string # The full path of the parent organization associated with the user. If the parent organization is the top-level, it is represented as a forward slash (`/`).
  --organizations: any # The list of organizations the user belongs to. The maximum allowed data size for this field is 10KB.
  --password: string # User's password
  --phones: any # The list of the user's phone numbers. The maximum allowed data size for this field is 1KB.
  --posix-accounts: any # The list of [POSIX](https://www.opengroup.org/austin/papers/posix_faq.html) account information for the user.
  --primary-email: string # The user's primary email address. This property is required in a request to create a user account. The `primaryEmail` must be unique and cannot be an alias of another user.
  --recovery-email: string # Recovery email of the user.
  --recovery-phone: string # Recovery phone of the user. The phone number must be in the E.164 format, starting with the plus sign (+). Example: *+16506661212*.
  --relations: any # The list of the user's relationships to other users. The maximum allowed data size for this field is 2KB.
  --ssh-public-keys: any # A list of SSH public keys.
  --suspended: oneof<nothing, bool> # Indicates if user is suspended.
  --websites: any # The user's websites. The maximum allowed data size for this field is 2KB.
]: any -> record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}") $qp)
  let req_body = {"addresses": $addresses, "archived": $archived, "changePasswordAtNextLogin": $change_password_at_next_login, "customSchemas": $custom_schemas, "emails": $emails, "externalIds": $external_ids, "gender": $gender, "hashFunction": $hash_function, "id": $id, "ims": $ims, "includeInGlobalAddressList": $include_in_global_address_list, "ipWhitelisted": $ip_whitelisted, "keywords": $keywords, "languages": $languages, "locations": $locations, "name": $name, "notes": $notes, "orgUnitPath": $org_unit_path, "organizations": $organizations, "password": $password, "phones": $phones, "posixAccounts": $posix_accounts, "primaryEmail": $primary_email, "recoveryEmail": $recovery_email, "recoveryPhone": $recovery_phone, "relations": $relations, "sshPublicKeys": $ssh_public_keys, "suspended": $suspended, "websites": $websites} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Updates a user. This method supports patch semantics, meaning that you only need to include the fields you wish to update. Fields that are not present in the request will be preserved, and fields set to `null` will be cleared. For repeating fields that contain arrays, individual items in the array can't be patched piecemeal; they must be supplied in the request body with the desired values for all items. See the [user accounts guide](https://developers.google.com/admin-sdk/directory/v1/guides/manage-users#update_user) for more information.
#
# PUT /admin/directory/v1/users/{userKey}
# operationId: directory.users.update
# --name shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
export def "admin-directory-users update-by-user-key-1" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --addresses: any # The list of the user's addresses. The maximum allowed data size for this field is 10KB.
  --archived: oneof<nothing, bool> # Indicates if user is archived.
  --change-password-at-next-login: oneof<nothing, bool> # Indicates if the user is forced to change their password at next login. This setting doesn't apply when [the user signs in via a third-party identity provider](https://support.google.com/a/answer/60224).
  --custom-schemas: record # Custom fields of the user. The key is a `schema_name` and its values are `'field_name': 'field_value'`.
  --emails: any # The list of the user's email addresses. The maximum allowed data size for this field is 10KB.
  --external-ids: any # The list of external IDs for the user, such as an employee or network ID. The maximum allowed data size for this field is 2KB.
  --gender: any # The user's gender. The maximum allowed data size for this field is 1KB.
  --hash-function: string # Stores the hash format of the `password` property. The following `hashFunction` values are allowed: * `MD5` - Accepts simple hex-encoded values. * `SHA-1` - Accepts simple hex-encoded values. * `crypt` - Compliant with the [C crypt library](https://en.wikipedia.org/wiki/Crypt_%28C%29). Supports the DES, MD5 (hash prefix `$1$`), SHA-256 (hash prefix `$5$`), and SHA-512 (hash prefix `$6$`) hash algorithms. If rounds are specified as part of the prefix, they must be 10,000 or fewer.
  --id: string # The unique ID for the user. A user `id` can be used as a user request URI's `userKey`.
  --ims: any # The list of the user's Instant Messenger (IM) accounts. A user account can have multiple ims properties. But, only one of these ims properties can be the primary IM contact. The maximum allowed data size for this field is 2KB.
  --include-in-global-address-list: oneof<nothing, bool> # Indicates if the user's profile is visible in the Google Workspace global address list when the contact sharing feature is enabled for the domain. For more information about excluding user profiles, see the [administration help center](https://support.google.com/a/answer/1285988).
  --ip-whitelisted: oneof<nothing, bool> # If `true`, the user's IP address is subject to a deprecated IP address [`allowlist`](https://support.google.com/a/answer/60752) configuration.
  --keywords: any # The list of the user's keywords. The maximum allowed data size for this field is 1KB.
  --languages: any # The user's languages. The maximum allowed data size for this field is 1KB.
  --locations: any # The user's locations. The maximum allowed data size for this field is 10KB.
  --name: record # shape: {displayName?: string, familyName?: string, fullName?: string, givenName?: string}
  --notes: any # Notes for the user.
  --org-unit-path: string # The full path of the parent organization associated with the user. If the parent organization is the top-level, it is represented as a forward slash (`/`).
  --organizations: any # The list of organizations the user belongs to. The maximum allowed data size for this field is 10KB.
  --password: string # User's password
  --phones: any # The list of the user's phone numbers. The maximum allowed data size for this field is 1KB.
  --posix-accounts: any # The list of [POSIX](https://www.opengroup.org/austin/papers/posix_faq.html) account information for the user.
  --primary-email: string # The user's primary email address. This property is required in a request to create a user account. The `primaryEmail` must be unique and cannot be an alias of another user.
  --recovery-email: string # Recovery email of the user.
  --recovery-phone: string # Recovery phone of the user. The phone number must be in the E.164 format, starting with the plus sign (+). Example: *+16506661212*.
  --relations: any # The list of the user's relationships to other users. The maximum allowed data size for this field is 2KB.
  --ssh-public-keys: any # A list of SSH public keys.
  --suspended: oneof<nothing, bool> # Indicates if user is suspended.
  --websites: any # The user's websites. The maximum allowed data size for this field is 2KB.
]: any -> record<addresses: any, agreedToTerms: bool, aliases: list<string>, archived: bool, changePasswordAtNextLogin: bool, creationTime: string, customSchemas: record, customerId: string, deletionTime: string, emails: any, etag: string, externalIds: any, gender: any, hashFunction: string, id: string, ims: any, includeInGlobalAddressList: bool, ipWhitelisted: bool, isAdmin: bool, isDelegatedAdmin: bool, isEnforcedIn2Sv: bool, isEnrolledIn2Sv: bool, isMailboxSetup: bool, keywords: any, kind: string, languages: any, lastLoginTime: string, locations: any, name: record<displayName: string, familyName: string, fullName: string, givenName: string>, nonEditableAliases: list<string>, notes: any, orgUnitPath: string, organizations: any, password: string, phones: any, posixAccounts: any, primaryEmail: string, recoveryEmail: string, recoveryPhone: string, relations: any, sshPublicKeys: any, suspended: bool, suspensionReason: string, thumbnailPhotoEtag: string, thumbnailPhotoUrl: string, websites: any> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}") $qp)
  let req_body = {"addresses": $addresses, "archived": $archived, "changePasswordAtNextLogin": $change_password_at_next_login, "customSchemas": $custom_schemas, "emails": $emails, "externalIds": $external_ids, "gender": $gender, "hashFunction": $hash_function, "id": $id, "ims": $ims, "includeInGlobalAddressList": $include_in_global_address_list, "ipWhitelisted": $ip_whitelisted, "keywords": $keywords, "languages": $languages, "locations": $locations, "name": $name, "notes": $notes, "orgUnitPath": $org_unit_path, "organizations": $organizations, "password": $password, "phones": $phones, "posixAccounts": $posix_accounts, "primaryEmail": $primary_email, "recoveryEmail": $recovery_email, "recoveryPhone": $recovery_phone, "relations": $relations, "sshPublicKeys": $ssh_public_keys, "suspended": $suspended, "websites": $websites} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists all aliases for a user.
#
# GET /admin/directory/v1/users/{userKey}/aliases
# operationId: directory.users.aliases.list
export def "admin-directory-users-aliases list" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --event: string@event-completer-1 # Events to watch for.
]: nothing -> record<aliases: list<any>, etag: string, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "event" $event "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/aliases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "event": $event} | compact), body: null}
}

# Adds an alias.
#
# POST /admin/directory/v1/users/{userKey}/aliases
# operationId: directory.users.aliases.insert
export def "admin-directory-users-aliases create" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --alias: string
  --etag: string
  --id: string
  --kind: string # default: admin#directory#alias
  --primary-email: string
]: any -> record<alias: string, etag: string, id: string, kind: string, primaryEmail: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/aliases") $qp)
  let req_body = {"alias": $alias, "etag": $etag, "id": $id, "kind": $kind, "primaryEmail": $primary_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Watches for changes in users list.
#
# POST /admin/directory/v1/users/{userKey}/aliases/watch
# operationId: directory.users.aliases.watch
export def "admin-directory-users-aliases-watch watch" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --event: string@event-completer-1 # Events to watch for.
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is `api#channel`. (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional. For example, `params.ttl` specifies the time-to-live in seconds for the notification channel, where the default is 2 hours and the maximum TTL is 2 days.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel.
]: any -> record<address: string, expiration: string, id: string, kind: string, params: record, payload: bool, resourceId: string, resourceUri: string, token: string, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "event" $event "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/aliases/watch") $qp)
  let req_body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "event": $event} | compact), body: $req_body}
}

# Removes an alias.
#
# DELETE /admin/directory/v1/users/{userKey}/aliases/{alias}
# operationId: directory.users.aliases.delete
export def "admin-directory-users-aliases delete" [
  user_key: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key), alias: (encode-path-segment $alias)} | format pattern "/admin/directory/v1/users/{user_key}/aliases/{alias}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Lists the ASPs issued by a user.
#
# GET /admin/directory/v1/users/{userKey}/asps
# operationId: directory.asps.list
export def "admin-directory-users-asps list" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<etag: string, items: table<codeId: int, creationTime: string, etag: string, kind: string, lastTimeUsed: string, name: string, userKey: string>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/asps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Deletes an ASP issued by a user.
#
# DELETE /admin/directory/v1/users/{userKey}/asps/{codeId}
# operationId: directory.asps.delete
export def "admin-directory-users-asps delete" [
  user_key: string
  code_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($code_id | is-empty) { error make --unspanned { msg: "path parameter 'codeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key), code_id: (encode-path-segment $code_id)} | format pattern "/admin/directory/v1/users/{user_key}/asps/{code_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets information about an ASP issued by a user.
#
# GET /admin/directory/v1/users/{userKey}/asps/{codeId}
# operationId: directory.asps.get
export def "admin-directory-users-asps get" [
  user_key: string
  code_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<codeId: int, creationTime: string, etag: string, kind: string, lastTimeUsed: string, name: string, userKey: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($code_id | is-empty) { error make --unspanned { msg: "path parameter 'codeId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key), code_id: (encode-path-segment $code_id)} | format pattern "/admin/directory/v1/users/{user_key}/asps/{code_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Makes a user a super administrator.
#
# POST /admin/directory/v1/users/{userKey}/makeAdmin
# operationId: directory.users.makeAdmin
export def "admin-directory-users-make-admin create" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --status: oneof<nothing, bool> # Indicates the administrator status of the user.
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/makeAdmin") $qp)
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Removes the user's photo.
#
# DELETE /admin/directory/v1/users/{userKey}/photos/thumbnail
# operationId: directory.users.photos.delete
export def "admin-directory-users-photos-thumbnail delete" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/photos/thumbnail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Retrieves the user's photo.
#
# GET /admin/directory/v1/users/{userKey}/photos/thumbnail
# operationId: directory.users.photos.get
export def "admin-directory-users-photos-thumbnail get" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/photos/thumbnail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Adds a photo for the user. This method supports [patch semantics](/admin-sdk/directory/v1/guides/performance#patch).
#
# PATCH /admin/directory/v1/users/{userKey}/photos/thumbnail
# operationId: directory.users.photos.patch
export def "admin-directory-users-photos-thumbnail update-by-user-key" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --etag: string # ETag of the resource.
  --height: int # Height of the photo in pixels. (format: int32)
  --id: string # The ID the API uses to uniquely identify the user.
  --kind: string # The type of the API resource. For Photo resources, this is `admin#directory#user#photo`. (default: admin#directory#user#photo)
  --mime-type: string # The MIME type of the photo. Allowed values are `JPEG`, `PNG`, `GIF`, `BMP`, `TIFF`, and web-safe base64 encoding.
  --photo-data: string # The user photo's upload data in [web-safe Base64](https://en.wikipedia.org/wiki/Base64#URL_applications) format in bytes. This means: * The slash (/) character is replaced with the underscore (_) character. * The plus sign (+) character is replaced with the hyphen (-) character. * The equals sign (=) character is replaced with the asterisk (*). * For padding, the period (.) character is used instead of the RFC-4648 baseURL definition which uses the equals sign (=) for padding. This is done to simplify URL-parsing. * Whatever the size of the photo being uploaded, the API downsizes it to 96x96 pixels. (format: byte)
  --primary-email: string # The user's primary email address.
  --width: int # Width of the photo in pixels. (format: int32)
]: any -> record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/photos/thumbnail") $qp)
  let req_body = {"etag": $etag, "height": $height, "id": $id, "kind": $kind, "mimeType": $mime_type, "photoData": $photo_data, "primaryEmail": $primary_email, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Adds a photo for the user.
#
# PUT /admin/directory/v1/users/{userKey}/photos/thumbnail
# operationId: directory.users.photos.update
export def "admin-directory-users-photos-thumbnail update-by-user-key-1" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --etag: string # ETag of the resource.
  --height: int # Height of the photo in pixels. (format: int32)
  --id: string # The ID the API uses to uniquely identify the user.
  --kind: string # The type of the API resource. For Photo resources, this is `admin#directory#user#photo`. (default: admin#directory#user#photo)
  --mime-type: string # The MIME type of the photo. Allowed values are `JPEG`, `PNG`, `GIF`, `BMP`, `TIFF`, and web-safe base64 encoding.
  --photo-data: string # The user photo's upload data in [web-safe Base64](https://en.wikipedia.org/wiki/Base64#URL_applications) format in bytes. This means: * The slash (/) character is replaced with the underscore (_) character. * The plus sign (+) character is replaced with the hyphen (-) character. * The equals sign (=) character is replaced with the asterisk (*). * For padding, the period (.) character is used instead of the RFC-4648 baseURL definition which uses the equals sign (=) for padding. This is done to simplify URL-parsing. * Whatever the size of the photo being uploaded, the API downsizes it to 96x96 pixels. (format: byte)
  --primary-email: string # The user's primary email address.
  --width: int # Width of the photo in pixels. (format: int32)
]: any -> record<etag: string, height: int, id: string, kind: string, mimeType: string, photoData: string, primaryEmail: string, width: int> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/photos/thumbnail") $qp)
  let req_body = {"etag": $etag, "height": $height, "id": $id, "kind": $kind, "mimeType": $mime_type, "photoData": $photo_data, "primaryEmail": $primary_email, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Signs a user out of all web and device sessions and reset their sign-in cookies. User will have to sign in by authenticating again.
#
# POST /admin/directory/v1/users/{userKey}/signOut
# operationId: directory.users.signOut
export def "admin-directory-users-sign-out create" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/signOut") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Returns the set of tokens specified user has issued to 3rd party applications.
#
# GET /admin/directory/v1/users/{userKey}/tokens
# operationId: directory.tokens.list
export def "admin-directory-users-tokens list" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<etag: string, items: table<anonymous: bool, clientId: string, displayText: string, etag: string, kind: string, nativeApp: bool, scopes: list, userKey: string>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/tokens") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Deletes all access tokens issued by a user for an application.
#
# DELETE /admin/directory/v1/users/{userKey}/tokens/{clientId}
# operationId: directory.tokens.delete
export def "admin-directory-users-tokens delete" [
  user_key: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key), client_id: (encode-path-segment $client_id)} | format pattern "/admin/directory/v1/users/{user_key}/tokens/{client_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets information about an access token issued by a user.
#
# GET /admin/directory/v1/users/{userKey}/tokens/{clientId}
# operationId: directory.tokens.get
export def "admin-directory-users-tokens get" [
  user_key: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<anonymous: bool, clientId: string, displayText: string, etag: string, kind: string, nativeApp: bool, scopes: list<string>, userKey: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key), client_id: (encode-path-segment $client_id)} | format pattern "/admin/directory/v1/users/{user_key}/tokens/{client_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Turns off 2-Step Verification for user.
#
# POST /admin/directory/v1/users/{userKey}/twoStepVerification/turnOff
# operationId: directory.twoStepVerification.turnOff
export def "admin-directory-users-two-step-verification-turn-off create" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/twoStepVerification/turnOff") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Undeletes a deleted user.
#
# POST /admin/directory/v1/users/{userKey}/undelete
# operationId: directory.users.undelete
export def "admin-directory-users-undelete create" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --org-unit-path: string # OrgUnit of User
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/undelete") $qp)
  let req_body = {"orgUnitPath": $org_unit_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Returns the current set of valid backup verification codes for the specified user.
#
# GET /admin/directory/v1/users/{userKey}/verificationCodes
# operationId: directory.verificationCodes.list
export def "admin-directory-users-verification-codes list" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<etag: string, items: table<etag: string, kind: string, userId: string, verificationCode: string>, kind: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/verificationCodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Generates new backup verification codes for the user.
#
# POST /admin/directory/v1/users/{userKey}/verificationCodes/generate
# operationId: directory.verificationCodes.generate
export def "admin-directory-users-verification-codes-generate generate" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/verificationCodes/generate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Invalidates the current backup verification codes for the user.
#
# POST /admin/directory/v1/users/{userKey}/verificationCodes/invalidate
# operationId: directory.verificationCodes.invalidate
export def "admin-directory-users-verification-codes-invalidate create" [
  user_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($user_key | is-empty) { error make --unspanned { msg: "path parameter 'userKey' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_key: (encode-path-segment $user_key)} | format pattern "/admin/directory/v1/users/{user_key}/verificationCodes/invalidate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Deletes a print server.
#
# DELETE /admin/directory/v1/{name}
# operationId: admin.customers.chrome.printServers.delete
export def "admin-directory delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/admin/directory/v1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Returns a print server's configuration.
#
# GET /admin/directory/v1/{name}
# operationId: admin.customers.chrome.printServers.get
export def "admin-directory get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/admin/directory/v1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Updates a print server's configuration.
#
# PATCH /admin/directory/v1/{name}
# operationId: admin.customers.chrome.printServers.patch
export def "admin-directory update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --update-mask: string # The list of fields to update. Some fields are read-only and cannot be updated. Values for unspecified fields are patched.
  --description: string # Editable. Description of the print server (as shown in the Admin console).
  --display-name: string # Editable. Display name of the print server (as shown in the Admin console).
  --id: string # Immutable. ID of the print server. Leave empty when creating.
  --body-name: string # Immutable. Resource name of the print server. Leave empty when creating. Format: `customers/{customer.id}/printServers/{print_server.id}`
  --org-unit-id: string # ID of the organization unit (OU) that owns this print server. This value can only be set when the print server is initially created. If it's not populated, the print server is placed under the root OU. The `org_unit_id` can be retrieved using the [Directory API](/admin-sdk/directory/reference/rest/v1/orgunits).
  --uri: string # Editable. Print server URI.
]: any -> record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/admin/directory/v1/{name}") $qp)
  let req_body = {"description": $description, "displayName": $display_name, "id": $id, "name": $body_name, "orgUnitId": $org_unit_id, "uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "updateMask": $update_mask} | compact), body: $req_body}
}

# Lists print server configurations.
#
# GET /admin/directory/v1/{parent}/chrome/printServers
# operationId: admin.customers.chrome.printServers.list
export def "admin-directory-chrome-print-servers list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --filter: string # Search query in [Common Expression Language syntax](https://github.com/google/cel-spec). Supported filters are `display_name`, `description`, and `uri`. Example: `printServer.displayName=='marketing-queue'`.
  --order-by: string # Sort order for results. Supported values are `display_name`, `description`, or `create_time`. Default order is ascending, but descending order can be returned by appending "desc" to the `order_by` field. For instance, `orderBy=='description desc'` returns the print servers sorted by description in descending order.
  --org-unit-id: string # If `org_unit_id` is present in the request, only print servers owned or inherited by the organizational unit (OU) are returned. If the `PrintServer` resource's `org_unit_id` matches the one in the request, the OU owns the server. If `org_unit_id` is not specified in the request, all print servers are returned or filtered against.
  --page-size: int # The maximum number of objects to return (default `100`, max `100`). The service might return fewer than this value.
  --page-token: string # A generated token to paginate results (the `next_page_token` from a previous call).
]: nothing -> record<nextPageToken: string, printServers: table<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "orgUnitId" $org_unit_id "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printServers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "orgUnitId": $org_unit_id, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Creates a print server.
#
# POST /admin/directory/v1/{parent}/chrome/printServers
# operationId: admin.customers.chrome.printServers.create
export def "admin-directory-chrome-print-servers create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --description: string # Editable. Description of the print server (as shown in the Admin console).
  --display-name: string # Editable. Display name of the print server (as shown in the Admin console).
  --id: string # Immutable. ID of the print server. Leave empty when creating.
  --name: string # Immutable. Resource name of the print server. Leave empty when creating. Format: `customers/{customer.id}/printServers/{print_server.id}`
  --org-unit-id: string # ID of the organization unit (OU) that owns this print server. This value can only be set when the print server is initially created. If it's not populated, the print server is placed under the root OU. The `org_unit_id` can be retrieved using the [Directory API](/admin-sdk/directory/reference/rest/v1/orgunits).
  --uri: string # Editable. Print server URI.
]: any -> record<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printServers") $qp)
  let req_body = {"description": $description, "displayName": $display_name, "id": $id, "name": $name, "orgUnitId": $org_unit_id, "uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Creates multiple print servers.
#
# POST /admin/directory/v1/{parent}/chrome/printServers:batchCreatePrintServers
# operationId: admin.customers.chrome.printServers.batchCreatePrintServers
# --requests item shape: {parent?: string, printServer?: record}
export def "admin-directory-chrome-print-servers-batch-create-print-servers create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --requests: list # Required. A list of `PrintServer` resources to be created (max `50` per batch). — item shape: {parent?: string, printServer?: record}
]: any -> record<failures: table<errorCode: string, errorMessage: string, printServer: record, printServerId: string>, printServers: table<createTime: string, description: string, displayName: string, id: string, name: string, orgUnitId: string, uri: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printServers:batchCreatePrintServers") $qp)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes multiple print servers.
#
# POST /admin/directory/v1/{parent}/chrome/printServers:batchDeletePrintServers
# operationId: admin.customers.chrome.printServers.batchDeletePrintServers
export def "admin-directory-chrome-print-servers-batch-delete-print-servers delete" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --print-server-ids: list<string> # A list of print server IDs that should be deleted (max `100` per batch).
]: any -> record<failedPrintServers: table<errorCode: string, errorMessage: string, printServer: record, printServerId: string>, printServerIds: list<string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printServers:batchDeletePrintServers") $qp)
  let req_body = {"printServerIds": $print_server_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# List printers configs.
#
# GET /admin/directory/v1/{parent}/chrome/printers
# operationId: admin.customers.chrome.printers.list
export def "admin-directory-chrome-printers list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --filter: string # Search query. Search syntax is shared between this api and Admin Console printers pages.
  --order-by: string # The order to sort results by. Must be one of display_name, description, make_and_model, or create_time. Default order is ascending, but descending order can be returned by appending "desc" to the order_by field. For instance, "description desc" will return the printers sorted by description in descending order.
  --org-unit-id: string # Organization Unit that we want to list the printers for. When org_unit is not present in the request then all printers of the customer are returned (or filtered). When org_unit is present in the request then only printers available to this OU will be returned (owned or inherited). You may see if printer is owned or inherited for this OU by looking at Printer.org_unit_id.
  --page-size: int # The maximum number of objects to return. The service may return fewer than this value.
  --page-token: string # A page token, received from a previous call.
]: nothing -> record<nextPageToken: string, printers: table<auxiliaryMessages: list, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "orgUnitId" $org_unit_id "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "orderBy": $order_by, "orgUnitId": $org_unit_id, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Creates a printer under given Organization Unit.
#
# POST /admin/directory/v1/{parent}/chrome/printers
# operationId: admin.customers.chrome.printers.create
# --auxiliaryMessages item shape: {auxiliaryMessage?: string, fieldMask?: string, severity?: "SEVERITY_UNSPECIFIED"|"SEVERITY_INFO"|"SEVERITY_WARNING"|"SEVERITY_ERROR"}
export def "admin-directory-chrome-printers create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --description: string # Editable. Description of printer.
  --display-name: string # Editable. Name of printer.
  --id: string # Id of the printer. (During printer creation leave empty)
  --make-and-model: string # Editable. Make and model of printer. e.g. Lexmark MS610de Value must be in format as seen in ListPrinterModels response.
  --name: string # The resource name of the Printer object, in the format customers/{customer-id}/printers/{printer-id} (During printer creation leave empty)
  --org-unit-id: string # Organization Unit that owns this printer (Only can be set during Printer creation)
  --uri: string # Editable. Printer URI.
  --use-driverless-config: oneof<nothing, bool> # Editable. flag to use driverless configuration or not. If it's set to be true, make_and_model can be ignored
]: any -> record<auxiliaryMessages: table<auxiliaryMessage: string, fieldMask: string, severity: string>, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printers") $qp)
  let req_body = {"description": $description, "displayName": $display_name, "id": $id, "makeAndModel": $make_and_model, "name": $name, "orgUnitId": $org_unit_id, "uri": $uri, "useDriverlessConfig": $use_driverless_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Creates printers under given Organization Unit.
#
# POST /admin/directory/v1/{parent}/chrome/printers:batchCreatePrinters
# operationId: admin.customers.chrome.printers.batchCreatePrinters
# --requests item shape: {parent?: string, printer?: record}
export def "admin-directory-chrome-printers-batch-create-printers create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --requests: list # A list of Printers to be created. Max 50 at a time. — item shape: {parent?: string, printer?: record}
]: any -> record<failures: table<errorCode: string, errorMessage: string, printer: record, printerId: string>, printers: table<auxiliaryMessages: list, createTime: string, description: string, displayName: string, id: string, makeAndModel: string, name: string, orgUnitId: string, uri: string, useDriverlessConfig: bool>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printers:batchCreatePrinters") $qp)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Deletes printers in batch.
#
# POST /admin/directory/v1/{parent}/chrome/printers:batchDeletePrinters
# operationId: admin.customers.chrome.printers.batchDeletePrinters
export def "admin-directory-chrome-printers-batch-delete-printers delete" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --printer-ids: list<string> # A list of Printer.id that should be deleted. Max 100 at a time.
]: any -> record<failedPrinters: table<errorCode: string, errorMessage: string, printer: record, printerId: string>, printerIds: list<string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printers:batchDeletePrinters") $qp)
  let req_body = {"printerIds": $printer_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists the supported printer models.
#
# GET /admin/directory/v1/{parent}/chrome/printers:listPrinterModels
# operationId: admin.customers.chrome.printers.listPrinterModels
export def "admin-directory-chrome-printers-list-printer-models list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --filter: string # Filer to list only models by a given manufacturer in format: "manufacturer:Brother". Search syntax is shared between this api and Admin Console printers pages.
  --page-size: int # The maximum number of objects to return. The service may return fewer than this value.
  --page-token: string # A page token, received from a previous call.
]: nothing -> record<nextPageToken: string, printerModels: table<displayName: string, makeAndModel: string, manufacturer: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/admin/directory/v1/{parent}/chrome/printers:listPrinterModels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Stops watching resources through this channel.
#
# POST /admin/directory_v1/channels/stop
# operationId: admin.channels.stop
export def "admin-directory-v1-channels-stop stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --address: string # The address where notifications are delivered for this channel.
  --expiration: string # Date and time of notification channel expiration, expressed as a Unix timestamp, in milliseconds. Optional. (format: int64)
  --id: string # A UUID or similar unique string that identifies this channel.
  --kind: string # Identifies this as a notification channel used to watch for changes to a resource, which is `api#channel`. (default: api#channel)
  --params: record # Additional parameters controlling delivery channel behavior. Optional. For example, `params.ttl` specifies the time-to-live in seconds for the notification channel, where the default is 2 hours and the maximum TTL is 2 days.
  --payload: oneof<nothing, bool> # A Boolean value to indicate whether payload is wanted. Optional.
  --resource-id: string # An opaque ID that identifies the resource being watched on this channel. Stable across different API versions.
  --resource-uri: string # A version-specific identifier for the watched resource.
  --body-token: string # An arbitrary string delivered to the target address with each notification delivered over this channel. Optional.
  --type: string # The type of delivery mechanism used for this channel.
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o ADMIN_SDK_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o ADMIN_SDK_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/directory_v1/channels/stop" $qp)
  let req_body = {"address": $address, "expiration": $expiration, "id": $id, "kind": $kind, "params": $params, "payload": $payload, "resourceId": $resource_id, "resourceUri": $resource_uri, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}
