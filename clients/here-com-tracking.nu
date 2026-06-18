# Auto-generated client for HERE Tracking v2.1.191
# Source: https://api.apis.guru/v2/specs/here.com/tracking/2.1.191/openapi.json
# Auth: --token flag or $env.HERE_TRACKING_TOKEN

const BASE_URL = "https://tracking.api.here.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HERE_TRACKING_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "oauth" => { {headers: {Authorization: $"Oauth ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://tracking.api.here.com"] }
def auth-scheme-completer [] { ["bearer" "oauth"] }

# Completers for enum parameters
def x-confirm-completer [] { ["true"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def type-completer [] { ["create" "delete"] }
def action-completer [] { ["acknowledge" "cancel"] }
def group-by-completer [] { ["eventSource" "ruleId"] }
def type-completer-1 [] { ["circle"] }
def channel-type-completer [] { ["browserPull" "email" "webhook"] }
def event-source-completer [] { ["acceleration" "attach" "battery" "detention" "dwelling" "geofence" "humidity" "online" "pressure" "shipmentSchedule" "stock" "tamper" "temperature" "utilization"] }
def event-type-completer [] { ["ABOVE_RANGE" "BELOW_RANGE" "DETENTION_ENDED" "DETENTION_STARTED" "DWELLING_ENDED" "DWELLING_STARTED" "EVENT" "FALSE_TO_TRUE" "INSIDE_GEOFENCE" "IN_RANGE" "NORMAL_VOLUME" "OUTSIDE_GEOFENCE" "OVERSTOCK" "SHIPMENT_DELAYED" "SHIPMENT_EARLY" "SHIPMENT_ON_TIME" "TRUE_TO_FALSE" "UNDERSTOCK" "UNUTILIZED" "UTILIZED"] }
def measure-completer [] { ["asset" "day" "duration" "occurrence"] }
def interval-completer [] { ["day" "month" "week"] }
def group-by-completer-1 [] { ["asset" "geofence"] }
def method-completer [] { ["average" "cumulative" "percentage"] }
def type-completer-2 [] { ["utilization"] }
def type-completer-3 [] { ["battery"] }
def accept-completer-1 [] { ["application/json" "text/plain"] }
def status-completer [] { ["cancelled" "completed" "ongoing" "pending"] }
def transport-mode-completer [] { ["air" "car" "sea" "truck" "undefined"] }
def mode-completer [] { ["flight" "normal" "sleep" "transport" "unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "aliases get" } } | get name | first)
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

# Gets all aliases
#
# GET /aliases/v2
export def "aliases get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # An alias type
  --external-id: string # Filter for aliases external IDs
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: table<aliases: record, trackingId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "externalId" $external_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aliases/v2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /aliases/v2/health
export def "aliases-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aliases/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the tracking ID associated with an alias
#
# GET /aliases/v2/trackingId
export def "aliases-tracking-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # An alias type
  --external-id: string # An external ID. An externalId and type pair uniquely identifies an alias.
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<appId: string, externalId: string, trackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "externalId" $external_id "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aliases/v2/trackingId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /aliases/v2/version
export def "aliases-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aliases/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes all aliases of a device
#
# DELETE /aliases/v2/{trackingId}
export def "aliases delete-by-trackingId" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/aliases/v2/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all aliases of a device
#
# GET /aliases/v2/{trackingId}
export def "aliases get-by-trackingId" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --type: string # An alias type
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/aliases/v2/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates multiple aliases for a device
#
# PUT /aliases/v2/{trackingId}/batch
export def "aliases-batch update" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  aliases: record # A map of key-value pairs where the key is the type of the alias and the value is an array of `externalId`s.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/aliases/v2/{tracking_id}/batch") $qp)
  let req_body = {"aliases": $aliases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes all aliases of a specified type for a device
#
# DELETE /aliases/v2/{trackingId}/{type}
export def "aliases delete-by-trackingId-type" [
  tracking_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), type: (encode-path-segment $type)} | format pattern "/aliases/v2/{tracking_id}/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all aliases of a specified type for a device
#
# GET /aliases/v2/{trackingId}/{type}
export def "aliases get-by-trackingId-type" [
  tracking_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), type: (encode-path-segment $type)} | format pattern "/aliases/v2/{tracking_id}/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes an alias
#
# DELETE /aliases/v2/{trackingId}/{type}/{externalId}
export def "aliases delete-by-trackingId-type-externalId" [
  tracking_id: string
  type: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), type: (encode-path-segment $type), external_id: (encode-path-segment $external_id)} | format pattern "/aliases/v2/{tracking_id}/{type}/{external_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an alias
#
# PUT /aliases/v2/{trackingId}/{type}/{externalId}
export def "aliases update" [
  tracking_id: string
  type: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), type: (encode-path-segment $type), external_id: (encode-path-segment $external_id)} | format pattern "/aliases/v2/{tracking_id}/{type}/{external_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates rules associations for devices
#
# PUT /associations/v3/devices/batchUpdate
# --newRules shape: {geofenceIds: list<string>, ruleIds: list<string>}
# --oldRules shape: {geofenceIds: list<string>, ruleIds: list<string>}
export def "associations-devices-batch-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  new_rules: record # Rules to be associated to the devices — shape: {geofenceIds: list<string>, ruleIds: list<string>}
  old_rules: record # Rules to be disassociated from the devices — shape: {geofenceIds: list<string>, ruleIds: list<string>}
  tracking_ids: list<string> # Array of tracking IDs (external IDs are also permitted here)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/associations/v3/devices/batchUpdate" $qp)
  let req_body = {"newRules": $new_rules, "oldRules": $old_rules, "trackingIds": $tracking_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Associates rules with a device
#
# POST /associations/v3/devices/{trackingId}/batchCreate
export def "associations-devices-batch-create create" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  geofence_ids: list<string> # Array of geofence IDs
  rule_ids: list<string> # Array of rule IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/associations/v3/devices/{tracking_id}/batchCreate") $qp)
  let req_body = {"geofenceIds": $geofence_ids, "ruleIds": $rule_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disassociates rules from a device
#
# POST /associations/v3/devices/{trackingId}/batchDelete
export def "associations-devices-batch-delete create" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  geofence_ids: list<string> # Array of geofence IDs
  rule_ids: list<string> # Array of rule IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/associations/v3/devices/{tracking_id}/batchDelete") $qp)
  let req_body = {"geofenceIds": $geofence_ids, "ruleIds": $rule_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets all devices associated with a geofence
#
# GET /associations/v3/geofences/{geofenceId}
export def "associations-geofences get-by-geofenceId" [
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
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/associations/v3/geofences/{geofence_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /associations/v3/health
export def "associations-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/associations/v3/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all devices associated with a rule
#
# GET /associations/v3/rules/{ruleId}
export def "associations-rules get-by-ruleId" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/associations/v3/rules/{rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all devices associated with a sensor rule
#
# GET /associations/v3/sensors/{sensorRuleId}
export def "associations-sensors get-by-sensorRuleId" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/associations/v3/sensors/{sensor_rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /associations/v3/version
export def "associations-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/associations/v3/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets geofences associated with a device
#
# GET /associations/v3/{trackingId}/geofences
export def "associations-geofences get-by-trackingId" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --type: list<string> # Type of a geofence
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "type" $type "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/associations/v3/{tracking_id}/geofences") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Disassociates a device and a geofence
#
# DELETE /associations/v3/{trackingId}/geofences/{geofenceId}
export def "associations-geofences delete" [
  tracking_id: string
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
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), geofence_id: (encode-path-segment $geofence_id)} | format pattern "/associations/v3/{tracking_id}/geofences/{geofence_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associates a device to a geofence
#
# PUT /associations/v3/{trackingId}/geofences/{geofenceId}
export def "associations-geofences update" [
  tracking_id: string
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
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), geofence_id: (encode-path-segment $geofence_id)} | format pattern "/associations/v3/{tracking_id}/geofences/{geofence_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets rules associated with a device
#
# GET /associations/v3/{trackingId}/rules
export def "associations-rules get-by-trackingId" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/associations/v3/{tracking_id}/rules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Disassociates a device and a rule
#
# DELETE /associations/v3/{trackingId}/rules/{ruleId}
export def "associations-rules delete" [
  tracking_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/associations/v3/{tracking_id}/rules/{rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associates a device to a rule
#
# PUT /associations/v3/{trackingId}/rules/{ruleId}
export def "associations-rules update" [
  tracking_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/associations/v3/{tracking_id}/rules/{rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets sensor rules associated with a device
#
# GET /associations/v3/{trackingId}/sensors
export def "associations-sensors get-by-trackingId" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/associations/v3/{tracking_id}/sensors") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Disassociates a device and a sensor rule
#
# DELETE /associations/v3/{trackingId}/sensors/{sensorRuleId}
export def "associations-sensors delete" [
  tracking_id: string
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/associations/v3/{tracking_id}/sensors/{sensor_rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associates a device with a sensor rule
#
# PUT /associations/v3/{trackingId}/sensors/{sensorRuleId}
export def "associations-sensors update" [
  tracking_id: string
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/associations/v3/{tracking_id}/sensors/{sensor_rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the bulk upload job IDs for a project
#
# GET /bulkjobs/v4/deviceUploads
export def "bulkjobs-device-uploads get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --type: string@type-completer
  --status: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<jobId: string, status: string, type: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulkjobs/v4/deviceUploads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Starts bulk upload
#
# POST /bulkjobs/v4/deviceUploads
export def "bulkjobs-device-uploads create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --file-name: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: record
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "fileName" $file_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulkjobs/v4/deviceUploads" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if ($input | describe | str starts-with "list") { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates bulk upload job status
#
# PATCH /bulkjobs/v4/deviceUploads/{jobId}
export def "bulkjobs-device-uploads update" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  action: string@action-completer
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/bulkjobs/v4/deviceUploads/{job_id}") $qp)
  let req_body = {"action": $action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets bulk upload results
#
# GET /bulkjobs/v4/deviceUploads/{jobId}/results
export def "bulkjobs-device-uploads-results get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<connectorId: string, deviceId: string, deviceSecret: string, errors: list, externalDeviceId: string, externalId: string, name: string, trackingId: string>, limit: int, nextPageToken: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/bulkjobs/v4/deviceUploads/{job_id}/results") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets bulk upload status
#
# GET /bulkjobs/v4/deviceUploads/{jobId}/status
export def "bulkjobs-device-uploads-status get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<failed: int, fileName: string, partiallySucceeded: int, pending: int, progress: float, status: string, succeeded: int, total: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/bulkjobs/v4/deviceUploads/{job_id}/status") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /bulkjobs/v4/health
export def "bulkjobs-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulkjobs/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /bulkjobs/v4/version
export def "bulkjobs-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulkjobs/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Receives external device update reports
#
# POST /c2c/v4/callback
export def "c2c-callback create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API Key
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/c2c/v4/callback" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a list of connectors
#
# GET /c2c/v4/connectors
export def "c2c-connectors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<connectorId: string, projectId: string, description: string, driverId: string, enabled: bool, externalCloudInfo: record, name: string, refreshIntervalS: int, lastExecTs: string, totalAddedDevices: int, createdAt: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/c2c/v4/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a connector
#
# POST /c2c/v4/connectors
export def "c2c-connectors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --description: string # Brief description of the connector.
  driver_id: string # Identifier of the driver to be used with this connector.
  --enabled: oneof<nothing, bool> # Enabled state of the connector. If set to false then the connector will not execute periodically.
  external_cloud_info: record # An external cloud-specific object that the driver will use to login to the external cloud. The structure of this object varies per driver implementation. It is recommended to have dedicated credentials for logging in to the external cloud in order not to violate possible concurrent users policies of the external cloud. In case of the HERE Tracking loopback driver, the maximum allowed concurrent user account tokens is 3 per account, therefore it is recommended to create a separate HERE account and grant it the required privilege to update the connector's project, and use that account in externalCloudInfo.
  name: string # Name of the connector.
  --refresh-interval-s: int # This is the interval (in seconds) to execute the sync process between the connector's external cloud and HERE Tracking project. The maximum and at the same time default value for callback-type connectors is 900 seconds. The default value for other type of connectors is 3600 seconds and there is no maximum value set.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/c2c/v4/connectors" $qp)
  let req_body = {"description": $description, "driverId": $driver_id, "enabled": $enabled, "externalCloudInfo": $external_cloud_info, "name": $name, "refreshIntervalS": $refresh_interval_s} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets connector identifiers for an external device
#
# GET /c2c/v4/connectors/ext-devices/{externalDeviceId}
export def "c2c-connectors-ext-devices get-by-externalDeviceId" [
  external_device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<items: table<connectorId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({external_device_id: (encode-path-segment $external_device_id)} | format pattern "/c2c/v4/connectors/ext-devices/{external_device_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a connector
#
# DELETE /c2c/v4/connectors/{connectorId}
export def "c2c-connectors delete" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-devices: oneof<nothing, bool> # Unclaim and unprovision devices
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteDevices" $delete_devices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({connector_id: (encode-path-segment $connector_id)} | format pattern "/c2c/v4/connectors/{connector_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a connector info
#
# GET /c2c/v4/connectors/{connectorId}
export def "c2c-connectors get" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connectorId: string, projectId: string, description: string, driverId: string, enabled: bool, externalCloudInfo: record, name: string, refreshIntervalS: int, lastExecTs: string, totalAddedDevices: int, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({connector_id: (encode-path-segment $connector_id)} | format pattern "/c2c/v4/connectors/{connector_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a connector info
#
# PUT /c2c/v4/connectors/{connectorId}
export def "c2c-connectors update" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Brief description of the connector.
  driver_id: string # Identifier of the driver to be used with this connector.
  --enabled: oneof<nothing, bool> # Enabled state of the connector. If set to false then the connector will not execute periodically.
  external_cloud_info: record # An external cloud-specific object that the driver will use to login to the external cloud. The structure of this object varies per driver implementation. It is recommended to have dedicated credentials for logging in to the external cloud in order not to violate possible concurrent users policies of the external cloud. In case of the HERE Tracking loopback driver, the maximum allowed concurrent user account tokens is 3 per account, therefore it is recommended to create a separate HERE account and grant it the required privilege to update the connector's project, and use that account in externalCloudInfo.
  name: string # Name of the connector.
  --refresh-interval-s: int # This is the interval (in seconds) to execute the sync process between the connector's external cloud and HERE Tracking project. The maximum and at the same time default value for callback-type connectors is 900 seconds. The default value for other type of connectors is 3600 seconds and there is no maximum value set.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({connector_id: (encode-path-segment $connector_id)} | format pattern "/c2c/v4/connectors/{connector_id}"))
  let req_body = {"description": $description, "driverId": $driver_id, "enabled": $enabled, "externalCloudInfo": $external_cloud_info, "name": $name, "refreshIntervalS": $refresh_interval_s} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets all external devices under a connector
#
# GET /c2c/v4/connectors/{connectorId}/ext-devices
export def "c2c-connectors-ext-devices get-by-connectorId" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<enabled: bool, externalDeviceId: string, externalDeviceInfo: record, info: record, localDeviceId: string, provisioning: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({connector_id: (encode-path-segment $connector_id)} | format pattern "/c2c/v4/connectors/{connector_id}/ext-devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Adds external devices to a connector
#
# POST /c2c/v4/connectors/{connectorId}/ext-devices
export def "c2c-connectors-ext-devices create" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({connector_id: (encode-path-segment $connector_id)} | format pattern "/c2c/v4/connectors/{connector_id}/ext-devices"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes a batch of external devices from a connector
#
# DELETE /c2c/v4/connectors/{connectorId}/ext-devices-batch
export def "c2c-connectors-ext-devices-batch delete" [
  connector_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --external-device-ids: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({connector_id: (encode-path-segment $connector_id)} | format pattern "/c2c/v4/connectors/{connector_id}/ext-devices-batch"))
  let req_body = {"externalDeviceIds": $external_device_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes an external device from a connector
#
# DELETE /c2c/v4/connectors/{connectorId}/ext-devices/{externalDeviceId}
export def "c2c-connectors-ext-devices delete" [
  connector_id: string
  external_device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({connector_id: (encode-path-segment $connector_id), external_device_id: (encode-path-segment $external_device_id)} | format pattern "/c2c/v4/connectors/{connector_id}/ext-devices/{external_device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a list of drivers
#
# GET /c2c/v4/drivers
export def "c2c-drivers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<autoProvisionCallbackDevices: bool, driverId: string, driverSyncMethod: string, driverType: string, externalCloudInfoSchema: list, provider: string, strategy: record, version: int>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/c2c/v4/drivers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Validate and verify external cloud credentials for driver
#
# POST /c2c/v4/drivers/{driverId}/verify
export def "c2c-drivers-verify create" [
  driver_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({driver_id: (encode-path-segment $driver_id)} | format pattern "/c2c/v4/drivers/{driver_id}/verify"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /c2c/v4/health
export def "c2c-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/c2c/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /c2c/v4/version
export def "c2c-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/c2c/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /device-associations/v2/health
# DEPRECATED
@deprecated
export def "device-associations-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device-associations/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /device-associations/v2/version
# DEPRECATED
@deprecated
export def "device-associations-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device-associations/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets geofences associated with a device
#
# GET /device-associations/v2/{trackingId}/geofences
# DEPRECATED
@deprecated
export def "device-associations-geofences get" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/device-associations/v2/{tracking_id}/geofences") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets event history
#
# GET /events/v3
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --event-source: string
  --event-type: string
  --rule-id: string
  --initial-state: oneof<nothing, bool>
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 1000)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "eventSource" $event_source "scalar") (serialize-qp "eventType" $event_type "scalar") (serialize-qp "ruleId" $rule_id "scalar") (serialize-qp "initialState" $initial_state "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/v3" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /events/v3/health
export def "events-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events/v3/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the event statuses
#
# GET /events/v3/statuses
export def "events-statuses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --event-source: string
  --event-type: string
  --tracking-id: string
  --rule-id: string
  --geofence-id: string
  --shipments: oneof<nothing, bool>
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 1000)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "eventSource" $event_source "scalar") (serialize-qp "eventType" $event_type "scalar") (serialize-qp "trackingId" $tracking_id "scalar") (serialize-qp "ruleId" $rule_id "scalar") (serialize-qp "geofenceId" $geofence_id "scalar") (serialize-qp "shipments" $shipments "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/v3/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the number of devices and shipments in each event state
#
# GET /events/v3/statuses/deviceCounts
export def "events-statuses-device-counts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --group-by: string@group-by-completer # default: ruleId
  --event-source: string
  --tracking-id: string
  --rule-id: string
  --geofence-id: string
  --shipments: oneof<nothing, bool>
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 1000)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "groupBy" $group_by "scalar") (serialize-qp "eventSource" $event_source "scalar") (serialize-qp "trackingId" $tracking_id "scalar") (serialize-qp "ruleId" $rule_id "scalar") (serialize-qp "geofenceId" $geofence_id "scalar") (serialize-qp "shipments" $shipments "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/v3/statuses/deviceCounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /events/v3/version
export def "events-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events/v3/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets event history for a device or a shipment
#
# GET /events/v3/{trackingId}
export def "events get" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --event-source: string
  --event-type: string
  --rule-id: string
  --initial-state: oneof<nothing, bool>
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 1000)
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "eventSource" $event_source "scalar") (serialize-qp "eventType" $event_type "scalar") (serialize-qp "ruleId" $rule_id "scalar") (serialize-qp "initialState" $initial_state "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/events/v3/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /geofence-associations/v2/health
# DEPRECATED
@deprecated
export def "geofence-associations-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geofence-associations/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /geofence-associations/v2/version
# DEPRECATED
@deprecated
export def "geofence-associations-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geofence-associations/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all devices associated with a geofence
#
# GET /geofence-associations/v2/{geofenceId}/devices
# DEPRECATED
@deprecated
export def "geofence-associations-devices get" [
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
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/geofence-associations/v2/{geofence_id}/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Disassociates a device and a geofence
#
# DELETE /geofence-associations/v2/{geofenceId}/{trackingId}
# DEPRECATED
@deprecated
export def "geofence-associations delete" [
  geofence_id: string
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id), tracking_id: (encode-path-segment $tracking_id)} | format pattern "/geofence-associations/v2/{geofence_id}/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associates a device with a geofence
#
# PUT /geofence-associations/v2/{geofenceId}/{trackingId}
# DEPRECATED
@deprecated
export def "geofence-associations update" [
  geofence_id: string
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id), tracking_id: (encode-path-segment $tracking_id)} | format pattern "/geofence-associations/v2/{geofence_id}/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes all geofences
#
# DELETE /geofences/v2
export def "geofences delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geofences/v2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all geofences
#
# GET /geofences/v2
export def "geofences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --floor: string # The floor of the indoor geofence (e.g. {id: DM_1234})
  --type: list<string> # Type of a geofence
  --bbox: list<float> # Limit search to geofences intersecting the given bounding box.
  --fields: list<string> # Field names to filter a result object.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "floor" $floor "deepObject") (serialize-qp "type" $type "multi") (serialize-qp "bbox" $bbox "multi") (serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/geofences/v2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a geofence
#
# POST /geofences/v2
# --definition shape: {center: record, floor?: record, radius: float}
export def "geofences create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --definition: record # An object that defines the area of a circular geofence — shape: {center: record, floor?: record, radius: float}
  --description: string # A description of the area that the geofence encloses and the purpose of the geofence.
  --name: string # A human-readable name of the geofence.
  --type: string@type-completer-1 # The geofence type.
]: any -> record<id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geofences/v2" $qp)
  let req_body = {"definition": $definition, "description": $description, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /geofences/v2/health
export def "geofences-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geofences/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks if a POI geofence training is possible with the given parameters
#
# POST /geofences/v2/trainingTest
# --wlan item shape: {band?: "2.4"|"3.65"|"5", mac: string, powrx: int, timestamp?: string}
export def "geofences-training-test create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --after: int # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The value must be within the past 24 hours from the current timestamp
  --before: int # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The value must not be greater than current timestamp
  --id: string # This is a unique ID associated with the device data in HERE Tracking. For physical devices the `trackingId` gets assigned to a device when the device is claimed by a user, and for virtual devices it is an external device ID along with the device project `appId`.
  --wlan: list # WLAN access points — item shape: {band?: "2.4"|"3.65"|"5", mac: string, powrx: int, timestamp?: string}
]: any -> record<metadata: record<coordinate: record<lat: float, lng: float>, timestamp: int, trackingId: string, usedWlanApCount: float>, reason: string, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geofences/v2/trainingTest")
  let req_body = {"after": $after, "before": $before, "id": $id, "wlan": $wlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service version
#
# GET /geofences/v2/version
export def "geofences-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geofences/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a geofence
#
# DELETE /geofences/v2/{geofenceId}
export def "geofences delete-by-geofenceId" [
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
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/geofences/v2/{geofence_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a single geofence
#
# GET /geofences/v2/{geofenceId}
export def "geofences get" [
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
  --accept: string@accept-completer # Response content type
  --fields: list<string> # Field names to filter a result object.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<geofence: any, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/geofences/v2/{geofence_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a single geofence
#
# PUT /geofences/v2/{geofenceId}
# --definition shape: {center: record, floor?: record, radius: float}
export def "geofences update" [
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
  --accept: string@accept-completer # Response content type
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --definition: record # An object that defines the area of a circular geofence — shape: {center: record, floor?: record, radius: float}
  --description: string # A description of the area that the geofence encloses and the purpose of the geofence.
  --name: string # A human-readable name of the geofence.
  --type: string@type-completer-1 # The geofence type.
]: any -> record<geofence: any, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/geofences/v2/{geofence_id}"))
  let req_body = {"definition": $definition, "description": $description, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Trains a POI geofence
#
# POST /geofences/v2/{geofenceId}/poiTraining
# --wlan item shape: {band?: "2.4"|"3.65"|"5", mac: string, powrx: int, timestamp?: string}
export def "geofences-poi-training create" [
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
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --after: int # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The value must be within the past 24 hours from the current timestamp
  --before: int # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The value must not be greater than current timestamp
  --id: string # This is a unique ID associated with the device data in HERE Tracking. For physical devices the `trackingId` gets assigned to a device when the device is claimed by a user, and for virtual devices it is an external device ID along with the device project `appId`.
  --wlan: list # WLAN access points — item shape: {band?: "2.4"|"3.65"|"5", mac: string, powrx: int, timestamp?: string}
]: any -> record<trainingStatus: record<metadata: record<coordinate: record, timestamp: int, trackingId: string, usedWlanApCount: float>, trained: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/geofences/v2/{geofence_id}/poiTraining"))
  let req_body = {"after": $after, "before": $before, "id": $id, "wlan": $wlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /labels/v4/health
export def "labels-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/labels/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /labels/v4/version
export def "labels-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/labels/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all labels of a resource type
#
# GET /labels/v4/{resourceType}
export def "labels list" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --labels: record # A filter containing label key-value pairs. (e.g. {group: group1, priority: high})
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --fields: list<string> # Field names to filter a result object.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<labels: record, resourceId: string, resourceType: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "labels" $labels "deepObject") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type)} | format pattern "/labels/v4/{resource_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all label keys of a resource type
#
# GET /labels/v4/{resourceType}/keys
export def "labels-keys get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<keys: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type)} | format pattern "/labels/v4/{resource_type}/keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all values of a label
#
# GET /labels/v4/{resourceType}/keys/{key}/values
export def "labels-keys-values get" [
  resource_type: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<values: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type), key: (encode-path-segment $key)} | format pattern "/labels/v4/{resource_type}/keys/{key}/values") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes all labels of a resource
#
# DELETE /labels/v4/{resourceType}/{resourceId}
export def "labels delete-by-resourceType-resourceId" [
  resource_type: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type), resource_id: (encode-path-segment $resource_id)} | format pattern "/labels/v4/{resource_type}/{resource_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all labels of a resource
#
# GET /labels/v4/{resourceType}/{resourceId}
export def "labels get" [
  resource_type: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --fields: list<string> # Field names to filter a result object.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<labels: record, resourceId: string, resourceType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type), resource_id: (encode-path-segment $resource_id)} | format pattern "/labels/v4/{resource_type}/{resource_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a set of labels for a resource
#
# PUT /labels/v4/{resourceType}/{resourceId}/batch
export def "labels-batch update" [
  resource_type: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  labels: record # A map of key-value pairs where the key is the label key and the value is an array of label values.
]: any -> record<labels: record, resourceId: string, resourceType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type), resource_id: (encode-path-segment $resource_id)} | format pattern "/labels/v4/{resource_type}/{resource_id}/batch") $qp)
  let req_body = {"labels": $labels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes all labels of a resource by a label key
#
# DELETE /labels/v4/{resourceType}/{resourceId}/{key}
export def "labels delete-by-resourceType-resourceId-key" [
  resource_type: string
  resource_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type), resource_id: (encode-path-segment $resource_id), key: (encode-path-segment $key)} | format pattern "/labels/v4/{resource_type}/{resource_id}/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a label of a resource
#
# DELETE /labels/v4/{resourceType}/{resourceId}/{key}/{value}
export def "labels delete-by-resourceType-resourceId-key-value" [
  resource_type: string
  resource_id: string
  key: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type), resource_id: (encode-path-segment $resource_id), key: (encode-path-segment $key), value: (encode-path-segment $value)} | format pattern "/labels/v4/{resource_type}/{resource_id}/{key}/{value}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a label for a resource
#
# PUT /labels/v4/{resourceType}/{resourceId}/{key}/{value}
export def "labels update" [
  resource_type: string
  resource_id: string
  key: string
  value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<labels: record, resourceId: string, resourceType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type), resource_id: (encode-path-segment $resource_id), key: (encode-path-segment $key), value: (encode-path-segment $value)} | format pattern "/labels/v4/{resource_type}/{resource_id}/{key}/{value}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a new data upload
#
# POST /largedata/v4
export def "largedata create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --description: string # Large data object description
  --name: string # Large data object name
]: any -> record<dataId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/largedata/v4")
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets metadata listing for all large data for a device
#
# GET /largedata/v4/devices/{trackingId}/metadata
export def "largedata-devices-metadata get" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<completedAt: string, createdAt: string, dataId: string, description: string, name: string, numberOfParts: int, size: int, status: string, trackingId: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/largedata/v4/devices/{tracking_id}/metadata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /largedata/v4/health
export def "largedata-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/largedata/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /largedata/v4/version
export def "largedata-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/largedata/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes large data
#
# DELETE /largedata/v4/{dataId}
export def "largedata delete" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_id: (encode-path-segment $data_id)} | format pattern "/largedata/v4/{data_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Completes data upload
#
# POST /largedata/v4/{dataId}
export def "largedata create-by-dataId" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --abort: oneof<nothing, bool> # default: false
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "abort" $abort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_id: (encode-path-segment $data_id)} | format pattern "/largedata/v4/{data_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets large data object
#
# GET /largedata/v4/{dataId}/data
export def "largedata-data get" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int
  --count: int
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_id: (encode-path-segment $data_id)} | format pattern "/largedata/v4/{data_id}/data") $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets metadata for a large data object
#
# GET /largedata/v4/{dataId}/metadata
export def "largedata-metadata get" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<completedAt: string, createdAt: string, dataId: string, description: string, name: string, numberOfParts: int, size: int, status: string, trackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({data_id: (encode-path-segment $data_id)} | format pattern "/largedata/v4/{data_id}/metadata"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets parts information listing for a large data object
#
# GET /largedata/v4/{dataId}/parts
export def "largedata-parts get" [
  data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<md5: string, partNumber: int, size: int, status: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_id: (encode-path-segment $data_id)} | format pattern "/largedata/v4/{data_id}/parts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Uploads a part of a large data
#
# PUT /largedata/v4/{dataId}/parts/{partNumber}
export def "largedata-parts update" [
  data_id: string
  part_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --md5: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "md5" $md5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({data_id: (encode-path-segment $data_id), part_number: (encode-path-segment $part_number)} | format pattern "/largedata/v4/{data_id}/parts/{part_number}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Deletes all locations
#
# DELETE /locations/v4
export def "locations delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locations/v4" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all locations
#
# GET /locations/v4
export def "locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --limit: int # The number of items to return per page (default: 100)
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --geofence-id: string # Filter the results by `geofenceId` (format: uuid)
  --name: string # Filter locations by name. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *office*)
  --street: string # Filter locations by street address. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *street*)
  --city: string # Filter locations by city. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *city*)
  --postal-code: string # Filter locations by postal code. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *100*)
  --state: string # Filter locations by state. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. New*)
  --country: string # Filter locations by country. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *land*)
  --location-id: string # Filter locations by locationId wildcard. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. LOC-*)
  --qp-sort: string # A paramater to specify field to sort by and order. The following format can be used: 'name:asc' sort by name in ascending order, 'steet:desc' sort by street in descending order. Allowed fields to sort by: locationId, name, street, city, postalCode, state, country. (e.g. name:asc)
  --external-location-id: string # Filter locations by external location id
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<address: record, description: string, externalLocationId: string, geofenceId: string, location: record, locationId: string, name: string>, limit: int, nextPageToken: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "geofenceId" $geofence_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "street" $street "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "postalCode" $postal_code "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "locationId" $location_id "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "externalLocationId" $external_location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locations/v4" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a location
#
# POST /locations/v4
# --address shape: {city?: string, country?: string, postalCode?: string, state?: string, street?: string}
# --location shape: {lat: float, lng: float}
export def "locations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --address: record # Location address. — shape: {city?: string, country?: string, postalCode?: string, state?: string, street?: string}
  --description: string # Description of the location.
  --external-location-id: string # External location id in external cloud
  --geofence-id: string # Optional geofence ID associated with the location. A geofence with the specified ID must exist. (format: uuid)
  --location: record # Location coordinates. — shape: {lat: float, lng: float}
  --name: string # Name of the location.
]: any -> record<locationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locations/v4" $qp)
  let req_body = {"address": $address, "description": $description, "externalLocationId": $external_location_id, "geofenceId": $geofence_id, "location": $location, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /locations/v4/health
export def "locations-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locations/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /locations/v4/version
export def "locations-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locations/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a location
#
# DELETE /locations/v4/{locationId}
export def "locations delete-by-locationId" [
  location_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/locations/v4/{location_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a location details
#
# GET /locations/v4/{locationId}
export def "locations get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<city: string, country: string, postalCode: string, state: string, street: string>, description: string, externalLocationId: string, geofenceId: string, location: record<lat: float, lng: float>, locationId: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/locations/v4/{location_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a location details
#
# PUT /locations/v4/{locationId}
# --address shape: {city?: string, country?: string, postalCode?: string, state?: string, street?: string}
# --location shape: {lat: float, lng: float}
export def "locations update" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # Location address. — shape: {city?: string, country?: string, postalCode?: string, state?: string, street?: string}
  --description: string # Description of the location.
  --external-location-id: string # External location id in external cloud
  --geofence-id: string # Optional geofence ID associated with the location. A geofence with the specified ID must exist. (format: uuid)
  --location: record # Location coordinates. — shape: {lat: float, lng: float}
  --name: string # Name of the location.
]: any -> record<address: record<city: string, country: string, postalCode: string, state: string, street: string>, description: string, externalLocationId: string, geofenceId: string, location: record<lat: float, lng: float>, locationId: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/locations/v4/{location_id}"))
  let req_body = {"address": $address, "description": $description, "externalLocationId": $external_location_id, "geofenceId": $geofence_id, "location": $location, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a batch of metadata of multiple devices or shipments
#
# POST /metadata/v2/devices/batch
export def "metadata-devices-batch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: list
]: any -> record<count: int, pageToken: string, data: table<data: record, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata/v2/devices/batch" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes all metadata of a device or a shipment
#
# DELETE /metadata/v2/devices/{trackingId}
export def "metadata-devices delete" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/metadata/v2/devices/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets metadata of a device or a shipment
#
# GET /metadata/v2/devices/{trackingId}
export def "metadata-devices get" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<data: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/metadata/v2/devices/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates or updates metadata of a device or a shipment
#
# PUT /metadata/v2/devices/{trackingId}
export def "metadata-devices update" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: record
]: any -> record<data: record, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/metadata/v2/devices/{tracking_id}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a batch of metadata of multiple geofences
#
# POST /metadata/v2/geofences/batch
export def "metadata-geofences-batch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: list
]: any -> record<count: int, pageToken: string, data: table<data: record, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata/v2/geofences/batch" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes all metadata of a geofence
#
# DELETE /metadata/v2/geofences/{geofenceId}
export def "metadata-geofences delete" [
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
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/metadata/v2/geofences/{geofence_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets metadata of a geofence
#
# GET /metadata/v2/geofences/{geofenceId}
export def "metadata-geofences get" [
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
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<data: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/metadata/v2/geofences/{geofence_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates or updates metadata of a geofence
#
# PUT /metadata/v2/geofences/{geofenceId}
export def "metadata-geofences update" [
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
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: record
]: any -> record<data: record, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({geofence_id: (encode-path-segment $geofence_id)} | format pattern "/metadata/v2/geofences/{geofence_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /metadata/v2/health
export def "metadata-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a batch of metadata for multiple sensor rules
#
# POST /metadata/v2/sensorRules/batch
export def "metadata-sensor-rules-batch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: list
]: any -> record<count: int, pageToken: string, data: table<data: record, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metadata/v2/sensorRules/batch" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes all metadata of a sensor rule
#
# DELETE /metadata/v2/sensorRules/{sensorRuleId}
export def "metadata-sensor-rules delete" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/metadata/v2/sensorRules/{sensor_rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets metadata of a sensor rule
#
# GET /metadata/v2/sensorRules/{sensorRuleId}
export def "metadata-sensor-rules get" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<data: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/metadata/v2/sensorRules/{sensor_rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates or updates metadata of a sensor rule
#
# PUT /metadata/v2/sensorRules/{sensorRuleId}
export def "metadata-sensor-rules update" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: record
]: any -> record<data: record, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/metadata/v2/sensorRules/{sensor_rule_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service version
#
# GET /metadata/v2/version
export def "metadata-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /notifications/v3/health
export def "notifications-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/v3/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Unregisters from notifications
#
# DELETE /notifications/v3/registration/{channelId}
export def "notifications-registration delete" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/notifications/v3/registration/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a single notification channel information
#
# GET /notifications/v3/registration/{channelId}
export def "notifications-registration get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<registration: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/notifications/v3/registration/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a notification channel
#
# PUT /notifications/v3/registration/{channelId}
export def "notifications-registration update" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  channel_type: string@channel-type-completer # The type of notification channel.
  --event-source: string@event-source-completer # The event source rule type.
  --event-type: string@event-type-completer # Type of the event. An event is created every time an associated rule or geofence is triggered by a device ingestion. The event type depends on the data the device sends. Sensors that report numerical data (such as battery, humidity, pressure and temperature sensors), generate an event when the reported sensor reading of the device goes in or out of range, which is configured in the rule. This produces events of BELOW_RANGE, IN_RANGE and ABOVE_RANGE types. Sensors that report boolean data (such as attach and tamper sensors), generate events when the device transitions from one state to another, either from `false` to `true` or vice versa. This produces events of FALSE_TO_TRUE and TRUE_TO_FALSE types. The same event types are also generated by the online rule when the device state changes from `offline` (when the device has stopped ingesting data) to `online` (when the device data ingestion has resumed) or vice versa. The acceleration sensor generates events whenever the reported sensor reading crosses the acceleration threshold (for example, when the device was dropped). This produces events of the type EVENT. Such events are stateless. Events of INSIDE_GEOFENCE and OUTSIDE_GEOFENCE types are generated when the device enters or exits a geofence associated with the device. Events of DWELLING_STARTED type are generated when the device has stayed inside an associated geofence for longer than the threshold duration. DWELLING_ENDED type events are generated when dwelling of the device has ended. Events of DETENTION_STARTED type are generated when the device has been stationary for longer than the threshold duration, regardless whether the device is inside or outside of any geofence. DETENTION_ENDED type events will be generated when the device starts moving again. Events of UNUTILIZED type are generated when the device has been stationary for longer than the threshold duration. UTILIZED type events are generated when the device starts moving again after having been stationary. Events of OVERSTOCK, NORMAL_VOLUME and UNDERSTOCK types are generated when the number of assets inside a geofence crosses the `minVolume` and `maxVolume` thresholds of an associated stock rule. Events of SHIPMENT_EARLY, SHIPMENT_ON_TIME and SHIPMENT_DELAYED types are generated when a shipment is too early, on time or delayed.
  --initial-state: oneof<nothing, bool> # Events with the `initialState` property set as `true` are generated when the rule is evaluated for the first time. It indicates the fact that this is the initial evaluation state, which would serve as a starting point for the subsequent rule evaluations. The rest of the rule events would represent a transition of a device or a shipment or a geofence from one state to another and their `initialState` property will be set to `false`.
  --rule-id: string # Must be a valid UUIDv4. (format: uuid)
  --url: string # A webhook URL that will receive notifications POST requests.
]: any -> record<registration: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/notifications/v3/registration/{channel_id}"))
  let req_body = {"channelType": $channel_type, "eventSource": $event_source, "eventType": $event_type, "initialState": $initial_state, "ruleId": $rule_id, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Unregisters from all notifications
#
# DELETE /notifications/v3/registrations
export def "notifications-registrations delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/v3/registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all registered notification channels
#
# GET /notifications/v3/registrations
export def "notifications-registrations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --project-id: string
  --channel-type: list<string> # Filter result by channelType. Example: `channelType[]=webhook`, `channelType[]=browserPull,email`
  --user-id: string # User ID. Can be used by the project admin to filter email and browser pull notification channels by subscriber.
  --email-bounce: oneof<nothing, bool> # Filters by `emailBounce` property. When set to `true`, returns the email channels which are not active anymore due to email bounce. When set to `false`, returns all the channels which are active (and not only email channels).
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "projectId" $project_id "scalar") (serialize-qp "channelType" $channel_type "multi") (serialize-qp "userId" $user_id "scalar") (serialize-qp "emailBounce" $email_bounce "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/v3/registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Registers for notifications
#
# POST /notifications/v3/registrations
export def "notifications-registrations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --user-id: string # User Id.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  channel_type: string@channel-type-completer # The type of notification channel.
  --event-source: string@event-source-completer # The event source rule type.
  --event-type: string@event-type-completer # Type of the event. An event is created every time an associated rule or geofence is triggered by a device ingestion. The event type depends on the data the device sends. Sensors that report numerical data (such as battery, humidity, pressure and temperature sensors), generate an event when the reported sensor reading of the device goes in or out of range, which is configured in the rule. This produces events of BELOW_RANGE, IN_RANGE and ABOVE_RANGE types. Sensors that report boolean data (such as attach and tamper sensors), generate events when the device transitions from one state to another, either from `false` to `true` or vice versa. This produces events of FALSE_TO_TRUE and TRUE_TO_FALSE types. The same event types are also generated by the online rule when the device state changes from `offline` (when the device has stopped ingesting data) to `online` (when the device data ingestion has resumed) or vice versa. The acceleration sensor generates events whenever the reported sensor reading crosses the acceleration threshold (for example, when the device was dropped). This produces events of the type EVENT. Such events are stateless. Events of INSIDE_GEOFENCE and OUTSIDE_GEOFENCE types are generated when the device enters or exits a geofence associated with the device. Events of DWELLING_STARTED type are generated when the device has stayed inside an associated geofence for longer than the threshold duration. DWELLING_ENDED type events are generated when dwelling of the device has ended. Events of DETENTION_STARTED type are generated when the device has been stationary for longer than the threshold duration, regardless whether the device is inside or outside of any geofence. DETENTION_ENDED type events will be generated when the device starts moving again. Events of UNUTILIZED type are generated when the device has been stationary for longer than the threshold duration. UTILIZED type events are generated when the device starts moving again after having been stationary. Events of OVERSTOCK, NORMAL_VOLUME and UNDERSTOCK types are generated when the number of assets inside a geofence crosses the `minVolume` and `maxVolume` thresholds of an associated stock rule. Events of SHIPMENT_EARLY, SHIPMENT_ON_TIME and SHIPMENT_DELAYED types are generated when a shipment is too early, on time or delayed.
  --initial-state: oneof<nothing, bool> # Events with the `initialState` property set as `true` are generated when the rule is evaluated for the first time. It indicates the fact that this is the initial evaluation state, which would serve as a starting point for the subsequent rule evaluations. The rest of the rule events would represent a transition of a device or a shipment or a geofence from one state to another and their `initialState` property will be set to `false`.
  --rule-id: string # Must be a valid UUIDv4. (format: uuid)
  --url: string # A webhook URL that will receive notifications POST requests.
]: any -> record<registration: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "userId" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications/v3/registrations" $qp)
  let req_body = {"channelType": $channel_type, "eventSource": $event_source, "eventType": $event_type, "initialState": $initial_state, "ruleId": $rule_id, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service version
#
# GET /notifications/v3/version
export def "notifications-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/v3/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deactivates a device.
#
# DELETE /registry/v2/devices/{deviceOrExternalId}
export def "registry-devices delete" [
  device_or_external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_or_external_id: (encode-path-segment $device_or_external_id)} | format pattern "/registry/v2/devices/{device_or_external_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the trackingId for a device
#
# GET /registry/v2/devices/{deviceOrExternalId}
export def "registry-devices get-by-deviceOrExternalId" [
  device_or_external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<trackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_or_external_id: (encode-path-segment $device_or_external_id)} | format pattern "/registry/v2/devices/{device_or_external_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Claims a device
#
# PUT /registry/v2/devices/{deviceOrExternalId}
export def "registry-devices update" [
  device_or_external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --owner-app-id: string # (Deprecated) Application identifier which specifies device owner's application to which the device is associated with.
]: any -> record<trackingId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({device_or_external_id: (encode-path-segment $device_or_external_id)} | format pattern "/registry/v2/devices/{device_or_external_id}") $qp)
  let req_body = {"ownerAppId": $owner_app_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /registry/v2/health
export def "registry-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registry/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a list user projects along with the license information
#
# GET /registry/v2/licenses
export def "registry-licenses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # default: 0
  --end-index: int # default: 100
  --project-ids: string
  --project-types: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<end: int, licenses: table<appId: string, expired: bool, expiryDate: string, features: list, projectDescription: string, projectHrn: string, projectId: string, projectName: string, quota: record, realm: string, type: string>, start: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startIndex" $start_index "scalar") (serialize-qp "endIndex" $end_index "scalar") (serialize-qp "projectIds" $project_ids "scalar") (serialize-qp "projectTypes" $project_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registry/v2/licenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /registry/v2/version
export def "registry-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registry/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all the devices provisioned by a user
#
# GET /registry/v2/{appId}/devices
export def "registry-devices get-by-appId" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: table<appId: string, deviceId: string, externalId: string, timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/registry/v2/{app_id}/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates licenses for multiple devices
#
# POST /registry/v2/{appId}/devices
# --devices item shape: {id?: string}
export def "registry-devices create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoclaim: oneof<nothing, bool> # If set to `true`, the licenses are created and devices are immediately claimed by the same user. Supported only with `deviceId` array in body, and not with the `count` parameter. (default: false)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --count: int # Number of device credentials requested
  --devices: list # item shape: {id?: string}
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoclaim" $autoclaim "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/registry/v2/{app_id}/devices") $qp)
  let req_body = {"count": $count, "devices": $devices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a number of device licenses provisioned by a user
#
# GET /registry/v2/{appId}/licenseCount
export def "registry-license-count get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: float, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/registry/v2/{app_id}/licenseCount"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a license for a single physical device
#
# POST /registry/v2/{appId}/one-device
export def "registry-one-device create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoclaim: oneof<nothing, bool> # If set to `true`, the device license is created and the device is immediately claimed by the same user. (default: false)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<deviceId: string, deviceSecret: string, trackingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoclaim" $autoclaim "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/registry/v2/{app_id}/one-device") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the multiple device license request job results
#
# GET /registry/v2/{jobId}/results
export def "registry-results get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: table<deviceId: string, deviceSecret: string, externalId: string, trackingId: string>, errors: table<error: record, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/registry/v2/{job_id}/results") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the multiple device license request job status
#
# GET /registry/v2/{jobId}/status
export def "registry-status get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<percent: float, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/registry/v2/{job_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Unclaims a device
#
# DELETE /registry/v2/{trackingId}
export def "registry delete" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/registry/v2/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the deviceId
#
# GET /registry/v2/{trackingId}
export def "registry get" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<deviceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/registry/v2/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all resources of a resource type
#
# POST /registry/v4/resources/{resourceType}/find
export def "registry-resources-find create" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  filters: list
]: any -> record<count: int, items: table<resourceId: string>, limit: int, nextPageToken: string, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_type: (encode-path-segment $resource_type)} | format pattern "/registry/v4/resources/{resource_type}/find") $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Starts report creation
#
# POST /reports/v4
export def "reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  end: string # End date of the report period. The end date should be greater than the start date. (format: date-time)
  rule_id: string # Rule ID of a dwelling or detention rule. (format: uuid)
  start: string # Start date and time of the report period. When getting reports per interval, this timestamp defines the start of the interval day, week or month. For example, to make the report week start on Monday midnight 1st March 2021 in timezone UTC+1:00, set the `start` parameter to be `2021-02-28T23:00:00.000Z` (GMT). Now when getting interval reports, the first week would contain data between `2021-02-28T23:00:00.000Z` and `2021-03-07T23:00:00.000Z` (GMT). (format: date-time)
]: any -> record<reportId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/v4" $qp)
  let req_body = {"end": $end, "ruleId": $rule_id, "start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /reports/v4/health
export def "reports-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /reports/v4/version
export def "reports-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets reports
#
# GET /reports/v4/{reportId}
export def "reports get" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --measure: string@measure-completer # Defines the report metric to be calculated. The metrics are always calculated over a time period, either over each interval specified by the `interval` parameter (for example, over a week) or over the whole time period of the report. * `duration`: duration of the event * _"The asset dwelled for 45 hours during week 2. It was in detention for 4 hours."_ * `occurrence`: total number of the event occurrences * _"During week 3, the asset was in detention 2 times. During the past month it had 7 individual dwelling periods."_ * `day`: the number of days the event lasted * _"The asset was utilized for 3 days during week 4."_ * `asset`: the number of assets that generated the event * _"On Monday 5 assets were in detention. On Tuesday 16 assets were in detention."_
  --interval: string@interval-completer # Defines an interval, which can be a day, a week or a month, that will be used to group the report results. When the `interval` parameter is provided, the response will be an array of `timestamp`-`value` pairs where the `timestamp` defines the beginning of the interval and the `value` is the specified report metric's value calculated over the interval time.
  --tracking-id: string # Tracking ID. Provide a tracking ID to get a report on a specific asset. > Note that in the report context an asset is a device. For example, to get a report on how many times the specified asset was in detention during each week, create a request specifying the following: * `reportId`: ID of a report created for a detention rule * `trackingId`: tracking ID * `measure`: 'occurrence' * `interval`: 'week'
  --geofence-id: string # ID of the geofence. One can provide a geofence ID in case one wants to get reports on a specific geofence. This parameter can only be used with reports created for a dwelling rule type. For example, to get a report on assets' average dwelling time in the specified geofence during each week, create a request specifying the following: * `reportId`: ID of a report created for a dwelling rule * `measure`: 'duration' * `groupBy`: 'asset' * `interval`: 'week' * `method`: 'average' * `geofenceId`: geofence ID (format: uuid)
  --group-by: string@group-by-completer-1 # Defines whether the report metrics, such as cumulative or average, are calculated per asset or per geofence. The parameter can have a value 'geofence' only with reports created for a dwelling rule. To get a report on how many times on average assets were in detention during each time interval, create a request specifying the following: * `reportId`: ID of a report created for a detention rule * `groupBy`: 'asset' * `method`: 'average' * `measure`: 'occurrence' To get a report on how long all assets dwelled inside each geofence during the report period, create a request specifying the following: * `reportId`: ID of a report created for a dwelling rule * `groupBy`: 'geofence' * `measure`: 'duration' To get a report on how long each asset dwelled (inside any geofence) during the report period, create a request specifying the following: * `reportId`: ID of a report created for a dwelling rule * `groupBy`: 'asset' * `measure`: 'duration'
  --method: string@method-completer # Defines the calculation method. The parameter `method` can only be provided along with `interval`. The parameter value can be `percentage` only when `measure` is 'asset'. For example, to get a report on percentage of all assets that were in use during each week, create a request specifying the following: * `reportId`: ID of a report created for a utilization rule * `interval`: 'week' * `method`: 'percentage' * `measure`: 'asset' When `method` is set to 'cumulative' or 'average' and `measure` is set to 'duration' or 'occurrence', the `groupBy` parameter needs to be provided also. For example, to get a report on how long all assets dwelled in total in the specified geofence during each week, create a request specifying the following: * `reportId`: ID of a report created for a dwelling rule * `geofenceId`: ID of a geofence * `interval`: 'week' * `method`: 'cumulative' * `measure`: 'duration' * `groupBy`: 'asset' When `method` is set to 'cumulative' or 'average' and `measure` is set to 'day', the `groupBy` parameter is automatically set to 'asset'. For example, to get a report on how many days on average assets were in use during each month, create a request specifying the following: * `reportId`: ID of a report created for a utilization rule * `interval`: 'month' * `method`: 'average' * `measure`: 'day' * `groupBy`: 'asset'
  --qp-sort: string # Defines how the items are sorted. * If `interval` is provided, the default is `sort`=`timestamp:asc` * If `interval` is not provided, the default is `sort`=`value:desc` (e.g. timestamp:asc)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: list<any>, limit: int, nextPageToken: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "measure" $measure "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "trackingId" $tracking_id "scalar") (serialize-qp "geofenceId" $geofence_id "scalar") (serialize-qp "groupBy" $group_by "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/v4/{report_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes all rules
#
# DELETE /rules/v4
export def "rules delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rules/v4" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all rules
#
# GET /rules/v4
export def "rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<rule: any, ruleId: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rules/v4" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a rule
#
# POST /rules/v4
# --threshold shape: {durationS: int}
export def "rules create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --description: string # Rule description
  --name: string # Rule name
  --threshold: record # Utilization event is triggered when the asset starts moving indicating that the asset is utilized, and also when the asset stops moving and has been stationary for longer than the threshold duration indicating that the asset is unutilized. — shape: {durationS: int}
  --type: string@type-completer-2 # The rule type
  --geofence-id: string # Geofence ID (format: uuid)
]: any -> record<ruleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rules/v4" $qp)
  let req_body = {"description": $description, "name": $name, "threshold": $threshold, "type": $type, "geofenceId": $geofence_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /rules/v4/health
export def "rules-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /rules/v4/version
export def "rules-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rules/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a rule
#
# DELETE /rules/v4/{ruleId}
export def "rules delete-by-ruleId" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/v4/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a single rule
#
# GET /rules/v4/{ruleId}
export def "rules get" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<rule: any, ruleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/v4/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a single rule
#
# PUT /rules/v4/{ruleId}
# --threshold shape: {durationS: int}
export def "rules update" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --description: string # Rule description
  --name: string # Rule name
  --threshold: record # Utilization event is triggered when the asset starts moving indicating that the asset is utilized, and also when the asset stops moving and has been stationary for longer than the threshold duration indicating that the asset is unutilized. — shape: {durationS: int}
  --type: string@type-completer-2 # The rule type
  --geofence-id: string # Geofence ID (format: uuid)
]: any -> record<rule: any, ruleId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/rules/v4/{rule_id}"))
  let req_body = {"description": $description, "name": $name, "threshold": $threshold, "type": $type, "geofenceId": $geofence_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes all sensor rules
#
# DELETE /sensors/v3
export def "sensors delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sensors/v3" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all sensor rules
#
# GET /sensors/v3
export def "sensors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sensors/v3" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a sensor rule
#
# POST /sensors/v3
# --range shape: {begin: float, end: float}
# --threshold shape: {value: float}
export def "sensors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --description: string # Sensor rule description
  --name: string # Sensor rule name
  --range: record # shape: {begin: float, end: float}
  --type: string@type-completer-3 # The sensor type.
  --threshold: record # shape: {value: float}
]: any -> record<id: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sensors/v3" $qp)
  let req_body = {"description": $description, "name": $name, "range": $range, "type": $type, "threshold": $threshold} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /sensors/v3/health
export def "sensors-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sensors/v3/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /sensors/v3/version
export def "sensors-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sensors/v3/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a sensor rule
#
# DELETE /sensors/v3/{sensorRuleId}
export def "sensors delete-by-sensorRuleId" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/sensors/v3/{sensor_rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a single sensor rule
#
# GET /sensors/v3/{sensorRuleId}
export def "sensors get" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<description: string, id: string, name: string, range: record<begin: float, end: float>, threshold: record<value: float>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/sensors/v3/{sensor_rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a single sensor rule
#
# PUT /sensors/v3/{sensorRuleId}
# --range shape: {begin: float, end: float}
# --threshold shape: {value: float}
export def "sensors update" [
  sensor_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --description: string # Sensor rule description
  --name: string # Sensor rule name
  --range: record # shape: {begin: float, end: float}
  --type: string@type-completer-3 # The sensor type.
  --threshold: record # shape: {value: float}
]: any -> record<message: string, description: string, id: string, name: string, range: record<begin: float, end: float>, threshold: record<value: float>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sensor_rule_id: (encode-path-segment $sensor_rule_id)} | format pattern "/sensors/v3/{sensor_rule_id}"))
  let req_body = {"description": $description, "name": $name, "range": $range, "type": $type, "threshold": $threshold} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a batch of device shadows
#
# POST /shadows/v2/batch
export def "shadows-batch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --body: list
]: any -> table<appId: string, body: record<desired: record, reported: record>, externalId: string, statusCode: int, trackingId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shadows/v2/batch" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /shadows/v2/health
export def "shadows-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shadows/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /shadows/v2/version
export def "shadows-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shadows/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Clears a device shadow
#
# DELETE /shadows/v2/{trackingId}
export def "shadows delete" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --desired: oneof<nothing, bool> # If `true`, all the values of the `desired` shadow will be cleared (default: true)
  --reported: oneof<nothing, bool> # If `true`, all the values of the `reported` shadow will be cleared (default: true)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "desired" $desired "scalar") (serialize-qp "reported" $reported "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/shadows/v2/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a device shadow
#
# GET /shadows/v2/{trackingId}
export def "shadows get-by-trackingId" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<desired: record<payload: record, system: record<detectOutliers: bool, disableTracking: record, lastModifiedGeofenceTimestamp: int, rate: record, sensorAlarmConfig: record, sensorLoggingConfigurations: list, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list, wlanConnectivityEnabled: bool>, timestamp: int>, reported: record<payload: record, position: record<accuracy: float, alt: float, altaccuracy: float, confidence: int, floor: record, heading: int, lat: float, lng: float, satellitecount: int, speed: int, timestamp: int, type: string, wlancount: int>, system: record<client: record, computed: record, iccid: string, imsi: string, mode: string, phoneNumber: string, reportedSensorData: record, stateVersion: int>, timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/shadows/v2/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a device shadow
#
# PUT /shadows/v2/{trackingId}
# --desired shape: {payload?: record, system?: record}
export def "shadows update" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --content-length: float # The size of the shadow in bytes. The size is validated against the maximum limit of 1000 bytes.
  desired: record # The desired shadow of the device. — shape: {payload?: record, system?: record}
]: any -> record<desired: record<payload: record, system: record<detectOutliers: bool, disableTracking: record, lastModifiedGeofenceTimestamp: int, rate: record, sensorAlarmConfig: record, sensorLoggingConfigurations: list, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list, wlanConnectivityEnabled: bool>, timestamp: int>, reported: record<payload: record, position: record<accuracy: float, alt: float, altaccuracy: float, confidence: int, floor: record, heading: int, lat: float, lng: float, satellitecount: int, speed: int, timestamp: int, type: string, wlancount: int>, system: record<client: record, computed: record, iccid: string, imsi: string, mode: string, phoneNumber: string, reportedSensorData: record, stateVersion: int>, timestamp: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/shadows/v2/{tracking_id}") $qp)
  let req_body = {"desired": $desired} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "content-length": $content_length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets reported or desired state object of a device
#
# GET /shadows/v2/{trackingId}/{state}
export def "shadows get-by-trackingId-state" [
  tracking_id: string
  state: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), state: (encode-path-segment $state)} | format pattern "/shadows/v2/{tracking_id}/{state}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a value of a shadow property
#
# GET /shadows/v2/{trackingId}/{state}/{selector}
export def "shadows get-by-trackingId-state-selector" [
  tracking_id: string
  state: string
  selector: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id), state: (encode-path-segment $state), selector: (encode-path-segment $selector)} | format pattern "/shadows/v2/{tracking_id}/{state}/{selector}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all shadows
#
# GET /shadows/v4
export def "shadows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --after: string # If provided returns the shadows for which `reported.timestamp` is greater than given `after` parameter. (format: date-time)
  --qp-sort: string # Defines how the items are sorted. The default sort is `sort=trackingId:asc` (e.g. reported.timestamp:desc)
  --bbox: list<float> # Limit search to shadows, whose position intersects the given bounding box. The `bbox` array consist of latitude and longitude of Northwest and Southeast corners. (e.g. 61.494750,23.775189,61.494611,23.774758)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<appId: string, externalId: string, shadow: record, trackingId: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "bbox" $bbox "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/shadows/v4" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Starts shipment report generation
#
# POST /shipment-reports/v4
export def "shipment-reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --ended-after: string # Include successfully completed shipments of each shipment plan into the shipment report generation which ended after the provided date. (format: date-time)
  --ended-before: string # Include successfully completed shipments of each shipment plan into the shipment report generation which ended before the provided date. (format: date-time)
  --shipment-plan-ids: list<string> # Provide array of shipment plan ids to include into the shipment report. If just a single shipment plan id is given, then the shipment report will include only metrics and shipments for the given shipment plan. If none is given, then the shipment report will include all shipment plans.
  --started-after: string # Include successfully completed shipments of each shipment plan into the shipment report generation which started after the provided date. (format: date-time)
  --started-before: string # Include successfully completed shipments of each shipment plan into the shipment report generation which started before the provided date. (format: date-time)
]: any -> record<shipmentReportId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipment-reports/v4" $qp)
  let req_body = {"endedAfter": $ended_after, "endedBefore": $ended_before, "shipmentPlanIds": $shipment_plan_ids, "startedAfter": $started_after, "startedBefore": $started_before} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /shipment-reports/v4/health
export def "shipment-reports-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipment-reports/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /shipment-reports/v4/version
export def "shipment-reports-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipment-reports/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets status of generation of the shipment report
#
# GET /shipment-reports/v4/{shipmentReportId}/status
export def "shipment-reports-status get" [
  shipment_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<code: int, details: any, error: string, id: string, message: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_report_id: (encode-path-segment $shipment_report_id)} | format pattern "/shipment-reports/v4/{shipment_report_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets summary of the shipment report
#
# GET /shipment-reports/v4/{shipmentReportId}/summary
export def "shipment-reports-summary get" [
  shipment_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completedAt: string, createdAt: string, totalLocationCount: int, totalSegmentPlanCount: int, totalSegmentsCount: int, totalShipmentPlanCount: int, totalShipmentsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_report_id: (encode-path-segment $shipment_report_id)} | format pattern "/shipment-reports/v4/{shipment_report_id}/summary"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets metrics of the shipment report
#
# GET /shipment-reports/v4/{shipmentReportId}/{metric}
export def "shipment-reports get" [
  shipment_report_id: string
  metric: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --qp-sort: string # The response items can be sorted to ascending or descending order by their statistics properties. E.g for `shipmentPlanPunctualityAtOrigin` it could be `avg:desc`. Default is ascending sort order.
]: nothing -> record<count: int, items: table<ids: record, statistics: record, statisticsCount: int>, limit: int, nextPageToken: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shipment_report_id: (encode-path-segment $shipment_report_id), metric: (encode-path-segment $metric)} | format pattern "/shipment-reports/v4/{shipment_report_id}/{metric}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes all shipments
#
# DELETE /shipments/v4
export def "shipments delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipments/v4" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all shipments
#
# GET /shipments/v4
export def "shipments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --status: string@status-completer # Filter the results by shipment status
  --started-before: string # Return only shipments that started before the specified timestamp (format: date-time)
  --started-after: string # Return only shipments that started after the specified timestamp (format: date-time)
  --ended-before: string # Return only shipments that ended before the specified timestamp (format: date-time)
  --ended-after: string # Return only shipments that ended after the specified timestamp (format: date-time)
  --name: string # Filter shipments by name. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *portugal*)
  --shipment-plan-id: string # Return only shipments that have been instantiated from the specified `shipmentPlanId`
  --shipment-id: string # Filter shipments by `shipmentId` Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character.
  --is-sub-shipment: oneof<nothing, bool> # Returns only shipments marked as subShipments
  --created-before: string # Return only shipments that have been created before specified timestamp (format: date-time)
  --created-after: string # Return only shipments that have been created after specified timestamp (format: date-time)
  --qp-sort: string # A paramater to specify field to sort by and order. The following format can be used: 'name:asc' sort by name in ascending order, 'shipmentId:desc' sort by shipmentId in descending order. Allowed fields to sort by: shipmentId, name, status, startedAt, createdAt, endedAt, providedEtd, providedEta, calculatedEtd. (e.g. name:asc)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<autoStart: bool, calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, endedAt: string, name: string, providedEta: string, providedEtd: string, ruleIds: list, segments: list, shipmentId: string, shipmentPlanId: string, startedAt: string, status: string, subShipment: bool>, limit: int, nextPageToken: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "startedBefore" $started_before "scalar") (serialize-qp "startedAfter" $started_after "scalar") (serialize-qp "endedBefore" $ended_before "scalar") (serialize-qp "endedAfter" $ended_after "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "shipmentPlanId" $shipment_plan_id "scalar") (serialize-qp "shipmentId" $shipment_id "scalar") (serialize-qp "isSubShipment" $is_sub_shipment "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipments/v4" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a shipment
#
# POST /shipments/v4
# --segments item shape: {description?: string, destination: string, name?: string, origin: string, providedEta?: string, providedEtd?: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
export def "shipments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --auto-start: oneof<nothing, bool> # A boolean parameter defining whether the shipment starts upon exiting the first origin location. (default: true)
  --description: string # Description of the shipment
  --name: string # Name of the shipment
  --provided-eta: string # ETA for the shipment (format: date-time)
  --provided-etd: string # ETD for the shipment (format: date-time)
  --rule-ids: list<string> # Array of `ruleId`s to associate with the shipment
  --segments: list # Array of objects each defining the origin and destination of the segment — item shape: {description?: string, destination: string, name?: string, origin: string, providedEta?: string, providedEtd?: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
  --sub-shipment: oneof<nothing, bool> # Flag telling if shipment is a subShipment. (default: false)
  --shipment-departure: string # ETD of the shipment instance. Used to calculate the ETDs and ETAs of all the segments based on the segment durations defined in the plan. (format: date-time)
  --shipment-plan-id: string # Shipment plan ID
]: any -> record<shipmentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipments/v4" $qp)
  let req_body = {"autoStart": $auto_start, "description": $description, "name": $name, "providedEta": $provided_eta, "providedEtd": $provided_etd, "ruleIds": $rule_ids, "segments": $segments, "subShipment": $sub_shipment, "shipmentDeparture": $shipment_departure, "shipmentPlanId": $shipment_plan_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /shipments/v4/health
export def "shipments-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipments/v4/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes all shipment plans
#
# DELETE /shipments/v4/plans
export def "shipments-plans delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --x-confirm: string@x-confirm-completer # A safety measure that prevents one from accidentally deleting data. To confirm that all entries should be deleted, set the value to `true`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipments/v4/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "x-confirm": $x_confirm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all shipment plans
#
# GET /shipments/v4/plans
export def "shipments-plans get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --name: string # Filter shipments by name. Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character. (e.g. *portugal*)
  --shipment-plan-id: string # Return only shipment plans that have been instantiated from the specified `shipmentPlanId` Matching is case-insensitive. The following wildcards can be used: '*' matches any number of any characters, '?' matches any single character.
  --location-id: string # Return only shipments that have been instantiated from the specified `locationId`
  --created-before: string # Return only shipments that have been created before specified timestamp (format: date-time)
  --created-after: string # Return only shipments that have been created after specified timestamp (format: date-time)
  --is-sub-shipment: oneof<nothing, bool> # Returns only shipments marked as subShipments
  --qp-sort: string # A paramater to specify field to sort by and order. Allowed fields to sort by: shipmentPlanId, name, createdAt (e.g. name:asc)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, items: table<autoStart: bool, createdAt: string, description: string, name: string, ruleIds: list, segments: list, shipmentPlanId: string, subShipment: bool>, limit: int, nextPageToken: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "shipmentPlanId" $shipment_plan_id "scalar") (serialize-qp "locationId" $location_id "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "isSubShipment" $is_sub_shipment "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipments/v4/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a shipment plan
#
# POST /shipments/v4/plans
# --segments item shape: {description?: string, destination: string, durationS?: int, name?: string, origin: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
# --options shape: {calculateDurationsFrom?: "actuals"|"providedEstimate"|"calculatedEstimate", copyTrackingIds?: bool}
export def "shipments-plans create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --auto-start: oneof<nothing, bool> # A boolean parameter defining whether the shipment starts upon exiting the first origin location. (default: true)
  --description: string # Description of the shipment
  --name: string # Name of the shipment
  --rule-ids: list<string> # Array of `ruleId`s to associate with the shipment
  --segments: list # Array of objects each defining the origin and destination of the segment — item shape: {description?: string, destination: string, durationS?: int, name?: string, origin: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
  --sub-shipment: oneof<nothing, bool> # Flag telling if shipment is a subShipment. (default: false)
  --options: record # Optional parameters for plan creation — shape: {calculateDurationsFrom?: "actuals"|"providedEstimate"|"calculatedEstimate", copyTrackingIds?: bool}
  --shipment-id: string # Shipment ID
]: any -> record<shipmentPlanId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipments/v4/plans" $qp)
  let req_body = {"autoStart": $auto_start, "description": $description, "name": $name, "ruleIds": $rule_ids, "segments": $segments, "subShipment": $sub_shipment, "options": $options, "shipmentId": $shipment_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a shipment plan
#
# DELETE /shipments/v4/plans/{shipmentPlanId}
export def "shipments-plans delete-by-shipmentPlanId" [
  shipment_plan_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_plan_id: (encode-path-segment $shipment_plan_id)} | format pattern "/shipments/v4/plans/{shipment_plan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a shipment plan details
#
# GET /shipments/v4/plans/{shipmentPlanId}
export def "shipments-plans get-by-shipmentPlanId" [
  shipment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<autoStart: bool, createdAt: string, description: string, name: string, ruleIds: list<string>, segments: table<description: string, destination: string, durationS: int, name: string, origin: string, segmentPlanId: string, trackingId: string, transportMode: string>, shipmentPlanId: string, subShipment: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_plan_id: (encode-path-segment $shipment_plan_id)} | format pattern "/shipments/v4/plans/{shipment_plan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a shipment plan details
#
# PATCH /shipments/v4/plans/{shipmentPlanId}
export def "shipments-plans update-by-shipmentPlanId" [
  shipment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-start: oneof<nothing, bool> # A boolean parameter defining whether the shipment starts upon exiting the first origin location.
  --description: string # Description of the shipment
  --name: string # Name of the shipment
  --rule-ids: list<string> # Array of `ruleId`s to associate with the shipment
  --sub-shipment: oneof<nothing, bool> # Flag telling if shipment is a subShipment.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_plan_id: (encode-path-segment $shipment_plan_id)} | format pattern "/shipments/v4/plans/{shipment_plan_id}"))
  let req_body = {"autoStart": $auto_start, "description": $description, "name": $name, "ruleIds": $rule_ids, "subShipment": $sub_shipment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a segment plan details
#
# GET /shipments/v4/plans/{shipmentPlanId}/{segmentPlanId}
export def "shipments-plans get-by-shipmentPlanId-segmentPlanId" [
  shipment_plan_id: string
  segment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, destination: string, durationS: int, name: string, origin: string, segmentPlanId: string, trackingId: string, transportMode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_plan_id: (encode-path-segment $shipment_plan_id), segment_plan_id: (encode-path-segment $segment_plan_id)} | format pattern "/shipments/v4/plans/{shipment_plan_id}/{segment_plan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a segment plan details
#
# PATCH /shipments/v4/plans/{shipmentPlanId}/{segmentPlanId}
export def "shipments-plans update-by-shipmentPlanId-segmentPlanId" [
  shipment_plan_id: string
  segment_plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the segment
  --duration-s: int # Segment duration in seconds.
  --name: string # Name of the segment
  --tracking-id: string # ID of the tracking device that produces data for this segment
  --transport-mode: string@transport-mode-completer # Transport mode of the segment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_plan_id: (encode-path-segment $shipment_plan_id), segment_plan_id: (encode-path-segment $segment_plan_id)} | format pattern "/shipments/v4/plans/{shipment_plan_id}/{segment_plan_id}"))
  let req_body = {"description": $description, "durationS": $duration_s, "name": $name, "trackingId": $tracking_id, "transportMode": $transport_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service version
#
# GET /shipments/v4/version
export def "shipments-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipments/v4/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes a shipment
#
# DELETE /shipments/v4/{shipmentId}
export def "shipments delete-by-shipmentId" [
  shipment_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/shipments/v4/{shipment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a shipment details
#
# GET /shipments/v4/{shipmentId}
export def "shipments get-by-shipmentId" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<autoStart: bool, calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, endedAt: string, name: string, providedEta: string, providedEtd: string, ruleIds: list<string>, segments: table<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string>, shipmentId: string, shipmentPlanId: string, startedAt: string, status: string, subShipment: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/shipments/v4/{shipment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a shipment details
#
# PATCH /shipments/v4/{shipmentId}
# --segments item shape: {description?: string, destination: string, name?: string, origin: string, providedEta?: string, providedEtd?: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
export def "shipments update-by-shipmentId" [
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-start: oneof<nothing, bool> # A boolean parameter defining whether the shipment starts upon exiting the first origin location.
  --description: string # Description of the shipment
  --name: string # Name of the shipment
  --provided-eta: string # ETA for the shipment (format: date-time)
  --provided-etd: string # ETD for the shipment (format: date-time)
  --rule-ids: list<string> # Array of `ruleId`s to associate with the shipment
  --segments: list # Array of objects each defining the origin and destination of the segment — item shape: {description?: string, destination: string, name?: string, origin: string, providedEta?: string, providedEtd?: string, trackingId?: string, transportMode: "car"|"truck"|"sea"|"air"|"undefined"}
  --status: string@status-completer # Status of the shipment
  --sub-shipment: oneof<nothing, bool> # Flag telling if shipment is a subShipment.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id)} | format pattern "/shipments/v4/{shipment_id}"))
  let req_body = {"autoStart": $auto_start, "description": $description, "name": $name, "providedEta": $provided_eta, "providedEtd": $provided_etd, "ruleIds": $rule_ids, "segments": $segments, "status": $status, "subShipment": $sub_shipment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a segment details
#
# GET /shipments/v4/{shipmentId}/{segmentId}
export def "shipments get-by-shipmentId-segmentId" [
  shipment_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id), segment_id: (encode-path-segment $segment_id)} | format pattern "/shipments/v4/{shipment_id}/{segment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a segment details
#
# PATCH /shipments/v4/{shipmentId}/{segmentId}
export def "shipments update-by-shipmentId-segmentId" [
  shipment_id: string
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the segment
  --name: string # Name of the segment
  --provided-eta: string # ETA for the segment (format: date-time)
  --provided-etd: string # ETD for the segment (format: date-time)
  --status: string@status-completer # Status of the segment
  --tracking-id: string # ID of the tracking device that produces data for the segment
  --transport-mode: string@transport-mode-completer # Transport mode of the segment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({shipment_id: (encode-path-segment $shipment_id), segment_id: (encode-path-segment $segment_id)} | format pattern "/shipments/v4/{shipment_id}/{segment_id}"))
  let req_body = {"description": $description, "name": $name, "providedEta": $provided_eta, "providedEtd": $provided_etd, "status": $status, "trackingId": $tracking_id, "transportMode": $transport_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets segments assigned to a device
#
# GET /shipments/v4/{trackingId}/segments
export def "shipments-segments get" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --limit: int # The number of items to return per page (default: 100)
  --status: string@status-completer # Filter the results by segment status
]: nothing -> record<count: int, items: table<calculatedEta: string, calculatedEtd: string, createdAt: string, description: string, destination: string, endedAt: string, name: string, origin: string, providedEta: string, providedEtd: string, segmentId: string, shipmentId: string, startedAt: string, status: string, trackingId: string, transportMode: string>, limit: int, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/shipments/v4/{tracking_id}/segments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /traces/v2/health
export def "traces-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/traces/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /traces/v2/version
export def "traces-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/traces/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deletes all the device traces and events
#
# DELETE /traces/v2/{trackingId}
export def "traces delete" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/traces/v2/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets traces within a specified time range
#
# GET /traces/v2/{trackingId}
export def "traces get" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --outliers: oneof<nothing, bool> # Flag specifying if only outliers (`true`) or only nonoutliers (`false`) are to be returned. If the parameter is not present both nonoutlier and outlier traces are returned.
  --mode: string@mode-completer # Tracker mode.
  --smooth: oneof<nothing, bool> # Flag telling if smoothed traces (true) or non-smoothed (false) traces should get returned. By default the traces are not smoothed. The smoothing will have an effect on to the stationary trace points only.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of records per page. (default: 1000)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: table<payload: record, position: record, serverTimestamp: int, system: record, timestamp: int, trackingDisabled: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "outliers" $outliers "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "smooth" $smooth "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/traces/v2/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets transitions for a device
#
# GET /transitions/v2/devices/{trackingId}
# DEPRECATED
@deprecated
export def "transitions-devices get" [
  tracking_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # Application identifier. Used together with an external ID to identify a virtual device.
  --before: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 1 to the current time.
  --after: float # Milliseconds elapsed since 1 January 1970 00:00:00 UTC. The accepted range is from 0 to the current time.
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: table<geofence: any, geofenceId: string, inOut: string, notificationStatus: string, timestamp: int, trackingId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tracking_id: (encode-path-segment $tracking_id)} | format pattern "/transitions/v2/devices/{tracking_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /transitions/v2/health
# DEPRECATED
@deprecated
export def "transitions-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transitions/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /transitions/v2/version
# DEPRECATED
@deprecated
export def "transitions-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transitions/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets all devices claimed by a project
#
# GET /users/v2/devices
export def "users-devices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string
  --page-token: string # A token from the previously returned response to retrieve the specified page.
  --count: int # The number of items to return per page. (default: 100)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<count: int, pageToken: string, data: table<appId: string, externalId: string, shadow: record, trackingId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $project_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/v2/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service health
#
# GET /users/v2/health
export def "users-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a user access token
#
# POST /users/v2/login
export def "users-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  email: string # The email address of the user
  password: string # The password of the user
  --realm: string # A case-insensitive requested realm ID
]: any -> record<accessToken: string, expiresIn: int, realm: string, refreshToken: string, tokenType: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/v2/login")
  let req_body = {"email": $email, "password": $password, "realm": $realm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a renewed user access token
#
# POST /users/v2/refresh
export def "users-refresh create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  access_token: string # The access token obtained in a previous login
  refresh_token: string # The refresh token obtained in a previous login
]: any -> record<accessToken: string, expiresIn: int, realm: string, refreshToken: string, tokenType: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/v2/refresh")
  let req_body = {"accessToken": $access_token, "refreshToken": $refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a project-scoped user access token
#
# POST /users/v2/tokenExchange
export def "users-token-exchange create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  access_token: string # HERE Account user access token, obtained from login endpoint.
  scope: string # Requested scope of the access token. Must be an HRN identifying a project that the identified user has access to.
]: any -> record<accessToken: string, expiresIn: int, issuedTokenType: string, scope: string, tokenType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/v2/tokenExchange")
  let req_body = {"accessToken": $access_token, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service version
#
# GET /users/v2/version
export def "users-version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Ingests data and receives a shadow
#
# POST /v2/
export def "ingestion create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool> # If set to `true`, ingests the device data and responds immediately with an empty response body. (default: false)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --authorization: string # e.g. Bearer h1.yxPIksZ0ViLq77f1Nh-9cg.NVgGBZVlCU8G7kjV_...
  --body: list
]: any -> record<payload: record, system: record<detectOutliers: bool, disableTracking: record<periods: list, position: any, sensors: any>, lastModifiedGeofenceTimestamp: int, rate: record<distanceM: float, sampleMs: float, sendMs: float>, sensorAlarmConfig: record<alertAccelerationGMax: float, alertAccelerationGMin: float, alertBatteryLevelPMax: float, alertBatteryLevelPMin: float, alertPressureHpaMax: float, alertPressureHpaMin: float, alertRelativeHumidityMax: float, alertRelativeHumidityMin: float, alertTemperatureCMax: float, alertTemperatureCMin: float, alertTiltDegreeMax: float, alertTiltDegreeMin: float, isAttachAlertEnabled: bool, isTamperAlertEnabled: bool>, sensorLoggingConfigurations: list<record>, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list<record>, wlanConnectivityEnabled: bool>, timestamp: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /v2/health
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the current timestamp
#
# GET /v2/timestamp
export def "timestamp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
]: nothing -> record<timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/timestamp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Requests a token for a registered device
#
# POST /v2/token
export def "token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --authorization: string # Signed OAuth 1.0 header (e.g. OAuth oauth_consumer_key='{deviceId}',oauth_signature_method='HMAC_SHA256',oauth_timestamp='{nowS}',oauth_nonce='{nonce}',oauth_signature='{signature}')
]: nothing -> record<accessToken: string, expiresIn: int> {
  let auth = (build-auth $token ($auth_scheme | default "oauth"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /v2/version
export def "version get" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Ingests data for a device and receives a shadow
#
# POST /v3/
# --data item shape: {payload?: record, position?: record, scan?: record, system?: record, timestamp: int}
export def "ingestion create-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool> # If set to `true`, ingests the device data and responds immediately with an empty response body. (default: false)
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --authorization: string # e.g. Bearer h1.yxPIksZ0ViLq77f1Nh-9cg.NVgGBZVlCU8G7kjV_...
  --app-id: string # The user's project appId. Used together with an external ID to identify the virtual device.
  data: list # item shape: {payload?: record, position?: record, scan?: record, system?: record, timestamp: int}
  --id: string # Tracking ID or application specific external ID, needed only if ingesting on behalf of another device.
]: any -> record<payload: record, system: record<detectOutliers: bool, disableTracking: record<periods: list, position: any, sensors: any>, lastModifiedGeofenceTimestamp: int, rate: record<distanceM: float, sampleMs: float, sendMs: float>, sensorAlarmConfig: record<alertAccelerationGMax: float, alertAccelerationGMin: float, alertBatteryLevelPMax: float, alertBatteryLevelPMin: float, alertPressureHpaMax: float, alertPressureHpaMin: float, alertRelativeHumidityMax: float, alertRelativeHumidityMin: float, alertTemperatureCMax: float, alertTemperatureCMin: float, alertTiltDegreeMax: float, alertTiltDegreeMin: float, isAttachAlertEnabled: bool, isTamperAlertEnabled: bool>, sensorLoggingConfigurations: list<record>, sensorLoggingEnabled: bool, stateVersion: int, syncGeofences: bool, wlanConfigurations: list<record>, wlanConnectivityEnabled: bool>, timestamp: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/" $qp)
  let req_body = {"appId": $app_id, "data": $data, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Ingests data for multiple devices
#
# POST /v3/batch
# --data item shape: {payload?: record, position?: record, scan?: record, system?: record, timestamp: int, id?: string}
export def "batch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # ID used for correlating requests within HERE Tracking. Used for logging and error reporting. Must be a valid UUIDv4.
  --authorization: string # e.g. Bearer h1.yxPIksZ0ViLq77f1Nh-9cg.NVgGBZVlCU8G7kjV_...
  --app-id: string # The user's project appId. Used together with an external ID to identify the virtual devices.
  data: list # item shape: {payload?: record, position?: record, scan?: record, system?: record, timestamp: int, id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/batch")
  let req_body = {"appId": $app_id, "data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets service health
#
# GET /v3/health
export def "health get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service version
#
# GET /v3/version
export def "version get-1" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
