# Auto-generated client for Twilio - Preview v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_preview/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_PREVIEW_TOKEN

const BASE_URL = "https://preview.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_PREVIEW_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://preview.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["canceled" "failed" "opened" "signed" "signing"] }
def status-completer-1 [] { ["action-required" "carrier-processing" "completed" "failed" "pending-loa" "pending-verification" "received" "testing" "verified"] }
def sms-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def sms-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def verification-type-completer [] { ["phone-bill" "phone-call"] }
def order-completer [] { ["asc" "desc"] }
def bounds-completer [] { ["exclusive" "inclusive"] }
def commands-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "deployed-devices-fleets list" } } | get name | first)
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

# Retrieve a list of all Fleets belonging to your account.
#
# GET /DeployedDevices/Fleets
# operationId: ListDeployedDevicesFleet
export def "deployed-devices-fleets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<fleets: table<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/DeployedDevices/Fleets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Fleet for scoping of deployed devices within your account.
#
# POST /DeployedDevices/Fleets
# operationId: CreateDeployedDevicesFleet
export def "deployed-devices-fleets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # Provides a human readable descriptive text for this Fleet, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/DeployedDevices/Fleets")
  let req_body = {"FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Certificate credentials belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Certificates
# operationId: ListDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates list" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-sid: string # Filters the resulting list of Certificates by a unique string identifier of an authenticated Device.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<certificates: table<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  let qp = [(serialize-qp "DeviceSid" $device_sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Certificates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DeviceSid": $device_sid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Enroll a new Certificate credential to the Fleet, optionally giving it a friendly name and assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Certificates
# operationId: CreateDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates create" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  certificate_data: string # Provides a URL encoded representation of the public certificate in PEM format.
  --device-sid: string # Provides the unique string identifier of an existing Device to become authenticated with this Certificate credential.
  --friendly-name: string # Provides a human readable descriptive text for this Certificate credential, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Certificates"))
  let req_body = {"CertificateData": $certificate_data, "DeviceSid": $device_sid, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Unregister a specific Certificate credential from the Fleet, effectively disallowing any inbound client connections that are presenting it.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# operationId: DeleteDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates delete" [
  fleet_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Certificates/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch information about a specific Certificate credential in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# operationId: FetchDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates get" [
  fleet_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Certificates/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the given properties of a specific Certificate credential in the Fleet, giving it a friendly name or assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Certificates/{Sid}
# operationId: UpdateDeployedDevicesCertificate
export def "deployed-devices-fleets-certificates update" [
  fleet_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-sid: string # Provides the unique string identifier of an existing Device to become authenticated with this Certificate credential.
  --friendly-name: string # Provides a human readable descriptive text for this Certificate credential, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, sid: string, thumbprint: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Certificates/{sid}"))
  let req_body = {"DeviceSid": $device_sid, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Deployments belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Deployments
# operationId: ListDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments list" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<deployments: table<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Deployments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Deployment in the Fleet, optionally giving it a friendly name and linking to a specific Twilio Sync service instance.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Deployments
# operationId: CreateDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments create" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # Provides a human readable descriptive text for this Deployment, up to 256 characters long.
  --sync-service-sid: string # Provides the unique string identifier of the Twilio Sync service instance that will be linked to and accessible by this Deployment.
]: any -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Deployments"))
  let req_body = {"FriendlyName": $friendly_name, "SyncServiceSid": $sync_service_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a specific Deployment from the Fleet, leaving associated devices effectively undeployed.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# operationId: DeleteDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments delete" [
  fleet_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Deployments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch information about a specific Deployment in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# operationId: FetchDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments get" [
  fleet_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Deployments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the given properties of a specific Deployment credential in the Fleet, giving it a friendly name or linking to a specific Twilio Sync service instance.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Deployments/{Sid}
# operationId: UpdateDeployedDevicesDeployment
export def "deployed-devices-fleets-deployments update" [
  fleet_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # Provides a human readable descriptive text for this Deployment, up to 64 characters long
  --sync-service-sid: string # Provides the unique string identifier of the Twilio Sync service instance that will be linked to and accessible by this Deployment.
]: any -> record<account_sid: string, date_created: string, date_updated: string, fleet_sid: string, friendly_name: string, sid: string, sync_service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Deployments/{sid}"))
  let req_body = {"FriendlyName": $friendly_name, "SyncServiceSid": $sync_service_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Devices belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Devices
# operationId: ListDeployedDevicesDevice
export def "deployed-devices-fleets-devices list" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-sid: string # Filters the resulting list of Devices by a unique string identifier of the Deployment they are associated with.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<devices: table<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  let qp = [(serialize-qp "DeploymentSid" $deployment_sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DeploymentSid": $deployment_sid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Device in the Fleet, optionally giving it a unique name, friendly name, and assigning to a Deployment and/or human identity.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Devices
# operationId: CreateDeployedDevicesDevice
export def "deployed-devices-fleets-devices create" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-sid: string # Specifies the unique string identifier of the Deployment group that this Device is going to be associated with.
  --enabled: oneof<nothing, bool>
  --friendly-name: string # Provides a human readable descriptive text to be assigned to this Device, up to 256 characters long.
  --identity: string # Provides an arbitrary string identifier representing a human user to be associated with this Device, up to 256 characters long.
  --unique-name: string # Provides a unique and addressable name to be assigned to this Device, to be used in addition to SID, up to 128 characters long.
]: any -> record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Devices"))
  let req_body = {"DeploymentSid": $deployment_sid, "Enabled": $enabled, "FriendlyName": $friendly_name, "Identity": $identity, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a specific Device from the Fleet, also removing it from associated Deployments.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# operationId: DeleteDeployedDevicesDevice
export def "deployed-devices-fleets-devices delete" [
  fleet_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Devices/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch information about a specific Device in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# operationId: FetchDeployedDevicesDevice
export def "deployed-devices-fleets-devices get" [
  fleet_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Devices/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the given properties of a specific Device in the Fleet, giving it a friendly name, assigning to a Deployment, or a human identity.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Devices/{Sid}
# operationId: UpdateDeployedDevicesDevice
export def "deployed-devices-fleets-devices update" [
  fleet_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-sid: string # Specifies the unique string identifier of the Deployment group that this Device is going to be associated with.
  --enabled: oneof<nothing, bool>
  --friendly-name: string # Provides a human readable descriptive text to be assigned to this Device, up to 256 characters long.
  --identity: string # Provides an arbitrary string identifier representing a human user to be associated with this Device, up to 256 characters long.
]: any -> record<account_sid: string, date_authenticated: string, date_created: string, date_updated: string, deployment_sid: string, enabled: bool, fleet_sid: string, friendly_name: string, identity: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Devices/{sid}"))
  let req_body = {"DeploymentSid": $deployment_sid, "Enabled": $enabled, "FriendlyName": $friendly_name, "Identity": $identity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Keys credentials belonging to the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Keys
# operationId: ListDeployedDevicesKey
export def "deployed-devices-fleets-keys list" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-sid: string # Filters the resulting list of Keys by a unique string identifier of an authenticated Device.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<keys: table<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  let qp = [(serialize-qp "DeviceSid" $device_sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Keys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"DeviceSid": $device_sid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create a new Key credential in the Fleet, optionally giving it a friendly name and assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Keys
# operationId: CreateDeployedDevicesKey
export def "deployed-devices-fleets-keys create" [
  fleet_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-sid: string # Provides the unique string identifier of an existing Device to become authenticated with this Key credential.
  --friendly-name: string # Provides a human readable descriptive text for this Key credential, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Keys"))
  let req_body = {"DeviceSid": $device_sid, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a specific Key credential from the Fleet, effectively disallowing any inbound client connections that are presenting it.
#
# DELETE /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# operationId: DeleteDeployedDevicesKey
export def "deployed-devices-fleets-keys delete" [
  fleet_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Keys/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch information about a specific Key credential in the Fleet.
#
# GET /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# operationId: FetchDeployedDevicesKey
export def "deployed-devices-fleets-keys get" [
  fleet_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Keys/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the given properties of a specific Key credential in the Fleet, giving it a friendly name or assigning to a Device.
#
# POST /DeployedDevices/Fleets/{FleetSid}/Keys/{Sid}
# operationId: UpdateDeployedDevicesKey
export def "deployed-devices-fleets-keys update" [
  fleet_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-sid: string # Provides the unique string identifier of an existing Device to become authenticated with this Key credential.
  --friendly-name: string # Provides a human readable descriptive text for this Key credential, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, device_sid: string, fleet_sid: string, friendly_name: string, secret: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($fleet_sid | is-empty) { error make --unspanned { msg: "path parameter 'FleetSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({fleet_sid: (encode-path-segment $fleet_sid), sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{fleet_sid}/Keys/{sid}"))
  let req_body = {"DeviceSid": $device_sid, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a specific Fleet from your account, also destroys all nested resources: Devices, Deployments, Certificates, Keys.
#
# DELETE /DeployedDevices/Fleets/{Sid}
# operationId: DeleteDeployedDevicesFleet
export def "deployed-devices-fleets delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch information about a specific Fleet in your account.
#
# GET /DeployedDevices/Fleets/{Sid}
# operationId: FetchDeployedDevicesFleet
export def "deployed-devices-fleets get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the friendly name property of a specific Fleet in your account.
#
# POST /DeployedDevices/Fleets/{Sid}
# operationId: UpdateDeployedDevicesFleet
export def "deployed-devices-fleets update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-deployment-sid: string # Provides a string identifier of a Deployment that is going to be used as a default one for this Fleet.
  --friendly-name: string # Provides a human readable descriptive text for this Fleet, up to 256 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, default_deployment_sid: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/DeployedDevices/Fleets/{sid}"))
  let req_body = {"DefaultDeploymentSid": $default_deployment_sid, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of AuthorizationDocuments belonging to the account initiating the request.
#
# GET /HostedNumbers/AuthorizationDocuments
# operationId: ListHostedNumbersAuthorizationDocument
export def "hosted-numbers-authorization-documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email that this AuthorizationDocument will be sent to for signing.
  --status: string@status-completer # Status of an instance resource. It can hold one of the values: 1. opened 2. signing, 3. signed LOA, 4. canceled, 5. failed. See the section entitled [Status Values](https://www.twilio.com/docs/api/phone-numbers/hosted-number-authorization-documents#status-values) for more information on each of these statuses.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<items: table<address_sid: string, cc_emails: list, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Email" $email "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/HostedNumbers/AuthorizationDocuments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Email": $email, "Status": $status, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Create an AuthorizationDocument for authorizing the hosting of phone number capabilities on Twilio's platform.
#
# POST /HostedNumbers/AuthorizationDocuments
# operationId: CreateHostedNumbersAuthorizationDocument
export def "hosted-numbers-authorization-documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_sid: string # A 34 character string that uniquely identifies the Address resource that is associated with this AuthorizationDocument.
  --cc-emails: list<string> # Email recipients who will be informed when an Authorization Document has been sent and signed.
  contact_phone_number: string # The contact phone number of the person authorized to sign the Authorization Document.
  contact_title: string # The title of the person authorized to sign the Authorization Document for this phone number.
  email: string # Email that this AuthorizationDocument will be sent to for signing.
  hosted_number_order_sids: list<string> # A list of HostedNumberOrder sids that this AuthorizationDocument will authorize for hosting phone number capabilities on Twilio's platform.
]: any -> record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/HostedNumbers/AuthorizationDocuments")
  let req_body = {"AddressSid": $address_sid, "CcEmails": $cc_emails, "ContactPhoneNumber": $contact_phone_number, "ContactTitle": $contact_title, "Email": $email, "HostedNumberOrderSids": $hosted_number_order_sids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch a specific AuthorizationDocument.
#
# GET /HostedNumbers/AuthorizationDocuments/{Sid}
# operationId: FetchHostedNumbersAuthorizationDocument
export def "hosted-numbers-authorization-documents get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/HostedNumbers/AuthorizationDocuments/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a specific AuthorizationDocument.
#
# POST /HostedNumbers/AuthorizationDocuments/{Sid}
# operationId: UpdateHostedNumbersAuthorizationDocument
export def "hosted-numbers-authorization-documents update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # A 34 character string that uniquely identifies the Address resource that is associated with this AuthorizationDocument.
  --cc-emails: list<string> # Email recipients who will be informed when an Authorization Document has been sent and signed
  --contact-phone-number: string # The contact phone number of the person authorized to sign the Authorization Document.
  --contact-title: string # The title of the person authorized to sign the Authorization Document for this phone number.
  --email: string # Email that this AuthorizationDocument will be sent to for signing.
  --hosted-number-order-sids: list<string> # A list of HostedNumberOrder sids that this AuthorizationDocument will authorize for hosting phone number capabilities on Twilio's platform.
  --status: string@status-completer
]: any -> record<address_sid: string, cc_emails: list<string>, date_created: string, date_updated: string, email: string, links: record, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/HostedNumbers/AuthorizationDocuments/{sid}"))
  let req_body = {"AddressSid": $address_sid, "CcEmails": $cc_emails, "ContactPhoneNumber": $contact_phone_number, "ContactTitle": $contact_title, "Email": $email, "HostedNumberOrderSids": $hosted_number_order_sids, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of dependent HostedNumberOrders belonging to the AuthorizationDocument.
#
# GET /HostedNumbers/AuthorizationDocuments/{SigningDocumentSid}/DependentHostedNumberOrders
# operationId: ListHostedNumbersDependentHostedNumberOrder
export def "hosted-numbers-authorization-documents-dependent-hosted-number-orders list" [
  signing_document_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Status of an instance resource. It can hold one of the values: 1. opened 2. signing, 3. signed LOA, 4. canceled, 5. failed. See the section entitled [Status Values](https://www.twilio.com/docs/api/phone-numbers/hosted-number-authorization-documents#status-values) for more information on each of these statuses.
  --phone-number: string # An E164 formatted phone number hosted by this HostedNumberOrder. (format: phone-number)
  --incoming-phone-number-sid: string # A 34 character string that uniquely identifies the IncomingPhoneNumber resource created by this HostedNumberOrder.
  --friendly-name: string # A human readable description of this resource, up to 64 characters.
  --unique-name: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, address_sid: string, call_delay: int, capabilities: record, cc_emails: list, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, verification_attempts: int, verification_call_sids: list, verification_code: string, verification_document_sid: string, verification_type: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($signing_document_sid | is-empty) { error make --unspanned { msg: "path parameter 'SigningDocumentSid' must be non-empty" } }
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "PhoneNumber" $phone_number "scalar") (serialize-qp "IncomingPhoneNumberSid" $incoming_phone_number_sid "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "UniqueName" $unique_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({signing_document_sid: (encode-path-segment $signing_document_sid)} | format pattern "/HostedNumbers/AuthorizationDocuments/{signing_document_sid}/DependentHostedNumberOrders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Status": $status, "PhoneNumber": $phone_number, "IncomingPhoneNumberSid": $incoming_phone_number_sid, "FriendlyName": $friendly_name, "UniqueName": $unique_name, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Retrieve a list of HostedNumberOrders belonging to the account initiating the request.
#
# GET /HostedNumbers/HostedNumberOrders
# operationId: ListHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # The Status of this HostedNumberOrder. One of `received`, `pending-verification`, `verified`, `pending-loa`, `carrier-processing`, `testing`, `completed`, `failed`, or `action-required`.
  --phone-number: string # An E164 formatted phone number hosted by this HostedNumberOrder. (format: phone-number)
  --incoming-phone-number-sid: string # A 34 character string that uniquely identifies the IncomingPhoneNumber resource created by this HostedNumberOrder.
  --friendly-name: string # A human readable description of this resource, up to 64 characters.
  --unique-name: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, address_sid: string, call_delay: int, capabilities: record, cc_emails: list, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list, verification_code: string, verification_document_sid: string, verification_type: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "PhoneNumber" $phone_number "scalar") (serialize-qp "IncomingPhoneNumberSid" $incoming_phone_number_sid "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "UniqueName" $unique_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/HostedNumbers/HostedNumberOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Status": $status, "PhoneNumber": $phone_number, "IncomingPhoneNumberSid": $incoming_phone_number_sid, "FriendlyName": $friendly_name, "UniqueName": $unique_name, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Host a phone number's capability on Twilio's platform.
#
# POST /HostedNumbers/HostedNumberOrders
# operationId: CreateHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-sid: string # This defaults to the AccountSid of the authorization the user is using. This can be provided to specify a subaccount to add the HostedNumberOrder to.
  --address-sid: string # Optional. A 34 character string that uniquely identifies the Address resource that represents the address of the owner of this phone number.
  --cc-emails: list<string> # Optional. A list of emails that the LOA document for this HostedNumberOrder will be carbon copied to.
  --email: string # Optional. Email of the owner of this phone number that is being hosted.
  --friendly-name: string # A 64 character string that is a human readable text that describes this resource.
  phone_number: string # The number to host in [+E.164](https://en.wikipedia.org/wiki/E.164) format (format: phone-number)
  --sms-application-sid: string # Optional. The 34 character sid of the application Twilio should use to handle SMS messages sent to this number. If a `SmsApplicationSid` is present, Twilio will ignore all of the SMS urls above and use those set on the application.
  --sms-capability: oneof<nothing, bool> # Used to specify that the SMS capability will be hosted on Twilio's platform.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that should be used to request the SmsFallbackUrl. Must be either `GET` or `POST`. This will be copied onto the IncomingPhoneNumber resource. (format: http-method)
  --sms-fallback-url: string # A URL that Twilio will request if an error occurs requesting or executing the TwiML defined by SmsUrl. This will be copied onto the IncomingPhoneNumber resource. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that should be used to request the SmsUrl. Must be either `GET` or `POST`. This will be copied onto the IncomingPhoneNumber resource. (format: http-method)
  --sms-url: string # The URL that Twilio should request when somebody sends an SMS to the phone number. This will be copied onto the IncomingPhoneNumber resource. (format: uri)
  --status-callback-method: string@status-callback-method-completer # Optional. The Status Callback Method attached to the IncomingPhoneNumber resource. (format: http-method)
  --status-callback-url: string # Optional. The Status Callback URL attached to the IncomingPhoneNumber resource. (format: uri)
  --unique-name: string # Optional. Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --verification-document-sid: string # Optional. The unique sid identifier of the Identity Document that represents the document for verifying ownership of the number to be hosted. Required when VerificationType is phone-bill.
  --verification-type: string@verification-type-completer
]: any -> record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/HostedNumbers/HostedNumberOrders")
  let req_body = {"AccountSid": $account_sid, "AddressSid": $address_sid, "CcEmails": $cc_emails, "Email": $email, "FriendlyName": $friendly_name, "PhoneNumber": $phone_number, "SmsApplicationSid": $sms_application_sid, "SmsCapability": $sms_capability, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsUrl": $sms_url, "StatusCallbackMethod": $status_callback_method, "StatusCallbackUrl": $status_callback_url, "UniqueName": $unique_name, "VerificationDocumentSid": $verification_document_sid, "VerificationType": $verification_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Cancel the HostedNumberOrder (only available when the status is in `received`).
#
# DELETE /HostedNumbers/HostedNumberOrders/{Sid}
# operationId: DeleteHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/HostedNumbers/HostedNumberOrders/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a specific HostedNumberOrder.
#
# GET /HostedNumbers/HostedNumberOrders/{Sid}
# operationId: FetchHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/HostedNumbers/HostedNumberOrders/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a specific HostedNumberOrder.
#
# POST /HostedNumbers/HostedNumberOrders/{Sid}
# operationId: UpdateHostedNumbersHostedNumberOrder
export def "hosted-numbers-hosted-number-orders update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-delay: int # The number of seconds, between 0 and 60, to delay before initiating the verification call. Defaults to 0.
  --cc-emails: list<string> # Optional. A list of emails that LOA document for this HostedNumberOrder will be carbon copied to.
  --email: string # Email of the owner of this phone number that is being hosted.
  --extension: string # Digits to dial after connecting the verification call.
  --friendly-name: string # A 64 character string that is a human readable text that describes this resource.
  --status: string@status-completer-1
  --unique-name: string # Provides a unique and addressable name to be assigned to this HostedNumberOrder, assigned by the developer, to be optionally used in addition to SID.
  --verification-code: string # A verification code that is given to the user via a phone call to the phone number that is being hosted.
  --verification-document-sid: string # Optional. The unique sid identifier of the Identity Document that represents the document for verifying ownership of the number to be hosted. Required when VerificationType is phone-bill.
  --verification-type: string@verification-type-completer
]: any -> record<account_sid: string, address_sid: string, call_delay: int, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, cc_emails: list<string>, date_created: string, date_updated: string, email: string, extension: string, failure_reason: string, friendly_name: string, incoming_phone_number_sid: string, phone_number: string, sid: string, signing_document_sid: string, status: string, unique_name: string, url: string, verification_attempts: int, verification_call_sids: list<string>, verification_code: string, verification_document_sid: string, verification_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/HostedNumbers/HostedNumberOrders/{sid}"))
  let req_body = {"CallDelay": $call_delay, "CcEmails": $cc_emails, "Email": $email, "Extension": $extension, "FriendlyName": $friendly_name, "Status": $status, "UniqueName": $unique_name, "VerificationCode": $verification_code, "VerificationDocumentSid": $verification_document_sid, "VerificationType": $verification_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /Sync/Services
#
# operationId: ListSyncService
export def "sync-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Sync/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /Sync/Services
#
# operationId: CreateSyncService
export def "sync-services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl-enabled: oneof<nothing, bool>
  --friendly-name: string
  --reachability-webhooks-enabled: oneof<nothing, bool>
  --webhook-url: string # format: uri
]: any -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/Sync/Services")
  let req_body = {"AclEnabled": $acl_enabled, "FriendlyName": $friendly_name, "ReachabilityWebhooksEnabled": $reachability_webhooks_enabled, "WebhookUrl": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /Sync/Services/{ServiceSid}/Documents
#
# operationId: ListSyncDocument
export def "sync-services-documents list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<documents: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/Sync/Services/{service_sid}/Documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /Sync/Services/{ServiceSid}/Documents
#
# operationId: CreateSyncDocument
export def "sync-services-documents create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: any
  --unique-name: string
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/Sync/Services/{service_sid}/Documents"))
  let req_body = {"Data": $data, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Permissions applying to a Sync Document.
#
# GET /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions
# operationId: ListSyncDocumentPermission
export def "sync-services-documents-permissions list" [
  service_sid: string
  document_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($document_sid | is-empty) { error make --unspanned { msg: "path parameter 'DocumentSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid)} | format pattern "/Sync/Services/{service_sid}/Documents/{document_sid}/Permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Delete a specific Sync Document Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: DeleteSyncDocumentPermission
export def "sync-services-documents-permissions delete" [
  service_sid: string
  document_sid: string
  identity: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($document_sid | is-empty) { error make --unspanned { msg: "path parameter 'DocumentSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a specific Sync Document Permission.
#
# GET /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: FetchSyncDocumentPermission
export def "sync-services-documents-permissions get" [
  service_sid: string
  document_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($document_sid | is-empty) { error make --unspanned { msg: "path parameter 'DocumentSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an identity's access to a specific Sync Document.
#
# POST /Sync/Services/{ServiceSid}/Documents/{DocumentSid}/Permissions/{Identity}
# operationId: UpdateSyncDocumentPermission
export def "sync-services-documents-permissions update" [
  service_sid: string
  document_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync Document.
  --read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync Document.
  --write: oneof<nothing, bool> # Boolean flag specifying whether the identity can update the Sync Document.
]: any -> record<account_sid: string, document_sid: string, identity: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($document_sid | is-empty) { error make --unspanned { msg: "path parameter 'DocumentSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), document_sid: (encode-path-segment $document_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Documents/{document_sid}/Permissions/{identity}"))
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: DeleteSyncDocument
export def "sync-services-documents delete" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{service_sid}/Documents/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: FetchSyncDocument
export def "sync-services-documents get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{service_sid}/Documents/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /Sync/Services/{ServiceSid}/Documents/{Sid}
#
# operationId: UpdateSyncDocument
export def "sync-services-documents update" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The If-Match HTTP request header
  data: any
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{service_sid}/Documents/{sid}"))
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /Sync/Services/{ServiceSid}/Lists
#
# operationId: ListSyncSyncList
export def "sync-services-lists list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<lists: table<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/Sync/Services/{service_sid}/Lists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /Sync/Services/{ServiceSid}/Lists
#
# operationId: CreateSyncSyncList
export def "sync-services-lists create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unique-name: string
]: any -> record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/Sync/Services/{service_sid}/Lists"))
  let req_body = {"UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# operationId: ListSyncSyncListItem
export def "sync-services-lists-items list" [
  service_sid: string
  list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer
  --qp-from: string
  --bounds: string@bounds-completer
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  let qp = [(serialize-qp "Order" $order "scalar") (serialize-qp "From" $qp_from "scalar") (serialize-qp "Bounds" $bounds "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Order": $order, "From": $qp_from, "Bounds": $bounds, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items
#
# operationId: CreateSyncSyncListItem
export def "sync-services-lists-items create" [
  service_sid: string
  list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: any
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Items"))
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: DeleteSyncSyncListItem
export def "sync-services-lists-items delete" [
  service_sid: string
  list_sid: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The If-Match HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'Index' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Items/{index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: FetchSyncSyncListItem
export def "sync-services-lists-items get" [
  service_sid: string
  list_sid: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'Index' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Items/{index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Items/{Index}
#
# operationId: UpdateSyncSyncListItem
export def "sync-services-lists-items update" [
  service_sid: string
  list_sid: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string # The If-Match HTTP request header
  data: any
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, index: int, list_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'Index' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), index: (encode-path-segment $index)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Items/{index}"))
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Permissions applying to a Sync List.
#
# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions
# operationId: ListSyncSyncListPermission
export def "sync-services-lists-permissions list" [
  service_sid: string
  list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Delete a specific Sync List Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: DeleteSyncSyncListPermission
export def "sync-services-lists-permissions delete" [
  service_sid: string
  list_sid: string
  identity: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a specific Sync List Permission.
#
# GET /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: FetchSyncSyncListPermission
export def "sync-services-lists-permissions get" [
  service_sid: string
  list_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an identity's access to a specific Sync List.
#
# POST /Sync/Services/{ServiceSid}/Lists/{ListSid}/Permissions/{Identity}
# operationId: UpdateSyncSyncListPermission
export def "sync-services-lists-permissions update" [
  service_sid: string
  list_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync List.
  --read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync List.
  --write: oneof<nothing, bool> # Boolean flag specifying whether the identity can create, update and delete Items of the Sync List.
]: any -> record<account_sid: string, identity: string, list_sid: string, manage: bool, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($list_sid | is-empty) { error make --unspanned { msg: "path parameter 'ListSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), list_sid: (encode-path-segment $list_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Lists/{list_sid}/Permissions/{identity}"))
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /Sync/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: DeleteSyncSyncList
export def "sync-services-lists delete" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{service_sid}/Lists/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /Sync/Services/{ServiceSid}/Lists/{Sid}
#
# operationId: FetchSyncSyncList
export def "sync-services-lists get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{service_sid}/Lists/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /Sync/Services/{ServiceSid}/Maps
#
# operationId: ListSyncSyncMap
export def "sync-services-maps list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<maps: table<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/Sync/Services/{service_sid}/Maps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /Sync/Services/{ServiceSid}/Maps
#
# operationId: CreateSyncSyncMap
export def "sync-services-maps create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unique-name: string
]: any -> record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/Sync/Services/{service_sid}/Maps"))
  let req_body = {"UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# operationId: ListSyncSyncMapItem
export def "sync-services-maps-items list" [
  service_sid: string
  map_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer
  --qp-from: string
  --bounds: string@bounds-completer
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<items: table<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  let qp = [(serialize-qp "Order" $order "scalar") (serialize-qp "From" $qp_from "scalar") (serialize-qp "Bounds" $bounds "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Order": $order, "From": $qp_from, "Bounds": $bounds, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items
#
# operationId: CreateSyncSyncMapItem
export def "sync-services-maps-items create" [
  service_sid: string
  map_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: any
  key: string
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Items"))
  let req_body = {"Data": $data, "Key": $key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: DeleteSyncSyncMapItem
export def "sync-services-maps-items delete" [
  service_sid: string
  map_sid: string
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
  --if-match: string # The If-Match HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'Key' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Items/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: FetchSyncSyncMapItem
export def "sync-services-maps-items get" [
  service_sid: string
  map_sid: string
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
]: nothing -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'Key' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Items/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Items/{Key}
#
# operationId: UpdateSyncSyncMapItem
export def "sync-services-maps-items update" [
  service_sid: string
  map_sid: string
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
  --if-match: string # The If-Match HTTP request header
  data: any
]: any -> record<account_sid: string, created_by: string, data: any, date_created: string, date_updated: string, key: string, map_sid: string, revision: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'Key' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), key: (encode-path-segment $key)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Items/{key}"))
  let req_body = {"Data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of all Permissions applying to a Sync Map.
#
# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions
# operationId: ListSyncSyncMapPermission
export def "sync-services-maps-permissions list" [
  service_sid: string
  map_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, permissions: table<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Permissions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Delete a specific Sync Map Permission.
#
# DELETE /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: DeleteSyncSyncMapPermission
export def "sync-services-maps-permissions delete" [
  service_sid: string
  map_sid: string
  identity: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a specific Sync Map Permission.
#
# GET /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: FetchSyncSyncMapPermission
export def "sync-services-maps-permissions get" [
  service_sid: string
  map_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an identity's access to a specific Sync Map.
#
# POST /Sync/Services/{ServiceSid}/Maps/{MapSid}/Permissions/{Identity}
# operationId: UpdateSyncSyncMapPermission
export def "sync-services-maps-permissions update" [
  service_sid: string
  map_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --manage: oneof<nothing, bool> # Boolean flag specifying whether the identity can delete the Sync Map.
  --read: oneof<nothing, bool> # Boolean flag specifying whether the identity can read the Sync Map.
  --write: oneof<nothing, bool> # Boolean flag specifying whether the identity can create, update and delete Items of the Sync Map.
]: any -> record<account_sid: string, identity: string, manage: bool, map_sid: string, read: bool, service_sid: string, url: string, write: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($map_sid | is-empty) { error make --unspanned { msg: "path parameter 'MapSid' must be non-empty" } }
  if ($identity | is-empty) { error make --unspanned { msg: "path parameter 'Identity' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), map_sid: (encode-path-segment $map_sid), identity: (encode-path-segment $identity)} | format pattern "/Sync/Services/{service_sid}/Maps/{map_sid}/Permissions/{identity}"))
  let req_body = {"Manage": $manage, "Read": $read, "Write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /Sync/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: DeleteSyncSyncMap
export def "sync-services-maps delete" [
  service_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{service_sid}/Maps/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /Sync/Services/{ServiceSid}/Maps/{Sid}
#
# operationId: FetchSyncSyncMap
export def "sync-services-maps get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, created_by: string, date_created: string, date_updated: string, links: record, revision: string, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($service_sid | is-empty) { error make --unspanned { msg: "path parameter 'ServiceSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{service_sid}/Maps/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /Sync/Services/{Sid}
#
# operationId: DeleteSyncService
export def "sync-services delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /Sync/Services/{Sid}
#
# operationId: FetchSyncService
export def "sync-services get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /Sync/Services/{Sid}
#
# operationId: UpdateSyncService
export def "sync-services update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl-enabled: oneof<nothing, bool>
  --friendly-name: string
  --reachability-webhooks-enabled: oneof<nothing, bool>
  --webhook-url: string # format: uri
]: any -> record<account_sid: string, acl_enabled: bool, date_created: string, date_updated: string, friendly_name: string, links: record, reachability_webhooks_enabled: bool, sid: string, url: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/Sync/Services/{sid}"))
  let req_body = {"AclEnabled": $acl_enabled, "FriendlyName": $friendly_name, "ReachabilityWebhooksEnabled": $reachability_webhooks_enabled, "WebhookUrl": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of Add-ons currently available to be installed.
#
# GET /marketplace/AvailableAddOns
# operationId: ListMarketplaceAvailableAddOn
export def "marketplace-available-add-ons list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<available_add_ons: table<configuration_schema: any, description: string, friendly_name: string, links: record, pricing_type: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketplace/AvailableAddOns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Retrieve a list of Extensions for the Available Add-on.
#
# GET /marketplace/AvailableAddOns/{AvailableAddOnSid}/Extensions
# operationId: ListMarketplaceAvailableAddOnExtension
export def "marketplace-available-add-ons-extensions list" [
  available_add_on_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<extensions: table<available_add_on_sid: string, friendly_name: string, product_name: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($available_add_on_sid | is-empty) { error make --unspanned { msg: "path parameter 'AvailableAddOnSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({available_add_on_sid: (encode-path-segment $available_add_on_sid)} | format pattern "/marketplace/AvailableAddOns/{available_add_on_sid}/Extensions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Fetch an instance of an Extension for the Available Add-on.
#
# GET /marketplace/AvailableAddOns/{AvailableAddOnSid}/Extensions/{Sid}
# operationId: FetchMarketplaceAvailableAddOnExtension
export def "marketplace-available-add-ons-extensions get" [
  available_add_on_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available_add_on_sid: string, friendly_name: string, product_name: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($available_add_on_sid | is-empty) { error make --unspanned { msg: "path parameter 'AvailableAddOnSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({available_add_on_sid: (encode-path-segment $available_add_on_sid), sid: (encode-path-segment $sid)} | format pattern "/marketplace/AvailableAddOns/{available_add_on_sid}/Extensions/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch an instance of an Add-on currently available to be installed.
#
# GET /marketplace/AvailableAddOns/{Sid}
# operationId: FetchMarketplaceAvailableAddOn
export def "marketplace-available-add-ons get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<configuration_schema: any, description: string, friendly_name: string, links: record, pricing_type: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/marketplace/AvailableAddOns/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of Add-ons currently installed on this Account.
#
# GET /marketplace/InstalledAddOns
# operationId: ListMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<installed_add_ons: table<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketplace/InstalledAddOns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Install an Add-on for the Account specified.
#
# POST /marketplace/InstalledAddOns
# operationId: CreateMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-terms-of-service: oneof<nothing, bool> # Whether the Terms of Service were accepted.
  available_add_on_sid: string # The SID of the AvaliableAddOn to install.
  --configuration: any # The JSON object that represents the configuration of the new Add-on being installed.
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be unique within the Account.
]: any -> record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/marketplace/InstalledAddOns")
  let req_body = {"AcceptTermsOfService": $accept_terms_of_service, "AvailableAddOnSid": $available_add_on_sid, "Configuration": $configuration, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Retrieve a list of Extensions for the Installed Add-on.
#
# GET /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions
# operationId: ListMarketplaceInstalledAddOnExtension
export def "marketplace-installed-add-ons-extensions list" [
  installed_add_on_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<extensions: table<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($installed_add_on_sid | is-empty) { error make --unspanned { msg: "path parameter 'InstalledAddOnSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({installed_add_on_sid: (encode-path-segment $installed_add_on_sid)} | format pattern "/marketplace/InstalledAddOns/{installed_add_on_sid}/Extensions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# Fetch an instance of an Extension for the Installed Add-on.
#
# GET /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions/{Sid}
# operationId: FetchMarketplaceInstalledAddOnExtension
export def "marketplace-installed-add-ons-extensions get" [
  installed_add_on_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($installed_add_on_sid | is-empty) { error make --unspanned { msg: "path parameter 'InstalledAddOnSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({installed_add_on_sid: (encode-path-segment $installed_add_on_sid), sid: (encode-path-segment $sid)} | format pattern "/marketplace/InstalledAddOns/{installed_add_on_sid}/Extensions/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an Extension for an Add-on installation.
#
# POST /marketplace/InstalledAddOns/{InstalledAddOnSid}/Extensions/{Sid}
# operationId: UpdateMarketplaceInstalledAddOnExtension
export def "marketplace-installed-add-ons-extensions update" [
  installed_add_on_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Whether the Extension should be invoked.
]: any -> record<enabled: bool, friendly_name: string, installed_add_on_sid: string, product_name: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($installed_add_on_sid | is-empty) { error make --unspanned { msg: "path parameter 'InstalledAddOnSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({installed_add_on_sid: (encode-path-segment $installed_add_on_sid), sid: (encode-path-segment $sid)} | format pattern "/marketplace/InstalledAddOns/{installed_add_on_sid}/Extensions/{sid}"))
  let req_body = {"Enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Remove an Add-on installation from your account
#
# DELETE /marketplace/InstalledAddOns/{Sid}
# operationId: DeleteMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/marketplace/InstalledAddOns/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch an instance of an Add-on currently installed on this Account.
#
# GET /marketplace/InstalledAddOns/{Sid}
# operationId: FetchMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/marketplace/InstalledAddOns/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an Add-on installation for the Account specified.
#
# POST /marketplace/InstalledAddOns/{Sid}
# operationId: UpdateMarketplaceInstalledAddOn
export def "marketplace-installed-add-ons update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration: any # Valid JSON object that conform to the configuration schema exposed by the associated AvailableAddOn resource. This is only required by Add-ons that need to be configured
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be unique within the Account.
]: any -> record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/marketplace/InstalledAddOns/{sid}"))
  let req_body = {"Configuration": $configuration, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants
#
# operationId: ListUnderstandAssistant
export def "understand-assistants list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<assistants: table<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/understand/Assistants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /understand/Assistants
#
# operationId: CreateUnderstandAssistant
export def "understand-assistants create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-events: string # Space-separated list of callback events that will trigger callbacks.
  --callback-url: string # A user-provided URL to send event callbacks to. (format: uri)
  --fallback-actions: any # The JSON actions to be executed when the user's input is not recognized as matching any Task.
  --friendly-name: string # A text description for the Assistant. It is non-unique and can up to 255 characters long.
  --initiation-actions: any # The JSON actions to be executed on inbound phone calls when the Assistant has to say something first.
  --log-queries: oneof<nothing, bool> # A boolean that specifies whether queries should be logged for 30 days further training. If false, no queries will be stored, if true, queries will be stored for 30 days and deleted thereafter. Defaults to true if no value is provided.
  --style-sheet: any # The JSON object that holds the style sheet for the assistant
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/understand/Assistants")
  let req_body = {"CallbackEvents": $callback_events, "CallbackUrl": $callback_url, "FallbackActions": $fallback_actions, "FriendlyName": $friendly_name, "InitiationActions": $initiation_actions, "LogQueries": $log_queries, "StyleSheet": $style_sheet, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/Dialogues/{Sid}
#
# operationId: FetchUnderstandDialogue
export def "understand-assistants-dialogues get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Dialogues/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/FallbackActions
#
# operationId: FetchUnderstandAssistantFallbackActions
export def "understand-assistants-fallback-actions get" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/FallbackActions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /understand/Assistants/{AssistantSid}/FallbackActions
#
# operationId: UpdateUnderstandAssistantFallbackActions
export def "understand-assistants-fallback-actions update" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fallback-actions: any
]: any -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/FallbackActions"))
  let req_body = {"FallbackActions": $fallback_actions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes
#
# operationId: ListUnderstandFieldType
export def "understand-assistants-field-types list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<field_types: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes
#
# operationId: CreateUnderstandFieldType
export def "understand-assistants-field-types create" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  unique_name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes"))
  let req_body = {"FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# operationId: ListUnderstandFieldValue
export def "understand-assistants-field-types-field-values list" [
  assistant_sid: string
  field_type_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # An ISO language-country string of the value. For example: *en-US*
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<field_values: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($field_type_sid | is-empty) { error make --unspanned { msg: "path parameter 'FieldTypeSid' must be non-empty" } }
  let qp = [(serialize-qp "Language" $language "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), field_type_sid: (encode-path-segment $field_type_sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes/{field_type_sid}/FieldValues") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Language": $language, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# operationId: CreateUnderstandFieldValue
export def "understand-assistants-field-types-field-values create" [
  assistant_sid: string
  field_type_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string # An ISO language-country string of the value.
  --synonym-of: string # A value that indicates this field value is a synonym of. Empty if the value is not a synonym.
  value: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($field_type_sid | is-empty) { error make --unspanned { msg: "path parameter 'FieldTypeSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), field_type_sid: (encode-path-segment $field_type_sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes/{field_type_sid}/FieldValues"))
  let req_body = {"Language": $language, "SynonymOf": $synonym_of, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# operationId: DeleteUnderstandFieldValue
export def "understand-assistants-field-types-field-values delete" [
  assistant_sid: string
  field_type_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($field_type_sid | is-empty) { error make --unspanned { msg: "path parameter 'FieldTypeSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), field_type_sid: (encode-path-segment $field_type_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes/{field_type_sid}/FieldValues/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# operationId: FetchUnderstandFieldValue
export def "understand-assistants-field-types-field-values get" [
  assistant_sid: string
  field_type_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($field_type_sid | is-empty) { error make --unspanned { msg: "path parameter 'FieldTypeSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), field_type_sid: (encode-path-segment $field_type_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes/{field_type_sid}/FieldValues/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: DeleteUnderstandFieldType
export def "understand-assistants-field-types delete" [
  assistant_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: FetchUnderstandFieldType
export def "understand-assistants-field-types get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /understand/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: UpdateUnderstandFieldType
export def "understand-assistants-field-types update" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/FieldTypes/{sid}"))
  let req_body = {"FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/InitiationActions
#
# operationId: FetchUnderstandAssistantInitiationActions
export def "understand-assistants-initiation-actions get" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/InitiationActions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /understand/Assistants/{AssistantSid}/InitiationActions
#
# operationId: UpdateUnderstandAssistantInitiationActions
export def "understand-assistants-initiation-actions update" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --initiation-actions: any
]: any -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/InitiationActions"))
  let req_body = {"InitiationActions": $initiation_actions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/ModelBuilds
#
# operationId: ListUnderstandModelBuild
export def "understand-assistants-model-builds list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, model_builds: table<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/ModelBuilds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /understand/Assistants/{AssistantSid}/ModelBuilds
#
# operationId: CreateUnderstandModelBuild
export def "understand-assistants-model-builds create" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status-callback: string # format: uri
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long. For example: v0.1
]: any -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/ModelBuilds"))
  let req_body = {"StatusCallback": $status_callback, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: DeleteUnderstandModelBuild
export def "understand-assistants-model-builds delete" [
  assistant_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/ModelBuilds/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: FetchUnderstandModelBuild
export def "understand-assistants-model-builds get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/ModelBuilds/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /understand/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: UpdateUnderstandModelBuild
export def "understand-assistants-model-builds update" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long. For example: v0.1
]: any -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/ModelBuilds/{sid}"))
  let req_body = {"UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/Queries
#
# operationId: ListUnderstandQuery
export def "understand-assistants-queries list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # An ISO language-country string of the sample.
  --model-build: string # The Model Build Sid or unique name of the Model Build to be queried.
  --status: string # A string that described the query status. The values can be: pending_review, reviewed, discarded
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, queries: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let qp = [(serialize-qp "Language" $language "scalar") (serialize-qp "ModelBuild" $model_build "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Queries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Language": $language, "ModelBuild": $model_build, "Status": $status, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /understand/Assistants/{AssistantSid}/Queries
#
# operationId: CreateUnderstandQuery
export def "understand-assistants-queries create-list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field: string # Constraints the query to a given Field with an task. Useful when you know the Field you are expecting. It accepts one field in the format *task-unique-name-1*:*field-unique-name*
  language: string # An ISO language-country string of the sample.
  --model-build: string # The Model Build Sid or unique name of the Model Build to be queried.
  query: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. It can be up to 2048 characters long.
  --tasks: string # Constraints the query to a set of tasks. Useful when you need to constrain the paths the user can take. Tasks should be comma separated *task-unique-name-1*, *task-unique-name-2*
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Queries"))
  let req_body = {"Field": $field, "Language": $language, "ModelBuild": $model_build, "Query": $query, "Tasks": $tasks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: DeleteUnderstandQuery
export def "understand-assistants-queries delete-list" [
  assistant_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Queries/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: FetchUnderstandQuery
export def "understand-assistants-queries get-list" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Queries/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /understand/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: UpdateUnderstandQuery
export def "understand-assistants-queries update-list" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sample-sid: string # An optional reference to the Sample created from this query.
  --status: string # A string that described the query status. The values can be: pending_review, reviewed, discarded
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Queries/{sid}"))
  let req_body = {"SampleSid": $sample_sid, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Returns Style sheet JSON object for this Assistant
#
# GET /understand/Assistants/{AssistantSid}/StyleSheet
# operationId: FetchUnderstandStyleSheet
export def "understand-assistants-style-sheet get" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/StyleSheet"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the style sheet for an assistant identified by {AssistantSid} or {AssistantUniqueName}.
#
# POST /understand/Assistants/{AssistantSid}/StyleSheet
# operationId: UpdateUnderstandStyleSheet
export def "understand-assistants-style-sheet update" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --style-sheet: any # The JSON Style sheet string
]: any -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/StyleSheet"))
  let req_body = {"StyleSheet": $style_sheet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/Tasks
#
# operationId: ListUnderstandTask
export def "understand-assistants-tasks list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /understand/Assistants/{AssistantSid}/Tasks
#
# operationId: CreateUnderstandTask
export def "understand-assistants-tasks create" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # A user-provided JSON object encoded as a string to specify the actions for this task. It is optional and non-unique.
  --actions-url: string # User-provided HTTP endpoint where from the assistant fetches actions (format: uri)
  --friendly-name: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  unique_name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks"))
  let req_body = {"Actions": $actions, "ActionsUrl": $actions_url, "FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: DeleteUnderstandTask
export def "understand-assistants-tasks delete" [
  assistant_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: FetchUnderstandTask
export def "understand-assistants-tasks get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: UpdateUnderstandTask
export def "understand-assistants-tasks update" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # A user-provided JSON object encoded as a string to specify the actions for this task. It is optional and non-unique.
  --actions-url: string # User-provided HTTP endpoint where from the assistant fetches actions (format: uri)
  --friendly-name: string # A user-provided string that identifies this resource. It is non-unique and can up to 255 characters long.
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{sid}"))
  let req_body = {"Actions": $actions, "ActionsUrl": $actions_url, "FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Returns JSON actions for this Task.
#
# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# operationId: FetchUnderstandTaskActions
export def "understand-assistants-tasks-actions get" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Actions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the actions of an Task identified by {TaskSid} or {TaskUniqueName}.
#
# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# operationId: UpdateUnderstandTaskActions
export def "understand-assistants-tasks-actions update" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # The JSON actions that instruct the Assistant how to perform this task.
]: any -> record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Actions"))
  let req_body = {"Actions": $actions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# operationId: ListUnderstandField
export def "understand-assistants-tasks-fields list" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<fields: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# operationId: CreateUnderstandField
export def "understand-assistants-tasks-fields create" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  field_type: string # The unique name or sid of the FieldType. It can be any [Built-in Field Type](https://www.twilio.com/docs/assistant/api/built-in-field-types) or the unique_name or the Field Type sid of a custom Field Type.
  unique_name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Fields"))
  let req_body = {"FieldType": $field_type, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# operationId: DeleteUnderstandField
export def "understand-assistants-tasks-fields delete" [
  assistant_sid: string
  task_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Fields/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# operationId: FetchUnderstandField
export def "understand-assistants-tasks-fields get" [
  assistant_sid: string
  task_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Fields/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# operationId: ListUnderstandSample
export def "understand-assistants-tasks-samples list" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # An ISO language-country string of the sample.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, samples: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  let qp = [(serialize-qp "Language" $language "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Language": $language, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# operationId: CreateUnderstandSample
export def "understand-assistants-tasks-samples create" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string # An ISO language-country string of the sample.
  --source-channel: string # The communication channel the sample was captured. It can be: *voice*, *sms*, *chat*, *alexa*, *google-assistant*, or *slack*. If not included the value will be null
  tagged_text: string # The text example of how end-users may express this task. The sample may contain Field tag blocks.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples"))
  let req_body = {"Language": $language, "SourceChannel": $source_channel, "TaggedText": $tagged_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: DeleteUnderstandSample
export def "understand-assistants-tasks-samples delete" [
  assistant_sid: string
  task_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: FetchUnderstandSample
export def "understand-assistants-tasks-samples get" [
  assistant_sid: string
  task_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: UpdateUnderstandSample
export def "understand-assistants-tasks-samples update" [
  assistant_sid: string
  task_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # An ISO language-country string of the sample.
  --source-channel: string # The communication channel the sample was captured. It can be: *voice*, *sms*, *chat*, *alexa*, *google-assistant*, or *slack*. If not included the value will be null
  --tagged-text: string # The text example of how end-users may express this task. The sample may contain Field tag blocks.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid), sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples/{sid}"))
  let req_body = {"Language": $language, "SourceChannel": $source_channel, "TaggedText": $tagged_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /understand/Assistants/{AssistantSid}/Tasks/{TaskSid}/Statistics
#
# operationId: FetchUnderstandTaskStatistics
export def "understand-assistants-tasks-statistics get" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, fields_count: int, samples_count: int, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($assistant_sid | is-empty) { error make --unspanned { msg: "path parameter 'AssistantSid' must be non-empty" } }
  if ($task_sid | is-empty) { error make --unspanned { msg: "path parameter 'TaskSid' must be non-empty" } }
  let full_url = (build-url $base ({assistant_sid: (encode-path-segment $assistant_sid), task_sid: (encode-path-segment $task_sid)} | format pattern "/understand/Assistants/{assistant_sid}/Tasks/{task_sid}/Statistics"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /understand/Assistants/{Sid}
#
# operationId: DeleteUnderstandAssistant
export def "understand-assistants delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /understand/Assistants/{Sid}
#
# operationId: FetchUnderstandAssistant
export def "understand-assistants get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /understand/Assistants/{Sid}
#
# operationId: UpdateUnderstandAssistant
export def "understand-assistants update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-events: string # Space-separated list of callback events that will trigger callbacks.
  --callback-url: string # A user-provided URL to send event callbacks to. (format: uri)
  --fallback-actions: any # The JSON actions to be executed when the user's input is not recognized as matching any Task.
  --friendly-name: string # A text description for the Assistant. It is non-unique and can up to 255 characters long.
  --initiation-actions: any # The JSON actions to be executed on inbound phone calls when the Assistant has to say something first.
  --log-queries: oneof<nothing, bool> # A boolean that specifies whether queries should be logged for 30 days further training. If false, no queries will be stored, if true, queries will be stored for 30 days and deleted thereafter. Defaults to true if no value is provided.
  --style-sheet: any # The JSON object that holds the style sheet for the assistant
  --unique-name: string # A user-provided string that uniquely identifies this resource as an alternative to the sid. Unique up to 64 characters long.
]: any -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/understand/Assistants/{sid}"))
  let req_body = {"CallbackEvents": $callback_events, "CallbackUrl": $callback_url, "FallbackActions": $fallback_actions, "FriendlyName": $friendly_name, "InitiationActions": $initiation_actions, "LogQueries": $log_queries, "StyleSheet": $style_sheet, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /wireless/Commands
#
# operationId: ListWirelessCommand
export def "wireless-commands list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string
  --sim: string
  --status: string
  --direction: string
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<commands: table<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Device" $device "scalar") (serialize-qp "Sim" $sim "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "Direction" $direction "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless/Commands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Device": $device, "Sim": $sim, "Status": $status, "Direction": $direction, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /wireless/Commands
#
# operationId: CreateWirelessCommand
export def "wireless-commands create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string
  --callback-url: string # format: uri
  command: string
  --command-mode: string
  --device: string
  --include-sid: string
  --sim: string
]: any -> record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/wireless/Commands")
  let req_body = {"CallbackMethod": $callback_method, "CallbackUrl": $callback_url, "Command": $command, "CommandMode": $command_mode, "Device": $device, "IncludeSid": $include_sid, "Sim": $sim} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /wireless/Commands/{Sid}
#
# operationId: FetchWirelessCommand
export def "wireless-commands get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, device_sid: string, direction: string, sid: string, sim_sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/wireless/Commands/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /wireless/RatePlans
#
# operationId: ListWirelessRatePlan
export def "wireless-rate-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rate_plans: table<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless/RatePlans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# POST /wireless/RatePlans
#
# operationId: CreateWirelessRatePlan
export def "wireless-rate-plans create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --commands-enabled: oneof<nothing, bool>
  --data-enabled: oneof<nothing, bool>
  --data-limit: int
  --data-metering: string
  --friendly-name: string
  --international-roaming: list<string>
  --messaging-enabled: oneof<nothing, bool>
  --national-roaming-enabled: oneof<nothing, bool>
  --unique-name: string
  --voice-enabled: oneof<nothing, bool>
]: any -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let full_url = (build-url $base "/wireless/RatePlans")
  let req_body = {"CommandsEnabled": $commands_enabled, "DataEnabled": $data_enabled, "DataLimit": $data_limit, "DataMetering": $data_metering, "FriendlyName": $friendly_name, "InternationalRoaming": $international_roaming, "MessagingEnabled": $messaging_enabled, "NationalRoamingEnabled": $national_roaming_enabled, "UniqueName": $unique_name, "VoiceEnabled": $voice_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# DELETE /wireless/RatePlans/{Sid}
#
# operationId: DeleteWirelessRatePlan
export def "wireless-rate-plans delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/wireless/RatePlans/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /wireless/RatePlans/{Sid}
#
# operationId: FetchWirelessRatePlan
export def "wireless-rate-plans get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/wireless/RatePlans/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /wireless/RatePlans/{Sid}
#
# operationId: UpdateWirelessRatePlan
export def "wireless-rate-plans update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string
  --unique-name: string
]: any -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, messaging_enabled: bool, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/wireless/RatePlans/{sid}"))
  let req_body = {"FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /wireless/Sims
#
# operationId: ListWirelessSim
export def "wireless-sims list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --iccid: string
  --rate-plan: string
  --e-id: string
  --sim-registration-code: string
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sims: table<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "Iccid" $iccid "scalar") (serialize-qp "RatePlan" $rate_plan "scalar") (serialize-qp "EId" $e_id "scalar") (serialize-qp "SimRegistrationCode" $sim_registration_code "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless/Sims" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Status": $status, "Iccid": $iccid, "RatePlan": $rate_plan, "EId": $e_id, "SimRegistrationCode": $sim_registration_code, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact), body: null}
}

# GET /wireless/Sims/{Sid}
#
# operationId: FetchWirelessSim
export def "wireless-sims get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/wireless/Sims/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /wireless/Sims/{Sid}
#
# operationId: UpdateWirelessSim
export def "wireless-sims update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string
  --callback-url: string # format: uri
  --commands-callback-method: string@commands-callback-method-completer # format: http-method
  --commands-callback-url: string # format: uri
  --friendly-name: string
  --rate-plan: string
  --sms-fallback-method: string@sms-fallback-method-completer # format: http-method
  --sms-fallback-url: string # format: uri
  --sms-method: string@sms-method-completer # format: http-method
  --sms-url: string # format: uri
  --status: string
  --unique-name: string
  --voice-fallback-method: string@voice-fallback-method-completer # format: http-method
  --voice-fallback-url: string # format: uri
  --voice-method: string@voice-method-completer # format: http-method
  --voice-url: string # format: uri
]: any -> record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, links: record, rate_plan_sid: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/wireless/Sims/{sid}"))
  let req_body = {"CallbackMethod": $callback_method, "CallbackUrl": $callback_url, "CommandsCallbackMethod": $commands_callback_method, "CommandsCallbackUrl": $commands_callback_url, "FriendlyName": $friendly_name, "RatePlan": $rate_plan, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsUrl": $sms_url, "Status": $status, "UniqueName": $unique_name, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceUrl": $voice_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# GET /wireless/Sims/{SimSid}/Usage
#
# operationId: FetchWirelessUsage
export def "wireless-sims-usage get" [
  sim_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end: string
  --start: string
]: nothing -> record<account_sid: string, commands_costs: any, commands_usage: any, data_costs: any, data_usage: any, period: any, sim_sid: string, sim_unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://preview.twilio.com")
  if ($sim_sid | is-empty) { error make --unspanned { msg: "path parameter 'SimSid' must be non-empty" } }
  let qp = [(serialize-qp "End" $end "scalar") (serialize-qp "Start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sim_sid: (encode-path-segment $sim_sid)} | format pattern "/wireless/Sims/{sim_sid}/Usage") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"End": $end, "Start": $start} | compact), body: null}
}
