# Auto-generated client for AGCO API vv1
# Source: https://api.apis.guru/v2/specs/agco-ats.com/v1/openapi.json
# Auth: --token flag or $env.AGCO_API_TOKEN

const BASE_URL = "https://secure.agco-ats.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AGCO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://secure.agco-ats.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def state-completer [] { ["Active" "Damaged" "Inactive"] }
def state-completer-1 [] { ["Active" "Inactive" "None"] }
def bearer-action-completer [] { ["Disable" "None" "Reset"] }
def mac-action-completer [] { ["Disable" "None" "Reset"] }
def duration-units-completer [] { ["Days" "Hours" "Minutes" "Weeks"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def state-completer-2 [] { ["Available" "Created" "Removed"] }
def license-activation-type-completer [] { ["EDT" "EDTLite"] }
def status-completer [] { ["Active" "All" "Inactive"] }
def subscription-type-completer [] { ["ExcludeByDefault" "IncludeByDefault" "Required"] }
def data-required-completer [] { ["No" "Optional" "Yes"] }
def status-completer-1 [] { ["Active" "All" "Completed"] }
def subscription-type-filter-completer [] { ["All" "Default" "RequiredOnly"] }
def state-completer-3 [] { ["CreatePending" "Invalidated" "Original" "Processed" "Processing" "RequestPending" "Requested" "Validated"] }
def state-completer-4 [] { ["Cancelled" "Completed" "NotSubmitted" "Submitted"] }
def state-completer-5 [] { ["Cancelled" "Completed" "OutForProcessing" "OutForTranslation" "PendingApproval" "Processing"] }
def type-completer [] { ["Commercial" "Internal" "RightToRepair" "Temporary"] }
def deleted-completer [] { ["All" "Deleted" "NotDeleted"] }
def status-completer-2 [] { ["Cancelled" "Failed" "InProgress" "Ready" "Succeeded"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "aftermarket-services-certificates get-certs" } } | get name | first)
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

# No Documentation Found.
#
# GET /api/v2/AftermarketServices/Certificates
# operationId: AftermarketServices_GetCerts
export def "aftermarket-services-certificates get-certs" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AftermarketServices/Certificates" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Activate or Deactivate an ECU, or Report an ECU as Damaged.
#
# PUT /api/v2/AftermarketServices/ECUs/{serialNumber}
# operationId: AftermarketServices_PutECU
export def "aftermarket-services-ec-us update-ecu" [
  serial_number: string
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
  --edt-instance-id: string # The EDT Instance Id of the kit calling this method.
  --activation-code: string # The code used to activate the ECU. May not be modified. Returned only on activation. (format: byte)
  --damaged-description: string # A description why the ECU cannot be deactivated.
  engine_serial_number: string # The serial number of the ECU’s engine
  --replaces-ecu-serial-number: string # The serial number of the ECU that this ECU replaces. Required if activating an ECU..
  --body-serial-number: string # The serial number of the ECU
  state: string@state-completer # The state of the ECU
]: any -> record<ActivationCode: string, DamagedDescription: string, EngineSerialNumber: string, ReplacesECUSerialNumber: string, SerialNumber: string, State: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serial_number | is-empty) { error make --unspanned { msg: "path parameter 'serialNumber' must be non-empty" } }
  let qp = [(serialize-qp "EDTInstanceId" $edt_instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial_number: (encode-path-segment $serial_number)} | format pattern "/api/v2/AftermarketServices/ECUs/{serial_number}") $qp $auth.query)
  let req_body = {"ActivationCode": $activation_code, "DamagedDescription": $damaged_description, "EngineSerialNumber": $engine_serial_number, "ReplacesECUSerialNumber": $replaces_ecu_serial_number, "SerialNumber": $body_serial_number, "State": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"EDTInstanceId": $edt_instance_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get injector codes given engine.
#
# GET /api/v2/AftermarketServices/Engines/{serialNumber}/IQACodes
# operationId: AftermarketServices_GetEngineIQACodes
export def "aftermarket-services-engines-iqa-codes get" [
  serial_number: string
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
  --edt-instance-id: string # The EDT Instance Id of the kit calling this method.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serial_number | is-empty) { error make --unspanned { msg: "path parameter 'serialNumber' must be non-empty" } }
  let qp = [(serialize-qp "EDTInstanceId" $edt_instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial_number: (encode-path-segment $serial_number)} | format pattern "/api/v2/AftermarketServices/Engines/{serial_number}/IQACodes") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EDTInstanceId": $edt_instance_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Report the IQA codes used by an engine
#
# PUT /api/v2/AftermarketServices/Engines/{serialNumber}/IQACodes
# operationId: AftermarketServices_PutIQACodes
export def "aftermarket-services-engines-iqa-codes update" [
  serial_number: string
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
  --edt-instance-id: string # The EDT Instance Id of the kit calling this method.
  --body: list
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serial_number | is-empty) { error make --unspanned { msg: "path parameter 'serialNumber' must be non-empty" } }
  let qp = [(serialize-qp "EDTInstanceId" $edt_instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial_number: (encode-path-segment $serial_number)} | format pattern "/api/v2/AftermarketServices/Engines/{serial_number}/IQACodes") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"EDTInstanceId": $edt_instance_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get production calibration data for given engine.
#
# GET /api/v2/AftermarketServices/Engines/{serialNumber}/ProductionData
# operationId: AftermarketServices_GetProductionData
export def "aftermarket-services-engines-production-data get" [
  serial_number: string
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
  --edt-instance-id: string # The EDT Instance Id of the kit calling this method.
]: nothing -> table<DataType: string, DataValues: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serial_number | is-empty) { error make --unspanned { msg: "path parameter 'serialNumber' must be non-empty" } }
  let qp = [(serialize-qp "EDTInstanceId" $edt_instance_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serial_number: (encode-path-segment $serial_number)} | format pattern "/api/v2/AftermarketServices/Engines/{serial_number}/ProductionData") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"EDTInstanceId": $edt_instance_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Check whether there is connectivity to AGCO Power Web Services
#
# GET /api/v2/AftermarketServices/Hello
# operationId: AftermarketServices_GetConnectionStatus
export def "aftermarket-services-hello get-connection-status" [
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
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AftermarketServices/Hello" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieve the status of an EDT Kit Registration with AGCO Power Web Services
#
# GET /api/v2/AftermarketServices/UserStatuses
# operationId: AftermarketServices_GetUserStatus
export def "aftermarket-services-user-statuses get-status" [
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
  --voucher-code: string
  --dealer-code: string
]: nothing -> record<DealerCode: string, State: string, VoucherCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "voucherCode" $voucher_code "scalar") (serialize-qp "dealerCode" $dealer_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AftermarketServices/UserStatuses" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"voucherCode": $voucher_code, "dealerCode": $dealer_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the status of an EDT Kit Registration with AGCO Power Web Services
#
# PUT /api/v2/AftermarketServices/UserStatuses
# operationId: AftermarketServices_UpdateUserStatus
export def "aftermarket-services-user-statuses update-status" [
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
  dealer_code: string # The dealer code of the voucher
  --state: string@state-completer-1 # The state of the voucher
  voucher_code: string # The voucher code
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AftermarketServices/UserStatuses" $auth.query)
  let req_body = {"DealerCode": $dealer_code, "State": $state, "VoucherCode": $voucher_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Manage API tokens.
#
# PUT /api/v2/AuthenticatedUsers/{UserID}/Tokens
# operationId: Authentication_PutManageTokens
export def "authenticated-users-tokens update-authentication-manage" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bearer-action: string@bearer-action-completer # The action to perform on the bearer token. Optional. Defaults to ‘None’.
  --mac-action: string@mac-action-completer # The action to perform on the MAC token. Optional. Defaults to ‘None’.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'UserID' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/api/v2/AuthenticatedUsers/{user_id}/Tokens") $auth.query)
  let req_body = {"BearerAction": $bearer_action, "MACAction": $mac_action} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Authenticate a user.
#
# POST /api/v2/Authentication
# operationId: Authentication_Default
export def "authentication create-default" [
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
  --bearer-action: string@bearer-action-completer # The action to perform on the bearer token. Optional. Defaults to ‘None’.
  --mac-action: string@mac-action-completer # The action to perform on the MAC token. Optional. Defaults to ‘None’.
  password: string # A secret word or phrase that must be used to gain admission
  username: string # A unique ID a user needs to login with
]: any -> record<Email: string, MACId: string, MACToken: string, Name: string, Token: string, UserID: int, Username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Authentication" $auth.query)
  let req_body = {"BearerAction": $bearer_action, "MACAction": $mac_action, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Acknowledges the connection to the API
#
# GET /api/v2/Authentication/IsAlive
# operationId: Authentication_IsAlive
export def "authentication-is-alive get" [
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
  let full_url = (build-url $base "/api/v2/Authentication/IsAlive" $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# Request a password reset.
#
# POST /api/v2/Authentication/RequestPasswordReset
# operationId: Authentication_RequestPasswordReset
export def "authentication-request-password-reset request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  parameter_name: string # The query string parameter name to use for supplying the password reset token
  url: string # The URL to direct the user to reset the password.
  username: string # The username to reset the password for
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Authentication/RequestPasswordReset" $auth.query)
  let req_body = {"ParameterName": $parameter_name, "Url": $url, "Username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Reset a password
#
# POST /api/v2/Authentication/ResetPasword
# operationId: Authentication_ResetPasword
export def "authentication-reset-pasword reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string # The new password
  --body-token: string # The password reset token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Authentication/ResetPasword" $auth.query)
  let req_body = {"NewPassword": $new_password, "Token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get authorization categories.
#
# GET /api/v2/AuthorizationCategories
# operationId: AuthorizationCategories_Get
export def "authorization-categories get" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --user-id: int # Optional. Filter by categories visible to the provided user with the provided userID. (format: int32)
  --definition-id: string # Optional. Filter by categories containing a definition with the provided ID.
]: nothing -> record<Entities: table<Description: string, ID: string, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $user_id "scalar") (serialize-qp "definitionID" $definition_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationCategories" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "userID": $user_id, "definitionID": $definition_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add an authorization category.
#
# POST /api/v2/AuthorizationCategories
# operationId: AuthorizationCategories_Post
export def "authorization-categories create" [
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
  --description: string # A description of the Category.
  --id: string # The ID of the Category.
  --name: string # The Name of the Category.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AuthorizationCategories" $auth.query)
  let req_body = {"Description": $description, "ID": $id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Returns a report of access that users have to Authorization Categories.
#
# GET /api/v2/AuthorizationCategories/Users
# operationId: AuthorizationCategories_GetUsers
export def "authorization-categories-users get" [
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
  --limit: int # Optional. Defaults to 10. (format: int32)
  --offset: int # Optional. Defaults to 0. (format: int32)
  --user-i-ds: string # Optional. Includes only users with IDs on the provided comma-separated list.
  --category-i-ds: string # Optional. Includes only users with categories with IDs on the provided comma-separated list.
  --include-categories: oneof<nothing, bool> # If true, include full Authorization Category detail. Defaults to false.
  --include-users: oneof<nothing, bool> # If true, include full User detail. Defaults to false.
  --user-search: string # Optional. Includes only users with a Name, Username, or Email containing the provided value.
]: nothing -> record<Entities: table<Categories: list, User: record>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userIDs" $user_i_ds "scalar") (serialize-qp "categoryIDs" $category_i_ds "scalar") (serialize-qp "includeCategories" $include_categories "scalar") (serialize-qp "includeUsers" $include_users "scalar") (serialize-qp "userSearch" $user_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationCategories/Users" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "userIDs": $user_i_ds, "categoryIDs": $category_i_ds, "includeCategories": $include_categories, "includeUsers": $include_users, "userSearch": $user_search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove an authorization category.
#
# DELETE /api/v2/AuthorizationCategories/{id}
# operationId: AuthorizationCategories_Delete
export def "authorization-categories delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCategories/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update an authorization category.
#
# PUT /api/v2/AuthorizationCategories/{id}
# operationId: AuthorizationCategories_Put
export def "authorization-categories update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description of the Category.
  --body-id: string # The ID of the Category.
  --name: string # The Name of the Category.
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCategories/{id}") $auth.query)
  let req_body = {"Description": $description, "ID": $body_id, "Name": $name} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Deletes a category a user could see.
#
# DELETE /api/v2/AuthorizationCategories/{id}/Users/{userID}
# operationId: AuthorizationCategories_RemoveUser
export def "authorization-categories-users delete" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/api/v2/AuthorizationCategories/{id}/Users/{user_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Add a category that a user can see.
#
# POST /api/v2/AuthorizationCategories/{id}/Users/{userID}
# operationId: AuthorizationCategories_AddUser
export def "authorization-categories-users create" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/api/v2/AuthorizationCategories/{id}/Users/{user_id}") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Get authorization code definitions.
#
# GET /api/v2/AuthorizationCodeDefinitions
# operationId: AuthorizationCodeDefinitions_GetAuthorizationCodeDefinition
export def "authorization-code-definitions list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. If specified, filters definitions by name. Starting and ending wildcards (*) supported.
  --created-by-user-id: int # Optional. If specified, filters definitions to those created by the given User ID. (format: int32)
  --deleted-by-user-id: int # Optional. If specified, filters definitions to those deleted by the given User ID. (format: int32)
  --include-deleted: oneof<nothing, bool> # Optional. Whether to include deleted definitions. 'False' by default.
  --category-id: string # Optional. If specified, filters definitions with the designated categoryID.
]: nothing -> record<Entities: table<AuthorizationID: string, CreatedByUserID: int, CreatedDate: string, DataFields: list, DeletedByUserID: int, DeletedDate: string, Description: string, DurationAccuracy: int, DurationAmount: int, DurationUnits: string, HashLength: int, ID: string, IsDeleted: bool, Name: string, RandomLength: int, ValidationFields: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "createdByUserID" $created_by_user_id "scalar") (serialize-qp "deletedByUserID" $deleted_by_user_id "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar") (serialize-qp "categoryID" $category_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationCodeDefinitions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "name": $name, "createdByUserID": $created_by_user_id, "deletedByUserID": $deleted_by_user_id, "includeDeleted": $include_deleted, "categoryID": $category_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add an authorization code definition.
#
# POST /api/v2/AuthorizationCodeDefinitions
# operationId: AuthorizationCodeDefinitions_PostAuthorizationCodeDefinition
# --DataFields item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
# --ValidationFields item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
export def "authorization-code-definitions create" [
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
  --authorization-id: string # The value used for securing codes generated.
  --created-by-user-id: int # The ID of the user that created this definition. Read only. (format: int32)
  --created-date: string # A timestamp of when this definition was created. Read only. (format: date-time)
  --data-fields: list # The defined fields to include in authorization codes generated from this definition. May not be updated. — item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
  --deleted-by-user-id: int # The ID of the user that deleted this definition. Read only. (format: int32)
  --deleted-date: string # A timestamp of when this definition was deleted. Read only. (format: date-time)
  --description: string # A description of this definition. May not be updated.
  --duration-accuracy: int # The number of bits used for timestamp verification. Defaults to 5. May not be updated. (format: int32)
  --duration-amount: int # The amount of duration for the specified duration unit used to calculate the Authorization Code. Defaults to 1. May not be updated. (format: int32)
  --duration-units: string@duration-units-completer # The units of duration used to calculate the Authorization Code. Defaults to 'Days'. May not be updated.
  --hash-length: int # The bit length of the hash data which will be used for the authorization code. Defaults to 20. May not be updated. (format: int32)
  --id: string # The ID of the authorization code definition. Read only.
  --is-deleted: oneof<nothing, bool> # Indicates whether this definition is enabled. True if generating codes is disabled.
  name: string # The name of the authorization code definition. May not be updated.
  --random-length: int # The bit length of random data which will be included in the authorization code. This is necessary to allow creation of "identical" authorization codes containing the same timestamp. Defaults to 5. May not be updated. (format: int32)
  --validation-fields: list # The defined fields to verify when reading authorization codes generated from this definition. May not be updated. — item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AuthorizationCodeDefinitions" $auth.query)
  let req_body = {"AuthorizationID": $authorization_id, "CreatedByUserID": $created_by_user_id, "CreatedDate": $created_date, "DataFields": $data_fields, "DeletedByUserID": $deleted_by_user_id, "DeletedDate": $deleted_date, "Description": $description, "DurationAccuracy": $duration_accuracy, "DurationAmount": $duration_amount, "DurationUnits": $duration_units, "HashLength": $hash_length, "ID": $id, "IsDeleted": $is_deleted, "Name": $name, "RandomLength": $random_length, "ValidationFields": $validation_fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Deletes the category from the authorization code definition.
#
# DELETE /api/v2/AuthorizationCodeDefinitions/{ID}/Categories/{categoryID}
# operationId: AuthorizationCodeDefinitions_RemoveCategoryFromDefinition
export def "authorization-code-definitions-categories delete-category" [
  id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'categoryID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), category_id: (encode-path-segment $category_id)} | format pattern "/api/v2/AuthorizationCodeDefinitions/{id}/Categories/{category_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Add a category to an authorizationCodeDefintion.
#
# POST /api/v2/AuthorizationCodeDefinitions/{ID}/Categories/{categoryID}
# operationId: AuthorizationCodeDefinitions_AddCategoryToDefinition
export def "authorization-code-definitions-categories create-category" [
  id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'categoryID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), category_id: (encode-path-segment $category_id)} | format pattern "/api/v2/AuthorizationCodeDefinitions/{id}/Categories/{category_id}") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Disable an authorization code definition
#
# DELETE /api/v2/AuthorizationCodeDefinitions/{id}
# operationId: AuthorizationCodeDefinitions_DeleteAuthorizationCodeDefinition
export def "authorization-code-definitions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCodeDefinitions/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get an authorization code definition by its ID
#
# GET /api/v2/AuthorizationCodeDefinitions/{id}
export def "authorization-code-definitions get" [
  id: string
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
]: nothing -> record<AuthorizationID: string, CreatedByUserID: int, CreatedDate: string, DataFields: table<DigitsPrecision: int, MaxExponent: int, MaxValue: float, MinExponent: int, MinValue: float, Name: string, ScaleFactor: float, Signed: bool, Type: string>, DeletedByUserID: int, DeletedDate: string, Description: string, DurationAccuracy: int, DurationAmount: int, DurationUnits: string, HashLength: int, ID: string, IsDeleted: bool, Name: string, RandomLength: int, ValidationFields: table<Name: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCodeDefinitions/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update an authorization code definition
#
# PUT /api/v2/AuthorizationCodeDefinitions/{id}
# operationId: AuthorizationCodeDefinitions_PutAuthorizationCodeDefinition
# --DataFields item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
# --ValidationFields item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
export def "authorization-code-definitions update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization-id: string # The value used for securing codes generated.
  --created-by-user-id: int # The ID of the user that created this definition. Read only. (format: int32)
  --created-date: string # A timestamp of when this definition was created. Read only. (format: date-time)
  --data-fields: list # The defined fields to include in authorization codes generated from this definition. May not be updated. — item shape: {DigitsPrecision?: int, MaxExponent?: int, MaxValue?: float, MinExponent?: int, MinValue?: float, Name: string, ScaleFactor?: float, Signed?: bool, Type: "Boolean"|"Decimal"|"Float"|"VariableLengthByteArray"}
  --deleted-by-user-id: int # The ID of the user that deleted this definition. Read only. (format: int32)
  --deleted-date: string # A timestamp of when this definition was deleted. Read only. (format: date-time)
  --description: string # A description of this definition. May not be updated.
  --duration-accuracy: int # The number of bits used for timestamp verification. Defaults to 5. May not be updated. (format: int32)
  --duration-amount: int # The amount of duration for the specified duration unit used to calculate the Authorization Code. Defaults to 1. May not be updated. (format: int32)
  --duration-units: string@duration-units-completer # The units of duration used to calculate the Authorization Code. Defaults to 'Days'. May not be updated.
  --hash-length: int # The bit length of the hash data which will be used for the authorization code. Defaults to 20. May not be updated. (format: int32)
  --body-id: string # The ID of the authorization code definition. Read only.
  --is-deleted: oneof<nothing, bool> # Indicates whether this definition is enabled. True if generating codes is disabled.
  name: string # The name of the authorization code definition. May not be updated.
  --random-length: int # The bit length of random data which will be included in the authorization code. This is necessary to allow creation of "identical" authorization codes containing the same timestamp. Defaults to 5. May not be updated. (format: int32)
  --validation-fields: list # The defined fields to verify when reading authorization codes generated from this definition. May not be updated. — item shape: {Name: string, Type: "Boolean"|"Float"|"Int"|"StringCaseInsensitive"|"StringCaseSensitive"}
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCodeDefinitions/{id}") $auth.query)
  let req_body = {"AuthorizationID": $authorization_id, "CreatedByUserID": $created_by_user_id, "CreatedDate": $created_date, "DataFields": $data_fields, "DeletedByUserID": $deleted_by_user_id, "DeletedDate": $deleted_date, "Description": $description, "DurationAccuracy": $duration_accuracy, "DurationAmount": $duration_amount, "DurationUnits": $duration_units, "HashLength": $hash_length, "ID": $body_id, "IsDeleted": $is_deleted, "Name": $name, "RandomLength": $random_length, "ValidationFields": $validation_fields} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get authorization codes.
#
# GET /api/v2/AuthorizationCodes
# operationId: AuthorizationCodes_GetAuthorizationCodes
export def "authorization-codes list" [
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
  --code: string # Optional. If provided, searches for entities with the provided authorization code.
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --definition-id: string # Optional. If specified, filters codes by definition id.
  --created-by-user-id: int # Optional. If specified, filters codes to those created by the given User ID. (format: int32)
  --deleted-by-user-id: int # Optional. If specified, filters codes to those deleted by the given User ID. (format: int32)
  --include-deleted: oneof<nothing, bool> # Optional. Whether to include deleted codes. 'False' by default.
]: nothing -> record<Entities: table<Code: string, CreatedByUserID: int, CreatedDate: string, DataParameters: list, DefinitionID: string, DeletedByUserID: int, DeletedDate: string, EffectiveDate: string, ID: int, IsDeleted: bool, ValidationParameters: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "definitionID" $definition_id "scalar") (serialize-qp "createdByUserID" $created_by_user_id "scalar") (serialize-qp "deletedByUserID" $deleted_by_user_id "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationCodes" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"code": $code, "limit": $limit, "offset": $offset, "definitionID": $definition_id, "createdByUserID": $created_by_user_id, "deletedByUserID": $deleted_by_user_id, "includeDeleted": $include_deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Generates an authorization code using the provided definition and parameters.
#
# POST /api/v2/AuthorizationCodes
# operationId: AuthorizationCodes_PostAuthorizationCode
# --DataParameters item shape: {Name: string, Value: string}
# --ValidationParameters item shape: {Name: string, Value: string}
export def "authorization-codes create" [
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
  --code: string # The code to enter to unlock a feature. Read only.
  --created-by-user-id: int # The ID of the user that created this authorization code. Read only. (format: int32)
  --created-date: string # A timestamp of when this code was created. Read only. (format: date-time)
  --data-parameters: list # The parameters and values contained as data in this authorization code. May not be updated. — item shape: {Name: string, Value: string}
  --definition-id: string # The id of the definition for this authorization code. May not be updated.
  --deleted-by-user-id: int # The ID of the user that deleted this authorization code. Read only. (format: int32)
  --deleted-date: string # A timestamp of when this authorization code was deleted. Read only. (format: date-time)
  --effective-date: string # A date at which this code should begin being valid. Optional. Set on create only. (format: date-time)
  --id: int # The identifier for the authorization code. Read only. (format: int32)
  --is-deleted: oneof<nothing, bool> # Indicates whether this code is deleted.
  --validation-parameters: list # The parameters and values used to validate this authorization code. May not be updated. — item shape: {Name: string, Value: string}
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AuthorizationCodes" $auth.query)
  let req_body = {"Code": $code, "CreatedByUserID": $created_by_user_id, "CreatedDate": $created_date, "DataParameters": $data_parameters, "DefinitionID": $definition_id, "DeletedByUserID": $deleted_by_user_id, "DeletedDate": $deleted_date, "EffectiveDate": $effective_date, "ID": $id, "IsDeleted": $is_deleted, "ValidationParameters": $validation_parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Hide an authorization code.
#
# DELETE /api/v2/AuthorizationCodes/{id}
# operationId: AuthorizationCodes_DeleteAuthorizationCode
export def "authorization-codes delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCodes/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get an authorization code by its ID.
#
# GET /api/v2/AuthorizationCodes/{id}
# operationId: AuthorizationCodes_GetAuthorizationCode
export def "authorization-codes get" [
  id: int
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
]: nothing -> record<Code: string, CreatedByUserID: int, CreatedDate: string, DataParameters: table<Name: string, Value: string>, DefinitionID: string, DeletedByUserID: int, DeletedDate: string, EffectiveDate: string, ID: int, IsDeleted: bool, ValidationParameters: table<Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCodes/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update an authorization code.
#
# PUT /api/v2/AuthorizationCodes/{id}
# operationId: AuthorizationCodes_PutAuthorizationCode
# --DataParameters item shape: {Name: string, Value: string}
# --ValidationParameters item shape: {Name: string, Value: string}
export def "authorization-codes update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # The code to enter to unlock a feature. Read only.
  --created-by-user-id: int # The ID of the user that created this authorization code. Read only. (format: int32)
  --created-date: string # A timestamp of when this code was created. Read only. (format: date-time)
  --data-parameters: list # The parameters and values contained as data in this authorization code. May not be updated. — item shape: {Name: string, Value: string}
  --definition-id: string # The id of the definition for this authorization code. May not be updated.
  --deleted-by-user-id: int # The ID of the user that deleted this authorization code. Read only. (format: int32)
  --deleted-date: string # A timestamp of when this authorization code was deleted. Read only. (format: date-time)
  --effective-date: string # A date at which this code should begin being valid. Optional. Set on create only. (format: date-time)
  --body-id: int # The identifier for the authorization code. Read only. (format: int32)
  --is-deleted: oneof<nothing, bool> # Indicates whether this code is deleted.
  --validation-parameters: list # The parameters and values used to validate this authorization code. May not be updated. — item shape: {Name: string, Value: string}
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCodes/{id}") $auth.query)
  let req_body = {"Code": $code, "CreatedByUserID": $created_by_user_id, "CreatedDate": $created_date, "DataParameters": $data_parameters, "DefinitionID": $definition_id, "DeletedByUserID": $deleted_by_user_id, "DeletedDate": $deleted_date, "EffectiveDate": $effective_date, "ID": $body_id, "IsDeleted": $is_deleted, "ValidationParameters": $validation_parameters} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get contact information for an authorization code.
#
# GET /api/v2/AuthorizationCodes/{id}/ContactInformation
# operationId: AuthorizationCodes_GetContactInformation
export def "authorization-codes-contact-information get" [
  id: int
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
]: nothing -> record<AuthorizationCodeID: int, Code: string, Contact: string, CreatedBy: string, CreatedDate: string, DealerCode: string, Dealership: string, DefinitionName: string, Email: string, ID: int, Notes: string, Phone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCodes/{id}/ContactInformation") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# No Documentation Found.
#
# GET /api/v2/AuthorizationCodes/{id}/Validate
# operationId: AuthorizationCodes_ValidateAuthorizationCode
export def "authorization-codes-validate validate" [
  id: int
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
]: nothing -> record<ExpirationDate: string, IsValid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/AuthorizationCodes/{id}/Validate") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get contact information for authorization codes.
#
# GET /api/v2/AuthorizationContactInformation
# operationId: AuthorizationContactInformation_Get
export def "authorization-contact-information get" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --authorization-code: string # Optional. Search by authorization code.
  --after-date: string # Optional. Include only data for authorization codes created after a provided date. (format: date-time)
  --before-date: string # Optional. Include only data for authorization codes created before a provided date. (format: date-time)
  --dealer-code: string # Optional. Search by dealer code.
]: nothing -> record<Entities: table<AuthorizationCodeID: int, Code: string, Contact: string, CreatedBy: string, CreatedDate: string, DealerCode: string, Dealership: string, DefinitionName: string, Email: string, ID: int, Notes: string, Phone: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "authorizationCode" $authorization_code "scalar") (serialize-qp "afterDate" $after_date "scalar") (serialize-qp "beforeDate" $before_date "scalar") (serialize-qp "dealerCode" $dealer_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/AuthorizationContactInformation" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "authorizationCode": $authorization_code, "afterDate": $after_date, "beforeDate": $before_date, "dealerCode": $dealer_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add contact information for authorization code.
#
# POST /api/v2/AuthorizationContactInformation
# operationId: AuthorizationContactInformation_Post
export def "authorization-contact-information create" [
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
  authorization_code_id: int # AuthorizationCode ID that the contact information ties into. (format: int32)
  --code: string # The authorization code. Read Only.
  contact: string # Name of contact requesting an authorization code. Minimum length of 3 characters.
  --created-by: string # The name of the user that created this code. Read Only.
  --created-date: string # The date the authorization code was created. (format: date-time)
  dealer_code: string # Dealer code that relates to the dealership. Minimum length of 3 characters.
  dealership: string # Name of dealership. Minimum length of 3 characters.
  --definition-name: string # The name of the definition used for generating this authorization code. Read Only.
  --email: string # Email of contact.
  --id: int # ID of authorizationContactInformation (format: int32)
  --notes: string # Optional notes used for internal use.
  phone: string # Phone number of contact.
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/AuthorizationContactInformation" $auth.query)
  let req_body = {"AuthorizationCodeID": $authorization_code_id, "Code": $code, "Contact": $contact, "CreatedBy": $created_by, "CreatedDate": $created_date, "DealerCode": $dealer_code, "Dealership": $dealership, "DefinitionName": $definition_name, "Email": $email, "ID": $id, "Notes": $notes, "Phone": $phone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets a list of Brands.
#
# GET /api/v2/Brands
# operationId: Brands_Brands
export def "brands get" [
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
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Brands" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get the list of bundles.
#
# GET /api/v2/Bundles
# operationId: Bundles_GetBundles
export def "bundles list" [
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
  --update-group-id: string # Optional. Filter by UpdateGroup ID.
  --active: oneof<nothing, bool> # Optional. Filter by active status.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --bundle-number: int # Optional. If provided, filters by BundleNumber. (format: int32)
]: nothing -> record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "Active" $active "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "BundleNumber" $bundle_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Bundles" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdateGroupID": $update_group_id, "Active": $active, "limit": $limit, "offset": $offset, "BundleNumber": $bundle_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Bundle to the Update System.
#
# POST /api/v2/Bundles
# operationId: Bundles_PostBundle
export def "bundles create" [
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
  --active: oneof<nothing, bool> # Default Value: false. During the creation of the Bundle, this field must be false.
  --bundle-id: string # Read-Only.
  bundle_number: int # The bundle number (format: int32)
  description: string # The Bundle description.
  update_group_id: string # The update group this bundle belongs to.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Bundles" $auth.query)
  let req_body = {"Active": $active, "BundleID": $bundle_id, "BundleNumber": $bundle_number, "Description": $description, "UpdateGroupID": $update_group_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a Bundle.
#
# DELETE /api/v2/Bundles/{ID}
# operationId: Bundles_DeleteBundle
export def "bundles delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Bundles/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a specific Bundle by ID.
#
# GET /api/v2/Bundles/{ID}
# operationId: Bundles_GetBundle
export def "bundles get" [
  id: string
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
]: nothing -> record<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Bundles/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Modify a Bundle in the Update System.
#
# PUT /api/v2/Bundles/{ID}
# operationId: Bundles_PutBundle
export def "bundles update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Default Value: false. During the creation of the Bundle, this field must be false.
  --bundle-id: string # Read-Only.
  bundle_number: int # The bundle number (format: int32)
  description: string # The Bundle description.
  update_group_id: string # The update group this bundle belongs to.
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Bundles/{id}") $auth.query)
  let req_body = {"Active": $active, "BundleID": $bundle_id, "BundleNumber": $bundle_number, "Description": $description, "UpdateGroupID": $update_group_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a List of Clients in the Update System.
#
# GET /api/v2/Clients
# operationId: Clients_Get
export def "clients list" [
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
  --tag: string # Optional. Filter clients by Tag. Wildcards are supported (*).
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ClientID: string, LastCheckin: string, Tag: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Tag" $tag "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Clients" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Tag": $tag, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of Cached Files installed on the client Machine.
#
# GET /api/v2/Clients/{ClientID}/CachedFiles
# operationId: UpdateSystem_GetCachedFiles
export def "clients-cached-files update-system-get" [
  client_id: string
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
  --expired: oneof<nothing, bool> # Only Expired Files (true|false)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'ClientID' must be non-empty" } }
  let qp = [(serialize-qp "Expired" $expired "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/api/v2/Clients/{client_id}/CachedFiles") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Expired": $expired} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the package reports for a client.
#
# GET /api/v2/Clients/{ClientID}/PackageReports
# operationId: PackageReports_Default
export def "clients-package-reports get-default" [
  client_id: string
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
]: nothing -> table<Categories: list<record>, PackageDescription: string, PackageID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'ClientID' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/api/v2/Clients/{client_id}/PackageReports") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Submit a package report
#
# PUT /api/v2/Clients/{ClientID}/PackageReports
# --Categories item shape: {Values?: list, category: string}
export def "clients-package-reports update" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # The package report's categories. — item shape: {Values?: list, category: string}
  --package-description: string # Read Only. The package description
  --package-id: string # The PackageID.
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'ClientID' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/api/v2/Clients/{client_id}/PackageReports") $auth.query)
  let req_body = {"Categories": $categories, "PackageDescription": $package_description, "PackageID": $package_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Submit a batch of package reports
#
# PUT /api/v2/Clients/{ClientID}/PackageReports/Batch
# operationId: PackageReports_Batch
export def "clients-package-reports-batch update" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'ClientID' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/api/v2/Clients/{client_id}/PackageReports/Batch") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a Client in the Update System.
#
# GET /api/v2/Clients/{ID}
export def "clients get" [
  id: string
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
]: nothing -> record<ClientID: string, LastCheckin: string, Tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Clients/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a Client.
#
# PUT /api/v2/Clients/{ID}
# operationId: Clients_Put
export def "clients update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Read Only. The id of the client
  --last-checkin: string # Read Only. The time of the client's last checkin with the server. (format: date-time)
  --tag: string # A description of the client that can be used for easy reference
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Clients/{id}") $auth.query)
  let req_body = {"ClientID": $client_id, "LastCheckin": $last_checkin, "Tag": $tag} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a Client's Available Update Group Subscriptions
#
# GET /api/v2/Clients/{ID}/AvailableUpdateGroupSubscriptions
# operationId: Clients_GetAvailableSubscriptions
export def "clients-available-update-group-subscriptions get" [
  id: string
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
  --update-group-id: string # Optional. Filter by Update Group.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<AvailableSubscriptions: list, UpdateGroup: record>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Clients/{id}/AvailableUpdateGroupSubscriptions") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdateGroupID": $update_group_id, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Client's Current Update Group Subscriptions
#
# GET /api/v2/Clients/{ID}/UpdateGroupSubscriptions
# operationId: Clients_GetSubscriptions
export def "clients-update-group-subscriptions get" [
  id: string
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
  --update-group-id: string # Optional. Filter by Update Group.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Clients/{id}/UpdateGroupSubscriptions") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdateGroupID": $update_group_id, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# No Documentation Found.
#
# PUT /api/v2/ContentDefinitionAttributes/Batch
# operationId: ContentDefinitions_PutContentDefinitionAttributes
export def "content-definition-attributes-batch update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentDefinitionAttributes/Batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove an Attribute from a ContentDefinition
#
# DELETE /api/v2/ContentDefinitionAttributes/{contentDefinitionAttributeID}
# operationId: ContentDefinitions_DeleteContentDefinitionAttribute
export def "content-definition-attributes delete" [
  content_definition_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_definition_attribute_id | is-empty) { error make --unspanned { msg: "path parameter 'contentDefinitionAttributeID' must be non-empty" } }
  let full_url = (build-url $base ({content_definition_attribute_id: (encode-path-segment $content_definition_attribute_id)} | format pattern "/api/v2/ContentDefinitionAttributes/{content_definition_attribute_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update an Attribute for a ContentDefinition
#
# PUT /api/v2/ContentDefinitionAttributes/{contentDefinitionAttributeID}
# operationId: ContentDefinitions_PutContentDefinitionAttributeAsync
export def "content-definition-attributes update-async" [
  content_definition_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-definition-id: int # The ID of the content definition to which this attribute belongs. (format: int32)
  --id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --value: string # The value of this Attribute
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_definition_attribute_id | is-empty) { error make --unspanned { msg: "path parameter 'contentDefinitionAttributeID' must be non-empty" } }
  let full_url = (build-url $base ({content_definition_attribute_id: (encode-path-segment $content_definition_attribute_id)} | format pattern "/api/v2/ContentDefinitionAttributes/{content_definition_attribute_id}") $auth.query)
  let req_body = {"ContentDefinitionID": $content_definition_id, "ID": $id, "Name": $name, "Value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get ContentDefinitions
#
# GET /api/v2/ContentDefinitions
# operationId: ContentDefinitions_GetContentDefinitions
export def "content-definitions list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --user-id: int # Optional. Filter by UserID. (format: int32)
  --include-attributes: string # Names of Attributes to include when retrieving this definition. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
  --name: string # Optional. Filter by Name. Supports beginning and ending wildcard (*).
  --type-id: int # Optional. Filter by TypeID. (format: int32)
  --package-type-id: string # Optional. Filter by PackageTypeID.
]: nothing -> record<Entities: table<Attributes: list, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $user_id "scalar") (serialize-qp "includeAttributes" $include_attributes "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "typeID" $type_id "scalar") (serialize-qp "packageTypeID" $package_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ContentDefinitions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "userID": $user_id, "includeAttributes": $include_attributes, "name": $name, "typeID": $type_id, "packageTypeID": $package_type_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a ContentDefinition
#
# POST /api/v2/ContentDefinitions
# operationId: ContentDefinitions_PostContentDefinition
# --Attributes item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
export def "content-definitions create" [
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
  --attributes: list # Attributes of this ContentDefinition — item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
  --content-definition-id: int # The ID of this content definition. (format: int32)
  description: string # The description used on the package type in the AGCO Update System
  --name: string # The name of this content. Name must be valid for Attribute on PackageType.
  --package-type-id: string # Read Only. The ID of the package type used for this content.
  --type-id: int # The type of content. (format: int32)
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentDefinitions" $auth.query)
  let req_body = {"Attributes": $attributes, "ContentDefinitionID": $content_definition_id, "Description": $description, "Name": $name, "PackageTypeID": $package_type_id, "TypeID": $type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a ContentDefinition
#
# DELETE /api/v2/ContentDefinitions/{contentDefinitionID}
# operationId: ContentDefinitions_DeleteContentDefinition
export def "content-definitions delete" [
  content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'contentDefinitionID' must be non-empty" } }
  let full_url = (build-url $base ({content_definition_id: (encode-path-segment $content_definition_id)} | format pattern "/api/v2/ContentDefinitions/{content_definition_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a ContentDefinition by ID
#
# GET /api/v2/ContentDefinitions/{contentDefinitionID}
# operationId: ContentDefinitions_GetContentDefinition
export def "content-definitions get" [
  content_definition_id: int
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
  --include-attributes: string # Names of Attributes to include when retrieving this definition. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> record<Attributes: table<ContentDefinitionID: int, ID: int, Name: string, Value: string>, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'contentDefinitionID' must be non-empty" } }
  let qp = [(serialize-qp "includeAttributes" $include_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_definition_id: (encode-path-segment $content_definition_id)} | format pattern "/api/v2/ContentDefinitions/{content_definition_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeAttributes": $include_attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a ContentDefinition
#
# PUT /api/v2/ContentDefinitions/{contentDefinitionID}
# operationId: ContentDefinitions_PutContentDefinition
# --Attributes item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
export def "content-definitions update" [
  content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Attributes of this ContentDefinition — item shape: {ContentDefinitionID?: int, ID?: int, Name: string, Value?: string}
  --body-content-definition-id: int # The ID of this content definition. (format: int32)
  description: string # The description used on the package type in the AGCO Update System
  --name: string # The name of this content. Name must be valid for Attribute on PackageType.
  --package-type-id: string # Read Only. The ID of the package type used for this content.
  --type-id: int # The type of content. (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'contentDefinitionID' must be non-empty" } }
  let full_url = (build-url $base ({content_definition_id: (encode-path-segment $content_definition_id)} | format pattern "/api/v2/ContentDefinitions/{content_definition_id}") $auth.query)
  let req_body = {"Attributes": $attributes, "ContentDefinitionID": $body_content_definition_id, "Description": $description, "Name": $name, "PackageTypeID": $package_type_id, "TypeID": $type_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Attributes for a ContentDefinition
#
# GET /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes
# operationId: ContentDefinitions_GetContentDefinitionAttributes
export def "content-definitions-attributes get" [
  content_definition_id: int
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. Filter the attributes by Name.
]: nothing -> record<Entities: table<ContentDefinitionID: int, ID: int, Name: string, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'contentDefinitionID' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_definition_id: (encode-path-segment $content_definition_id)} | format pattern "/api/v2/ContentDefinitions/{content_definition_id}/Attributes") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add an Attribute to a ContentDefinition
#
# POST /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes
# operationId: ContentDefinitions_PostContentDefinitionAttribute
export def "content-definitions-attributes create" [
  content_definition_id: int
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
  --body-content-definition-id: int # The ID of the content definition to which this attribute belongs. (format: int32)
  --id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --value: string # The value of this Attribute
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'contentDefinitionID' must be non-empty" } }
  let full_url = (build-url $base ({content_definition_id: (encode-path-segment $content_definition_id)} | format pattern "/api/v2/ContentDefinitions/{content_definition_id}/Attributes") $auth.query)
  let req_body = {"ContentDefinitionID": $body_content_definition_id, "ID": $id, "Name": $name, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# No Documentation Found.
#
# POST /api/v2/ContentDefinitions/{contentDefinitionID}/Attributes/Batch
# operationId: ContentDefinitions_PostContentDefinitionAttributes
export def "content-definitions-attributes-batch create" [
  content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'contentDefinitionID' must be non-empty" } }
  let full_url = (build-url $base ({content_definition_id: (encode-path-segment $content_definition_id)} | format pattern "/api/v2/ContentDefinitions/{content_definition_id}/Attributes/Batch") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get ContentReleaseVersion
#
# GET /api/v2/ContentReleases
# operationId: ContentRelease_GetContentReleaseVersion
export def "content-releases get-version" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --deleted: oneof<nothing, bool> # Optional. Filter by deleted.
  --release-id: int # Optional. Filter by releaseID. (format: int32)
  --user-id: int # Optional. Filter by UserID. (format: int32)
  --content-definition-id: int # Optional. Filter by ContentDefinitionID. (format: int32)
  --version: int # Optional. Filter by Version. (format: int32)
]: nothing -> record<Entities: table<ContentDefinitionID: int, ContentReleaseID: int, Deleted: bool, PublisherUserID: int, ReleaseID: int, TestReportUrl: string, UpdatedDate: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "releaseID" $release_id "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "contentDefinitionID" $content_definition_id "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ContentReleases" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "deleted": $deleted, "releaseID": $release_id, "userId": $user_id, "contentDefinitionID": $content_definition_id, "version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a ContentReleaseVersion
#
# POST /api/v2/ContentReleases
# operationId: ContentRelease_PostContentRelease
export def "content-releases create" [
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
  --content-definition-id: int # ContentDefinitionID (format: int32)
  --content-release-id: int # ContentReleaseID (format: int32)
  --deleted: oneof<nothing, bool> # deleted flag
  --publisher-user-id: int # PublisherUser ID (format: int32)
  --release-id: int # rele4ase Id (format: int32)
  --test-report-url: string # The URL at which test reports for this content can be found
  --updated-date: string # Updated Date (format: date-time)
  --version: int # version (format: int32)
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentReleases" $auth.query)
  let req_body = {"ContentDefinitionID": $content_definition_id, "ContentReleaseID": $content_release_id, "Deleted": $deleted, "PublisherUserID": $publisher_user_id, "ReleaseID": $release_id, "TestReportUrl": $test_report_url, "UpdatedDate": $updated_date, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a ContentReleaseVersion
#
# DELETE /api/v2/ContentReleases/{ContentReleaseId}
# operationId: ContentRelease_DeleteContentReleaseVersionn
export def "content-releases delete-versionn" [
  content_release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_release_id | is-empty) { error make --unspanned { msg: "path parameter 'ContentReleaseId' must be non-empty" } }
  let full_url = (build-url $base ({content_release_id: (encode-path-segment $content_release_id)} | format pattern "/api/v2/ContentReleases/{content_release_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a Content Release Version by ID
#
# GET /api/v2/ContentReleases/{ContentReleaseId}
export def "content-releases get" [
  content_release_id: int
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
]: nothing -> record<ContentDefinitionID: int, ContentReleaseID: int, Deleted: bool, PublisherUserID: int, ReleaseID: int, TestReportUrl: string, UpdatedDate: string, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_release_id | is-empty) { error make --unspanned { msg: "path parameter 'ContentReleaseId' must be non-empty" } }
  let full_url = (build-url $base ({content_release_id: (encode-path-segment $content_release_id)} | format pattern "/api/v2/ContentReleases/{content_release_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a ContentReleaseVersion
#
# PUT /api/v2/ContentReleases/{ContentReleaseId}
# operationId: ContentRelease_PutContentDefinition
export def "content-releases update-definition" [
  content_release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-definition-id: int # ContentDefinitionID (format: int32)
  --body-content-release-id: int # ContentReleaseID (format: int32)
  --deleted: oneof<nothing, bool> # deleted flag
  --publisher-user-id: int # PublisherUser ID (format: int32)
  --release-id: int # rele4ase Id (format: int32)
  --test-report-url: string # The URL at which test reports for this content can be found
  --updated-date: string # Updated Date (format: date-time)
  --version: int # version (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_release_id | is-empty) { error make --unspanned { msg: "path parameter 'ContentReleaseId' must be non-empty" } }
  let full_url = (build-url $base ({content_release_id: (encode-path-segment $content_release_id)} | format pattern "/api/v2/ContentReleases/{content_release_id}") $auth.query)
  let req_body = {"ContentDefinitionID": $content_definition_id, "ContentReleaseID": $body_content_release_id, "Deleted": $deleted, "PublisherUserID": $publisher_user_id, "ReleaseID": $release_id, "TestReportUrl": $test_report_url, "UpdatedDate": $updated_date, "Version": $version} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# No Documentation Found.
#
# PUT /api/v2/ContentSubmissionAttributes/Batch
# operationId: ContentSubmissions_PutContentSubmissionAttributes
export def "content-submission-attributes-batch update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentSubmissionAttributes/Batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove an Attribute from a ContentSubmission
#
# DELETE /api/v2/ContentSubmissionAttributes/{contentSubmissionAttributeID}
# operationId: ContentSubmissions_DeleteContentSubmissionAttribute
export def "content-submission-attributes delete" [
  content_submission_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_attribute_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionAttributeID' must be non-empty" } }
  let full_url = (build-url $base ({content_submission_attribute_id: (encode-path-segment $content_submission_attribute_id)} | format pattern "/api/v2/ContentSubmissionAttributes/{content_submission_attribute_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update an Attribute for a ContentSubmission
#
# PUT /api/v2/ContentSubmissionAttributes/{contentSubmissionAttributeID}
# operationId: ContentSubmissions_PutContentSubmissionAttributeAsync
export def "content-submission-attributes update-async" [
  content_submission_attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-submission-id: int # The ID of the content submission to which this attribute belongs. (format: int32)
  --id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --value: string # The value of this Attribute
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_attribute_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionAttributeID' must be non-empty" } }
  let full_url = (build-url $base ({content_submission_attribute_id: (encode-path-segment $content_submission_attribute_id)} | format pattern "/api/v2/ContentSubmissionAttributes/{content_submission_attribute_id}") $auth.query)
  let req_body = {"ContentSubmissionID": $content_submission_id, "ID": $id, "Name": $name, "Value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns available Content Submission Types.
#
# GET /api/v2/ContentSubmissionTypes
# operationId: ContentSubmissionTypes_GetContentSubmissionTypes
export def "content-submission-types list" [
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
  --enabled: oneof<nothing, bool>
]: nothing -> table<AttributeTemplate: string, BuildDefinitionID: int, CategoryTemplate: string, Description: string, Enabled: bool, ID: int, InventoryPackageID: string, JobID: int, Name: string, ReleaseNotesDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ContentSubmissionTypes" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"enabled": $enabled} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Content Submission Type
#
# POST /api/v2/ContentSubmissionTypes
# operationId: ContentSubmissionTypes_PostContentSubmissionType
export def "content-submission-types create" [
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
  --attribute-template: string # A template for the Attribute from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  --build-definition-id: int # The ID of the Azure DevOps Build Definition for which to create a Build. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  --category-template: string # A template for the category from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  description: string # A description for the Content Submission Type
  --enabled: oneof<nothing, bool> # Indicates whether this submission type is available to be used
  --id: int # The ID of the Content Submission Type (format: int32)
  --inventory-package-id: string # The ID of the Inventory Package from which to read the version of the package installed.
  --job-id: int # The ID of the JobDefinition for which to initiate a Job. A value of '0' will cause a submission to fail. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  name: string # The Name of the Content Submission Type
  --release-notes-description: string # A description of how release notes for this Content Submission Type are used
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentSubmissionTypes" $auth.query)
  let req_body = {"AttributeTemplate": $attribute_template, "BuildDefinitionID": $build_definition_id, "CategoryTemplate": $category_template, "Description": $description, "Enabled": $enabled, "ID": $id, "InventoryPackageID": $inventory_package_id, "JobID": $job_id, "Name": $name, "ReleaseNotesDescription": $release_notes_description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Remove a Content Submission Type
#
# DELETE /api/v2/ContentSubmissionTypes/{id}
# operationId: ContentSubmissionTypes_DeleteContentSubmissionType
export def "content-submission-types delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/ContentSubmissionTypes/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieves a Content Submission Type by its ID.
#
# GET /api/v2/ContentSubmissionTypes/{id}
# operationId: ContentSubmissionTypes_GetContentSubmissionType
export def "content-submission-types get" [
  id: int
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
]: nothing -> record<AttributeTemplate: string, BuildDefinitionID: int, CategoryTemplate: string, Description: string, Enabled: bool, ID: int, InventoryPackageID: string, JobID: int, Name: string, ReleaseNotesDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/ContentSubmissionTypes/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a Content Submission Type
#
# PUT /api/v2/ContentSubmissionTypes/{id}
# operationId: ContentSubmissionTypes_PutContentSubmissionType
export def "content-submission-types update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-template: string # A template for the Attribute from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  --build-definition-id: int # The ID of the Azure DevOps Build Definition for which to create a Build. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  --category-template: string # A template for the category from which to read the version of the package installed. The following placeholders are valid: {ContentDefinitionType}, {ContentDefinitionID}, {ContentDefinitionName}
  description: string # A description for the Content Submission Type
  --enabled: oneof<nothing, bool> # Indicates whether this submission type is available to be used
  --body-id: int # The ID of the Content Submission Type (format: int32)
  --inventory-package-id: string # The ID of the Inventory Package from which to read the version of the package installed.
  --job-id: int # The ID of the JobDefinition for which to initiate a Job. A value of '0' will cause a submission to fail. Either 'BuildDefinitionID' or 'JobID' is required. (format: int32)
  name: string # The Name of the Content Submission Type
  --release-notes-description: string # A description of how release notes for this Content Submission Type are used
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/ContentSubmissionTypes/{id}") $auth.query)
  let req_body = {"AttributeTemplate": $attribute_template, "BuildDefinitionID": $build_definition_id, "CategoryTemplate": $category_template, "Description": $description, "Enabled": $enabled, "ID": $body_id, "InventoryPackageID": $inventory_package_id, "JobID": $job_id, "Name": $name, "ReleaseNotesDescription": $release_notes_description} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get ContentSubmissions
#
# GET /api/v2/ContentSubmissions
# operationId: ContentSubmissions_GetContentSubmissions
export def "content-submissions list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --user-id: int # Optional. Filter by UserID. (format: int32)
  --content-definition-id: int # Optional. Filter by ContentDefinitionID (format: int32)
  --include-attributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
  --release-id: int # Optional. Filter the submissions by whether they are part of the Release with the specified Release ID. (format: int32)
  --type-id: int # Optional. Filter submissions by their ContentDefinition's Type ID. (format: int32)
  --version: int # Optional. Filter submissions by their Version. (format: int32)
  --include-definition: oneof<nothing, bool> # Optional. If true, includes the ContentDefinition for each submission.
]: nothing -> record<Entities: table<Attributes: list, BuildID: int, ContentDefinitionID: int, ContentSubmissionID: int, Definition: record, JobRunID: int, PackageID: string, ReleaseNotes: string, Repository: string, Revision: int, SubmissionDate: string, UserID: int, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $user_id "scalar") (serialize-qp "contentDefinitionID" $content_definition_id "scalar") (serialize-qp "includeAttributes" $include_attributes "scalar") (serialize-qp "releaseID" $release_id "scalar") (serialize-qp "typeID" $type_id "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "includeDefinition" $include_definition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ContentSubmissions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "userID": $user_id, "contentDefinitionID": $content_definition_id, "includeAttributes": $include_attributes, "releaseID": $release_id, "typeID": $type_id, "version": $version, "includeDefinition": $include_definition} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a ContentSubmission
#
# POST /api/v2/ContentSubmissions
# operationId: ContentSubmissions_PostContentSubmission
# --Attributes item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
# --Definition shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
export def "content-submissions create" [
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
  --attributes: list # Attributes of this ContentSubmission — item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
  --build-id: int # ReadOnly. The ID of the Azure DevOps Build which will build the content package. (format: int32)
  --content-definition-id: int # The ID of the Content Definition. (format: int32)
  --content-submission-id: int # The ID of this Content Submission. (format: int32)
  --definition: record # The definition of the content for submission — shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
  --job-run-id: int # ReadOnly. The ID of the JobRun which will build the content package. (format: int32)
  --package-id: string # The ID of package generated by this content submission.
  --release-notes: string # Release Notes for this ContentSubmission
  --repository: string # The SVN repository used as the source of this content submission
  --revision: int # The SVN revision used as the source of this content submission. (format: int32)
  --submission-date: string # Read Only. The UTC date and time the content submission was made. (format: date-time)
  --user-id: int # Read Only. The ID of the user who submitted the content (format: int32)
  --version: int # Optional. The version number assigned to this Content Submission and the resulting Package. If not provided, version shall be 1 if it is the first content submission for the ContentDefinitionID otherwise it shall be the highest content submission version for the specified ContentDefinitionID incremented by 1. (format: int32)
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/ContentSubmissions" $auth.query)
  let req_body = {"Attributes": $attributes, "BuildID": $build_id, "ContentDefinitionID": $content_definition_id, "ContentSubmissionID": $content_submission_id, "Definition": $definition, "JobRunID": $job_run_id, "PackageID": $package_id, "ReleaseNotes": $release_notes, "Repository": $repository, "Revision": $revision, "SubmissionDate": $submission_date, "UserID": $user_id, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a ContentSubmission
#
# DELETE /api/v2/ContentSubmissions/{contentSubmissionID}
# operationId: ContentSubmissions_DeleteContentSubmission
export def "content-submissions delete" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionID' must be non-empty" } }
  let full_url = (build-url $base ({content_submission_id: (encode-path-segment $content_submission_id)} | format pattern "/api/v2/ContentSubmissions/{content_submission_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a ContentSubmission by ID
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}
# operationId: ContentSubmissions_GetContentSubmission
export def "content-submissions get" [
  content_submission_id: int
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
  --include-attributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list.
]: nothing -> record<Attributes: table<ContentSubmissionID: int, ID: int, Name: string, Value: string>, BuildID: int, ContentDefinitionID: int, ContentSubmissionID: int, Definition: record<Attributes: list<record>, ContentDefinitionID: int, Description: string, Name: string, PackageTypeID: string, TypeID: int>, JobRunID: int, PackageID: string, ReleaseNotes: string, Repository: string, Revision: int, SubmissionDate: string, UserID: int, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionID' must be non-empty" } }
  let qp = [(serialize-qp "includeAttributes" $include_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_submission_id: (encode-path-segment $content_submission_id)} | format pattern "/api/v2/ContentSubmissions/{content_submission_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeAttributes": $include_attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a ContentSubmission
#
# PUT /api/v2/ContentSubmissions/{contentSubmissionID}
# operationId: ContentSubmissions_PutContentSubmission
# --Attributes item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
# --Definition shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
export def "content-submissions update" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Attributes of this ContentSubmission — item shape: {ContentSubmissionID?: int, ID?: int, Name: string, Value?: string}
  --build-id: int # ReadOnly. The ID of the Azure DevOps Build which will build the content package. (format: int32)
  --content-definition-id: int # The ID of the Content Definition. (format: int32)
  --body-content-submission-id: int # The ID of this Content Submission. (format: int32)
  --definition: record # The definition of the content for submission — shape: {Attributes?: list, ContentDefinitionID?: int, Description: string, Name?: string, PackageTypeID?: string, TypeID?: int}
  --job-run-id: int # ReadOnly. The ID of the JobRun which will build the content package. (format: int32)
  --package-id: string # The ID of package generated by this content submission.
  --release-notes: string # Release Notes for this ContentSubmission
  --repository: string # The SVN repository used as the source of this content submission
  --revision: int # The SVN revision used as the source of this content submission. (format: int32)
  --submission-date: string # Read Only. The UTC date and time the content submission was made. (format: date-time)
  --user-id: int # Read Only. The ID of the user who submitted the content (format: int32)
  --version: int # Optional. The version number assigned to this Content Submission and the resulting Package. If not provided, version shall be 1 if it is the first content submission for the ContentDefinitionID otherwise it shall be the highest content submission version for the specified ContentDefinitionID incremented by 1. (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionID' must be non-empty" } }
  let full_url = (build-url $base ({content_submission_id: (encode-path-segment $content_submission_id)} | format pattern "/api/v2/ContentSubmissions/{content_submission_id}") $auth.query)
  let req_body = {"Attributes": $attributes, "BuildID": $build_id, "ContentDefinitionID": $content_definition_id, "ContentSubmissionID": $body_content_submission_id, "Definition": $definition, "JobRunID": $job_run_id, "PackageID": $package_id, "ReleaseNotes": $release_notes, "Repository": $repository, "Revision": $revision, "SubmissionDate": $submission_date, "UserID": $user_id, "Version": $version} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Attributes for a ContentSubmission
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes
# operationId: ContentSubmissions_GetContentSubmissionAttributes
export def "content-submissions-attributes get" [
  content_submission_id: int
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --name: string # Optional. Filter the attributes by Name.
]: nothing -> record<Entities: table<ContentSubmissionID: int, ID: int, Name: string, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionID' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_submission_id: (encode-path-segment $content_submission_id)} | format pattern "/api/v2/ContentSubmissions/{content_submission_id}/Attributes") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add an Attribute to a ContentSubmission
#
# POST /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes
# operationId: ContentSubmissions_PostContentSubmissionAttribute
export def "content-submissions-attributes create" [
  content_submission_id: int
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
  --body-content-submission-id: int # The ID of the content submission to which this attribute belongs. (format: int32)
  --id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --value: string # The value of this Attribute
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionID' must be non-empty" } }
  let full_url = (build-url $base ({content_submission_id: (encode-path-segment $content_submission_id)} | format pattern "/api/v2/ContentSubmissions/{content_submission_id}/Attributes") $auth.query)
  let req_body = {"ContentSubmissionID": $body_content_submission_id, "ID": $id, "Name": $name, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# No Documentation Found.
#
# POST /api/v2/ContentSubmissions/{contentSubmissionID}/Attributes/Batch
# operationId: ContentSubmissions_PostContentSubmissionAttributes
export def "content-submissions-attributes-batch create" [
  content_submission_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionID' must be non-empty" } }
  let full_url = (build-url $base ({content_submission_id: (encode-path-segment $content_submission_id)} | format pattern "/api/v2/ContentSubmissions/{content_submission_id}/Attributes/Batch") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get the status of a ContentSubmission
#
# GET /api/v2/ContentSubmissions/{contentSubmissionID}/Status
# operationId: ContentSubmissions_GetContentSubmissionStatus
export def "content-submissions-status get" [
  content_submission_id: int
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
  --include-activity-run-details: oneof<nothing, bool> # True to include all status details if JobRun. Defaults to false
]: nothing -> record<ActivityRuns: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, EndDate: string, JobID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_submission_id | is-empty) { error make --unspanned { msg: "path parameter 'contentSubmissionID' must be non-empty" } }
  let qp = [(serialize-qp "includeActivityRunDetails" $include_activity_run_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_submission_id: (encode-path-segment $content_submission_id)} | format pattern "/api/v2/ContentSubmissions/{content_submission_id}/Status") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeActivityRunDetails": $include_activity_run_details} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a total count of dealers per country
#
# GET /api/v2/DealerByCountry
# operationId: DealerByCountry_GetCountries
export def "dealer-by-country get-countries" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Count: int, Country: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/DealerByCountry" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of dealers.
#
# GET /api/v2/Dealers
# operationId: Dealers_GetDealers
export def "dealers get" [
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
  --brand: string # The brand to filter by.
  --shipping-country: string # The country to filter by.
  --dealer-name: string # The partial Dealer Name to filter by. Wildcard supported (*).
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<BillingAddress: string, BillingAddress2: string, BillingAddress3: string, BillingAddress4: string, BillingCity: string, BillingCountry: string, BillingCountryCode: string, BillingState: string, BillingZip: string, Brands: list, DealerCode: string, DealerName: string, DealerStatus: string, DealerStatusUpdateDate: string, Filler: string, IsValid: bool, LanguagePreference: string, Region1: string, Region2: string, RegionMapping: string, RoleBrand: string, ShippingAddress2: string, ShippingAddress3: string, ShippingAddress4: string, ShippingCity: string, ShippingCountry: string, ShippingState: string, ShippingStreet: string, ShippingZip: string, Telephone: string, VATCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Brand" $brand "scalar") (serialize-qp "ShippingCountry" $shipping_country "scalar") (serialize-qp "DealerName" $dealer_name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Dealers" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Brand": $brand, "ShippingCountry": $shipping_country, "DealerName": $dealer_name, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lookup a dealer using a dealer code.
#
# GET /api/v2/Dealers/{DealerCode}
# operationId: Dealers_GetDealerbyDealerCode
export def "dealers get-dealerby-code" [
  dealer_code: string
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
]: nothing -> record<BillingAddress: string, BillingAddress2: string, BillingAddress3: string, BillingAddress4: string, BillingCity: string, BillingCountry: string, BillingCountryCode: string, BillingState: string, BillingZip: string, Brands: list<string>, DealerCode: string, DealerName: string, DealerStatus: string, DealerStatusUpdateDate: string, Filler: string, IsValid: bool, LanguagePreference: string, Region1: string, Region2: string, RegionMapping: string, RoleBrand: string, ShippingAddress2: string, ShippingAddress3: string, ShippingAddress4: string, ShippingCity: string, ShippingCountry: string, ShippingState: string, ShippingStreet: string, ShippingZip: string, Telephone: string, VATCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dealer_code | is-empty) { error make --unspanned { msg: "path parameter 'DealerCode' must be non-empty" } }
  let full_url = (build-url $base ({dealer_code: (encode-path-segment $dealer_code)} | format pattern "/api/v2/Dealers/{dealer_code}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a paged response of file metadata.
#
# GET /api/v2/Files
# operationId: Files_GetFiles
export def "files list" [
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
  --include-deleted: oneof<nothing, bool> # Indicates whether to include files marked as removed.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<CRC: string, ContentType: string, Description: string, Id: string, IsPublic: bool, Name: string, Path: string, Size: int, State: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDeleted" $include_deleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Files" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeDeleted": $include_deleted, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create the metadata for a file before uploading. The State of the File should be 'Created'.
#
# POST /api/v2/Files
# operationId: Files_PostFile
export def "files create" [
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
  crc: string # The crc of the file (SHA256, HEX-encoded). Must be provided when creating a file.
  content_type: string # The type of file; sent as the content-type header.
  description: string # The description of the file.
  --id: string # The Id of the file.
  --is-public: oneof<nothing, bool> # Indicates whether this file is available to the public for download.
  name: string # The name of the file when downloaded.
  path: string # The Path of the file.
  --size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  state: string@state-completer-2 # Indicates the state of this file. Must be 'Created' when created.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Files" $auth.query)
  let req_body = {"CRC": $crc, "ContentType": $content_type, "Description": $description, "Id": $id, "IsPublic": $is_public, "Name": $name, "Path": $path, "Size": $size, "State": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Mark a file as 'Removed'. Disables download of the file and hides metadata from GET all method
#
# DELETE /api/v2/Files/{ID}
# operationId: Files_DeleteFile
export def "files delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Files/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets a file's metadata.
#
# GET /api/v2/Files/{ID}
# operationId: Files_GetFile
export def "files get" [
  id: string
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
]: nothing -> record<CRC: string, ContentType: string, Description: string, Id: string, IsPublic: bool, Name: string, Path: string, Size: int, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Files/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update the metadata for a file. Size may not be modified by the client.
#
# PUT /api/v2/Files/{ID}
# operationId: Files_PutFile
export def "files update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  crc: string # The crc of the file (SHA256, HEX-encoded). Must be provided when creating a file.
  content_type: string # The type of file; sent as the content-type header.
  description: string # The description of the file.
  --body-id: string # The Id of the file.
  --is-public: oneof<nothing, bool> # Indicates whether this file is available to the public for download.
  name: string # The name of the file when downloaded.
  path: string # The Path of the file.
  --size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  state: string@state-completer-2 # Indicates the state of this file. Must be 'Created' when created.
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Files/{id}") $auth.query)
  let req_body = {"CRC": $crc, "ContentType": $content_type, "Description": $description, "Id": $body_id, "IsPublic": $is_public, "Name": $name, "Path": $path, "Size": $size, "State": $state} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Download the contents of a file. The current State of the File should be 'Available'.
#
# GET /api/v2/Files/{ID}/FileContents
# operationId: Files_GetFileContents
export def "files-file-contents get" [
  id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Files/{id}/FileContents") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Upload the contents of a file. The current State of the File should be 'Created'.
#
# PUT /api/v2/Files/{ID}/FileContents
# operationId: Files_PutFileContents
export def "files-file-contents update" [
  id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Files/{id}/FileContents") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get a paged response of file metadata.
#
# GET /api/v2/GlobalImageCategories
# operationId: GlobalImageCategories_GetFiles
export def "global-image-categories get-files" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Id: string, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/GlobalImageCategories" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create the metadata for a file before uploading. The State should be 'Created'.
#
# POST /api/v2/GlobalImageCategories
# operationId: GlobalImageCategories_PostFile
export def "global-image-categories create-file" [
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
  --id: string # The Id of the GlobalImage Categories.
  name: string # The name of the globalImage Catetory.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/GlobalImageCategories" $auth.query)
  let req_body = {"Id": $id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets a file's metadata.
#
# GET /api/v2/GlobalImageCategories/{ID}
# operationId: GlobalImageCategories_GetFile
export def "global-image-categories get-file" [
  id: string
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
]: nothing -> record<Id: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/GlobalImageCategories/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a paged response of GlobalImage.
#
# GET /api/v2/GlobalImages
# operationId: GlobalImages_GetGlobalImages
export def "global-images list" [
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
  --search: string # Optional. Searches for matching global images with the matching Category Name, Publisher or Description
  --category-id: string
  --publisher: string
  --include-deleted: oneof<nothing, bool> # Indicates whether to include GlobalImages marked as removed.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<CRC: string, Categories: list, Date: string, Description: string, Height: int, Id: string, Name: string, Publisher: string, Size: int, State: string, ThumbnailCRC: string, ThumbnailSize: int, Width: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "publisher" $publisher "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/GlobalImages" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "categoryId": $category_id, "publisher": $publisher, "includeDeleted": $include_deleted, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create the metadata for a GlobalImage before uploading. The State should be 'Created'.
#
# POST /api/v2/GlobalImages
# operationId: GlobalImages_PostGlobalImage
# --Categories item shape: {Id?: string, Name: string}
export def "global-images create" [
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
  --override-publisher-or-date: oneof<nothing, bool> # Whether to set the publisher and date to the provided values.
  crc: string # The Hash of the file (SHA256, HEX-encoded).
  --categories: list # The category of the file. — item shape: {Id?: string, Name: string}
  --date: string # The date of the file. (format: date-time)
  description: string # The description of the file.
  height: int # The height of the file. (format: int32)
  --id: string # The Id of the GlobalImage Metadata.
  name: string # The name of the file when downloaded.
  --publisher: string # The Publisher of the file.
  --size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  state: string@state-completer-2 # Indicates the state of this file. Must be 'Created' when created. Read Only.
  thumbnail_crc: string # The Hash of the thumbnail file (SHA256, HEX-encoded).
  --thumbnail-size: int # The size of the thumbnail file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  width: int # The width of the file. (format: int32)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "overridePublisherOrDate" $override_publisher_or_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/GlobalImages" $qp $auth.query)
  let req_body = {"CRC": $crc, "Categories": $categories, "Date": $date, "Description": $description, "Height": $height, "Id": $id, "Name": $name, "Publisher": $publisher, "Size": $size, "State": $state, "ThumbnailCRC": $thumbnail_crc, "ThumbnailSize": $thumbnail_size, "Width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"overridePublisherOrDate": $override_publisher_or_date} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Mark a file as 'Removed'. Disables download of the image and hides metadata from GET all method
#
# DELETE /api/v2/GlobalImages/{ID}
# operationId: GlobalImages_DeleteFile
export def "global-images delete-file" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/GlobalImages/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets a GlobalImage's metadata.
#
# GET /api/v2/GlobalImages/{ID}
# operationId: GlobalImages_GetGlobalImage
export def "global-images get" [
  id: string
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
]: nothing -> record<CRC: string, Categories: table<Id: string, Name: string>, Date: string, Description: string, Height: int, Id: string, Name: string, Publisher: string, Size: int, State: string, ThumbnailCRC: string, ThumbnailSize: int, Width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/GlobalImages/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update the metadata for an image.
#
# PUT /api/v2/GlobalImages/{ID}
# operationId: GlobalImages_PutGlobalImage
# --Categories item shape: {Id?: string, Name: string}
export def "global-images update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --override-publisher-or-date: oneof<nothing, bool> # Whether to set the publisher and date to the provided values.
  crc: string # The Hash of the file (SHA256, HEX-encoded).
  --categories: list # The category of the file. — item shape: {Id?: string, Name: string}
  --date: string # The date of the file. (format: date-time)
  description: string # The description of the file.
  height: int # The height of the file. (format: int32)
  --body-id: string # The Id of the GlobalImage Metadata.
  name: string # The name of the file when downloaded.
  --publisher: string # The Publisher of the file.
  --size: int # The size of the file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  state: string@state-completer-2 # Indicates the state of this file. Must be 'Created' when created. Read Only.
  thumbnail_crc: string # The Hash of the thumbnail file (SHA256, HEX-encoded).
  --thumbnail-size: int # The size of the thumbnail file in bytes. Null until assigned by server when marked as 'Available'. Read Only (format: int64)
  width: int # The width of the file. (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "overridePublisherOrDate" $override_publisher_or_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/GlobalImages/{id}") $qp $auth.query)
  let req_body = {"CRC": $crc, "Categories": $categories, "Date": $date, "Description": $description, "Height": $height, "Id": $body_id, "Name": $name, "Publisher": $publisher, "Size": $size, "State": $state, "ThumbnailCRC": $thumbnail_crc, "ThumbnailSize": $thumbnail_size, "Width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"overridePublisherOrDate": $override_publisher_or_date} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Download the contents of a GlobalImage. The current State of the GlobalImage should be 'Available'.
#
# GET /api/v2/GlobalImages/{ID}/ImageContents
# operationId: GlobalImages_GetGlobalImageContents
export def "global-images-image-contents get" [
  id: string
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
  --is-full-image: oneof<nothing, bool> # Indicated whether to download the full image or the thumbnail. Defaults to 'true'.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "isFullImage" $is_full_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/GlobalImages/{id}/ImageContents") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"isFullImage": $is_full_image} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Upload the contents of a GlobalImage. The current State of the File for the GlobalImage should be 'Created'.
#
# PUT /api/v2/GlobalImages/{ID}/ImageContents
# operationId: GlobalImages_PutGlobalImageContents
export def "global-images-image-contents update" [
  id: string
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
  --is-full-image: oneof<nothing, bool> # Indicated whether this is the full image or the thumbnail. Defaults to 'true'.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "isFullImage" $is_full_image "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/GlobalImages/{id}/ImageContents") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"isFullImage": $is_full_image} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Get a list of the languages for which translations are supported. Returns a PagedResponse of Language objects.
#
# GET /api/v2/Languages
# operationId: Languages_GetLanguages
export def "languages list" [
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
  --limit: int # limit the number of Language objects returned. Optional (defaults to 10). (format: int32)
  --offset: int # the number of Language objects to skip. Optional (defaults to 0). (format: int32)
  --include-deleted: oneof<nothing, bool> # whether to include languages marked as deleted. Defaults to false
]: nothing -> record<Entities: table<Description: string, IsDeleted: bool, LocaleId: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Languages" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "includeDeleted": $include_deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Language to support for translations. Accepts a Language object. Returns the Id of the created object.
#
# POST /api/v2/Languages
# operationId: Languages_CreateLanguage
export def "languages create" [
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
  description: string # The description of the language (e.g. “English – United States”).
  --is-deleted: oneof<nothing, bool> # Indicates whether the API supports the language. Must be false when created. Read Only.
  locale_id: int # The Locale Id of the language. (format: int32)
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Languages" $auth.query)
  let req_body = {"Description": $description, "IsDeleted": $is_deleted, "LocaleId": $locale_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Remove a Language from those supported for translations. Marks language as deleted.
#
# DELETE /api/v2/Languages/{LocaleID}
# operationId: Languages_DeleteLanguage
export def "languages delete" [
  locale_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'LocaleID' must be non-empty" } }
  let full_url = (build-url $base ({locale_id: (encode-path-segment $locale_id)} | format pattern "/api/v2/Languages/{locale_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a language by its id. Returns a Language object
#
# GET /api/v2/Languages/{LocaleID}
# operationId: Languages_GetLanguage
export def "languages get" [
  locale_id: int
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
]: nothing -> record<Description: string, IsDeleted: bool, LocaleId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'LocaleID' must be non-empty" } }
  let full_url = (build-url $base ({locale_id: (encode-path-segment $locale_id)} | format pattern "/api/v2/Languages/{locale_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a language’s description. Accepts a Language object.
#
# PUT /api/v2/Languages/{LocaleID}
# operationId: Languages_UpdateLanguage
export def "languages update" [
  locale_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # The description of the language (e.g. “English – United States”).
  --is-deleted: oneof<nothing, bool> # Indicates whether the API supports the language. Must be false when created. Read Only.
  --body-locale-id: int # The Locale Id of the language. (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($locale_id | is-empty) { error make --unspanned { msg: "path parameter 'LocaleID' must be non-empty" } }
  let full_url = (build-url $base ({locale_id: (encode-path-segment $locale_id)} | format pattern "/api/v2/Languages/{locale_id}") $auth.query)
  let req_body = {"Description": $description, "IsDeleted": $is_deleted, "LocaleId": $body_locale_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Create a license activation.
#
# POST /api/v2/LicenseActivations
# operationId: LicenseActivations_Post
export def "license-activations create" [
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
  dealer_code: string # The Dealer Code of the dealer activating the license
  --license-activation-type: string@license-activation-type-completer # The type of license to create (e.g. EDT, EDT Lite)
  postal_code: string # The dealer's postal code (zip code)
  system_info: string # Information about the system being activated
  voucher_code: string # The Voucher Code to use for activation
]: any -> record<Key: string, LicenseData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/LicenseActivations" $auth.query)
  let req_body = {"DealerCode": $dealer_code, "LicenseActivationType": $license_activation_type, "PostalCode": $postal_code, "SystemInfo": $system_info, "VoucherCode": $voucher_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Register an EDT Lite with the Server
#
# POST /api/v2/LicenseActivations/RegisterEDTLite
# operationId: LicenseActivations_PostRegisterEDTLite
export def "license-activations-register-edt-lite create" [
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
  --dealer-code: string # The dealer code with which the EDT Lite was created.
  expiration_date: string # The date at which the content of the EDT Lite expires. (format: date-time)
  instance_id: string # The identifier for the EDT Lite.
  voucher_code: string # The voucher code with which the EDT Lite was created.
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/LicenseActivations/RegisterEDTLite" $auth.query)
  let req_body = {"DealerCode": $dealer_code, "ExpirationDate": $expiration_date, "InstanceID": $instance_id, "VoucherCode": $voucher_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Update a license activiation.
#
# PUT /api/v2/LicenseActivations/{ID}
# operationId: LicenseActivations_Put
export def "license-activations update" [
  id: string
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
  license_version: string # The license version to update
  --system-info: string # Information about the system being activated
]: any -> record<Key: string, LicenseData: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/LicenseActivations/{id}") $auth.query)
  let req_body = {"LicenseVersion": $license_version, "SystemInfo": $system_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Confirm that the client has applied the updated license.
#
# PUT /api/v2/LicenseActivations/{ID}/Confirm
# operationId: LicenseActivations_PutConfirm
export def "license-activations-confirm update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  license_version: string # The license version to confirm
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/LicenseActivations/{id}/Confirm") $auth.query)
  let req_body = {"LicenseVersion": $license_version} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets a list of licenses with the specified criteria.
#
# GET /api/v2/Licenses
# operationId: Licenses_Get
export def "licenses list" [
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
  --voucher-code: string # Optional. Filter by VoucherCode
  --dealer-code: string # Optional. Filter by DealerCode
  --status: string@status-completer # Optional. Filter by Status. By default only active licenses will be returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Active: bool, CreatedDate: string, DeactivatedDate: string, LicenseActivationType: string, LicenseID: string, LicenseVersion: string, RefreshDate: string, SystemInfo: string, UpdatedLicenseVersion: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "VoucherCode" $voucher_code "scalar") (serialize-qp "DealerCode" $dealer_code "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Licenses" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"VoucherCode": $voucher_code, "DealerCode": $dealer_code, "Status": $status, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a license.
#
# GET /api/v2/Licenses/{ID}
export def "licenses get" [
  id: string
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
]: nothing -> record<Active: bool, CreatedDate: string, DeactivatedDate: string, LicenseActivationType: string, LicenseID: string, LicenseVersion: string, RefreshDate: string, SystemInfo: string, UpdatedLicenseVersion: string, VoucherCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Licenses/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get the API System logs, most recent first.
#
# GET /api/v2/Logs
# operationId: Logs_GetLogs
export def "logs list" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ID: string, Message: string, TimeStamp: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Logs" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Log entry
#
# POST /api/v2/Logs
# operationId: Logs_PostLog
export def "logs create" [
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
  --message: string # Message to enter into the log
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Message" $message "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Logs" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Message": $message} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get a log by ID
#
# GET /api/v2/Logs/{ID}
# operationId: Logs_GetLog
export def "logs get" [
  id: string
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
]: nothing -> record<ID: string, Message: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Logs/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Sends an email message.
#
# POST /api/v2/Notifications
# operationId: Notifications_PostMail
export def "notifications create-mail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cc-addresses: list<string>
  --is-body-html: oneof<nothing, bool>
  message_body: string
  subject: string
  to_addresses: list<string>
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Notifications" $auth.query)
  let req_body = {"CC_Addresses": $cc_addresses, "IsBodyHtml": $is_body_html, "MessageBody": $message_body, "Subject": $subject, "To_Addresses": $to_addresses} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get all of the Package Types.
#
# GET /api/v2/PackageTypes
# operationId: PackageTypes_Get
export def "package-types list" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --user-id: int # Optional. The user ID to sort packageTypes by the user's access (format: int32)
]: nothing -> record<Entities: table<Attribute: string, Category: string, Description: string, Icon: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, MaxDeltaPackages: int, PackageTypeID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/PackageTypes" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "userID": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Package Type.
#
# POST /api/v2/PackageTypes
# operationId: PackageTypes_Post
export def "package-types create" [
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
  --attribute: string # The inventory attribute (from the InventoryPackage) used to determine what version of this package type is installed.
  --category: string # The inventory category (from the InventoryPackage) used to determine what version of this package type is installed.
  description: string # The description of the package type
  --icon: string # Optional. The icon to use for the PackageType, in base 64
  --inventory-frequency: int # The number of minutes to wait before requesting another inventory. The default value is 1440 (24 hours). (format: int32)
  --inventory-package: string # The inventory package used to determine what version of this package type is installed.
  --localized-description: string # Optional. The StringID used to localize the description of the PackageType
  --localized-name: string # Optional. The StringID used to localize the name of the PackageType
  --max-delta-packages: int # The maximum number of "chained" delta packages to use when updating the client (format: int32)
  --package-type-id: string # Read Only. The package type id.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/PackageTypes" $auth.query)
  let req_body = {"Attribute": $attribute, "Category": $category, "Description": $description, "Icon": $icon, "InventoryFrequency": $inventory_frequency, "InventoryPackage": $inventory_package, "LocalizedDescription": $localized_description, "LocalizedName": $localized_name, "MaxDeltaPackages": $max_delta_packages, "PackageTypeID": $package_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a Package Type.
#
# DELETE /api/v2/PackageTypes/{ID}
# operationId: PackageTypes_Delete
export def "package-types delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/PackageTypes/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a specific Package Type.
#
# GET /api/v2/PackageTypes/{ID}
export def "package-types get" [
  id: string
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
]: nothing -> record<Attribute: string, Category: string, Description: string, Icon: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, MaxDeltaPackages: int, PackageTypeID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/PackageTypes/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Modify a Package Type.
#
# PUT /api/v2/PackageTypes/{ID}
# operationId: PackageTypes_Put
export def "package-types update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string # The inventory attribute (from the InventoryPackage) used to determine what version of this package type is installed.
  --category: string # The inventory category (from the InventoryPackage) used to determine what version of this package type is installed.
  description: string # The description of the package type
  --icon: string # Optional. The icon to use for the PackageType, in base 64
  --inventory-frequency: int # The number of minutes to wait before requesting another inventory. The default value is 1440 (24 hours). (format: int32)
  --inventory-package: string # The inventory package used to determine what version of this package type is installed.
  --localized-description: string # Optional. The StringID used to localize the description of the PackageType
  --localized-name: string # Optional. The StringID used to localize the name of the PackageType
  --max-delta-packages: int # The maximum number of "chained" delta packages to use when updating the client (format: int32)
  --package-type-id: string # Read Only. The package type id.
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/PackageTypes/{id}") $auth.query)
  let req_body = {"Attribute": $attribute, "Category": $category, "Description": $description, "Icon": $icon, "InventoryFrequency": $inventory_frequency, "InventoryPackage": $inventory_package, "LocalizedDescription": $localized_description, "LocalizedName": $localized_name, "MaxDeltaPackages": $max_delta_packages, "PackageTypeID": $package_type_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Deletes a package type a user could see.
#
# DELETE /api/v2/PackageTypes/{id}/Users/{userID}
# operationId: PackageTypes_RemovePackageTypeUser
export def "package-types-users delete" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/api/v2/PackageTypes/{id}/Users/{user_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Add a package type that a user can see.
#
# POST /api/v2/PackageTypes/{id}/Users/{userID}
# operationId: PackageTypes_AddPackageTypeUser
export def "package-types-users create" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/api/v2/PackageTypes/{id}/Users/{user_id}") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Delete a Package Type to Bundle Relationship.
#
# DELETE /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Delete
export def "package-typeto-bundles delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bundle-id: string # The BundleID
  --package-type-id: string # The PackageTypeID
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "BundleID" $bundle_id "scalar") (serialize-qp "PackageTypeID" $package_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/PackageTypetoBundles" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"BundleID": $bundle_id, "PackageTypeID": $package_type_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get all of the Package Type to Bundle Relationships.
#
# GET /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Get
export def "package-typeto-bundles get" [
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
  --bundle-id: string # Optional. Filter by BundleID.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<BundleID: string, PackageTypeID: string, PackageVersion: int, Priority: int, SubscriptionType: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "BundleID" $bundle_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/PackageTypetoBundles" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"BundleID": $bundle_id, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a new Package Type ID to Bundle Relationship.
#
# POST /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Post
export def "package-typeto-bundles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bundle_id: string # The bundle to include the package in.
  package_type_id: string # The package type id of the package to include
  package_version: int # The package version of the package to include (format: int32)
  priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --subscription-type: string@subscription-type-completer # Optional. The type of subscription supported. The default subscription type is Required.
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/PackageTypetoBundles" $auth.query)
  let req_body = {"BundleID": $bundle_id, "PackageTypeID": $package_type_id, "PackageVersion": $package_version, "Priority": $priority, "SubscriptionType": $subscription_type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update a Package Type ID to Bundle Relationship.
#
# PUT /api/v2/PackageTypetoBundles
# operationId: PackageTypetoBundles_Put
export def "package-typeto-bundles update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bundle_id: string # The bundle to include the package in.
  package_type_id: string # The package type id of the package to include
  package_version: int # The package version of the package to include (format: int32)
  priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --subscription-type: string@subscription-type-completer # Optional. The type of subscription supported. The default subscription type is Required.
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/PackageTypetoBundles" $auth.query)
  let req_body = {"BundleID": $bundle_id, "PackageTypeID": $package_type_id, "PackageVersion": $package_version, "Priority": $priority, "SubscriptionType": $subscription_type} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List Packages.
#
# GET /api/v2/Packages
# operationId: Packages_GetPackages
export def "packages list" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --package-type-id: string # Optional. If provided, filters by PackageTypeID.
  --version: int # Optional. If provided, filters by Version. (format: int32)
  --released: oneof<nothing, bool> # Optional. If provided, filters by Released.
]: nothing -> record<Entities: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "PackageTypeID" $package_type_id "scalar") (serialize-qp "Version" $version "scalar") (serialize-qp "Released" $released "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Packages" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "PackageTypeID": $package_type_id, "Version": $version, "Released": $released} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Package to the Update System.
#
# POST /api/v2/Packages
# operationId: Packages_PostPackage
export def "packages create" [
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
  --autorun: oneof<nothing, bool> # Value is true if package should run automatically. Default value is false.
  crc: string # The CRC used to validate the download.
  description: string # The package description
  --localized-name: string # Optional. The StringID used to localize the name of the Package
  --notes: string # Notes about the package
  --package-id: string # Read Only. The package ID
  package_type_id: string # The id of the package type this package belongs to.
  --previous-version: int # For delta packages, the previous version required. For non-delta packages, the Previous version is 0. Default value is 0. (format: int32)
  release_date: string # The date the package was released (format: date-time)
  --released: oneof<nothing, bool> # True if the package is released. Default value is False.
  --remove-on-success: oneof<nothing, bool> # True to remove the package after successful execution. Default value is False.
  --size: int # The size of the file at the specified URL. If a size is not supplied at creation time, the size will be determined by the response from the URL. If the size provided does not match the size in the response from the URL an error will be returned. (format: int64)
  --switches: string # The command line arguments for the package. Default value is an empty string.
  url: string # The Url to download the package from.
  version: int # The version. (format: int32)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Packages" $auth.query)
  let req_body = {"Autorun": $autorun, "CRC": $crc, "Description": $description, "LocalizedName": $localized_name, "Notes": $notes, "PackageID": $package_id, "PackageTypeID": $package_type_id, "PreviousVersion": $previous_version, "ReleaseDate": $release_date, "Released": $released, "RemoveOnSuccess": $remove_on_success, "Size": $size, "Switches": $switches, "Url": $url, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a Package.
#
# DELETE /api/v2/Packages/{ID}
# operationId: Packages_DeletePackage
export def "packages delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Packages/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Find a Package.
#
# GET /api/v2/Packages/{ID}
# operationId: Packages_GetPackage
export def "packages get" [
  id: string
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
]: nothing -> record<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Packages/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Modify a Packge to the Update System.
#
# PUT /api/v2/Packages/{ID}
# operationId: Packages_PutPackage
export def "packages update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --autorun: oneof<nothing, bool> # Value is true if package should run automatically. Default value is false.
  crc: string # The CRC used to validate the download.
  description: string # The package description
  --localized-name: string # Optional. The StringID used to localize the name of the Package
  --notes: string # Notes about the package
  --package-id: string # Read Only. The package ID
  package_type_id: string # The id of the package type this package belongs to.
  --previous-version: int # For delta packages, the previous version required. For non-delta packages, the Previous version is 0. Default value is 0. (format: int32)
  release_date: string # The date the package was released (format: date-time)
  --released: oneof<nothing, bool> # True if the package is released. Default value is False.
  --remove-on-success: oneof<nothing, bool> # True to remove the package after successful execution. Default value is False.
  --size: int # The size of the file at the specified URL. If a size is not supplied at creation time, the size will be determined by the response from the URL. If the size provided does not match the size in the response from the URL an error will be returned. (format: int64)
  --switches: string # The command line arguments for the package. Default value is an empty string.
  url: string # The Url to download the package from.
  version: int # The version. (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Packages/{id}") $auth.query)
  let req_body = {"Autorun": $autorun, "CRC": $crc, "Description": $description, "LocalizedName": $localized_name, "Notes": $notes, "PackageID": $package_id, "PackageTypeID": $package_type_id, "PreviousVersion": $previous_version, "ReleaseDate": $release_date, "Released": $released, "RemoveOnSuccess": $remove_on_success, "Size": $size, "Switches": $switches, "Url": $url, "Version": $version} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List Permissions
#
# GET /api/v2/Permissions
# operationId: Permissions_GetPermissions
export def "permissions list" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --name: string # Filter by permission name. Supports ending wildcard (*). Optional.
]: nothing -> record<Entities: table<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Permissions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a Permission
#
# POST /api/v2/Permissions
# operationId: Permissions_PostPermission
export def "permissions create" [
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
  --data-description: string # Description of data to be provided with Role Authorization
  data_required: string@data-required-completer # Indicates if data is required or optional
  --description: string
  --id: int # The identifier of the permission. (format: int32)
  name: string # The name of the permission.
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Permissions" $auth.query)
  let req_body = {"DataDescription": $data_description, "DataRequired": $data_required, "Description": $description, "Id": $id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Deletes a Permission
#
# DELETE /api/v2/Permissions/{id}
# operationId: Permissions_DeletePermission
export def "permissions delete" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Permissions/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets a Permission
#
# GET /api/v2/Permissions/{id}
# operationId: Permissions_GetPermission
export def "permissions get" [
  id: int
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
]: nothing -> record<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Permissions/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Updates a Permission
#
# PUT /api/v2/Permissions/{id}
# operationId: Permissions_PutPermission
export def "permissions update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-description: string # Description of data to be provided with Role Authorization
  data_required: string@data-required-completer # Indicates if data is required or optional
  --description: string
  --body-id: int # The identifier of the permission. (format: int32)
  name: string # The name of the permission.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Permissions/{id}") $auth.query)
  let req_body = {"DataDescription": $data_description, "DataRequired": $data_required, "Description": $description, "Id": $body_id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a list of Priority Packages by Client.
#
# GET /api/v2/PriorityPackages
# operationId: PriorityPackages_GetPriorityPackages
export def "priority-packages list" [
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
  --client-id: string # Optional. Filter priority packages by ClientID.
  --status: string@status-completer-1 # Optional. Filter returned packages by status. By default only active packages will be returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Autorun: bool, CRC: string, ClientID: string, Description: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, PriorityPackageID: string, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, TimeStamp: string, Url: string, Version: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $client_id "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/PriorityPackages" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ClientID": $client_id, "Status": $status, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Priority Package for a Client.
#
# POST /api/v2/PriorityPackages
# operationId: PriorityPackages_PostPriorityPackages
export def "priority-packages create" [
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
  --autorun: oneof<nothing, bool> # Read Only. From the package specified by package ID. Value is true if package should run automatically. Default value is false.
  --crc: string # Read Only. From the package specified by package ID.
  client_id: string # The ID of the client to receive the priority package
  --description: string # Read Only. From the package specified by package ID.
  --notes: string # Read Only. From the package specified by package ID.
  package_id: string # The ID of the package to push as a priority package.
  --package-type-id: string # Read Only. From the package specified by package ID.
  --previous-version: int # Read Only. From the package specified by package ID. (format: int32)
  --priority-package-id: string # Read Only. The ID of the priority package.
  --release-date: string # Read Only. From the package specified by package ID. The date the package was released (format: date-time)
  --released: oneof<nothing, bool> # Read Only. From the package specified by package ID.
  --remove-on-success: oneof<nothing, bool> # Read Only. From the package specified by package ID.
  --size: int # Read Only. From the package specified by package ID. (format: int64)
  --switches: string # The command line arguments for the priority package. Default value is an empty string.
  --time-stamp: string # Read Only. The timestamp of the priority package. (format: date-time)
  --url: string # Read Only. From the package specified by package ID.
  --version: int # Read Only. From the package specified by package ID. (format: int32)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/PriorityPackages" $auth.query)
  let req_body = {"Autorun": $autorun, "CRC": $crc, "ClientID": $client_id, "Description": $description, "Notes": $notes, "PackageID": $package_id, "PackageTypeID": $package_type_id, "PreviousVersion": $previous_version, "PriorityPackageID": $priority_package_id, "ReleaseDate": $release_date, "Released": $released, "RemoveOnSuccess": $remove_on_success, "Size": $size, "Switches": $switches, "TimeStamp": $time_stamp, "Url": $url, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a Priority Package for a Client.
#
# DELETE /api/v2/PriorityPackages/{ID}
# operationId: PriorityPackages_DeletePriorityPackages
export def "priority-packages delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/PriorityPackages/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a Priority Packages for a Client.
#
# GET /api/v2/PriorityPackages/{ID}
# operationId: PriorityPackages_GetPriorityPackage
export def "priority-packages get" [
  id: string
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
]: nothing -> record<Autorun: bool, CRC: string, ClientID: string, Description: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, PriorityPackageID: string, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, TimeStamp: string, Url: string, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/PriorityPackages/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get Release
#
# GET /api/v2/Releases
# operationId: Release_GetReleases
export def "releases list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --visible: oneof<nothing, bool> # Optional. Filter by visible.
  --bundle-id: string # Optional. Filter by BundleID.
]: nothing -> record<Entities: table<BuildDate: string, BundleIDs: list, ReleaseDate: string, ReleaseID: int, ReleaseNumber: string, Visible: bool>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "visible" $visible "scalar") (serialize-qp "bundleID" $bundle_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Releases" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "visible": $visible, "bundleID": $bundle_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Release
#
# POST /api/v2/Releases
# operationId: Release_PostRelease
export def "releases create" [
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
  --build-date: string # Build Date (format: date-time)
  --bundle-i-ds: list<string> # IDs of AUC Bundles associated with this Release.
  --release-date: string # Release Date (format: date-time)
  --release-id: int # Release ID (format: int32)
  --release-number: string # Release Number
  --visible: oneof<nothing, bool> # Visible
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Releases" $auth.query)
  let req_body = {"BuildDate": $build_date, "BundleIDs": $bundle_i_ds, "ReleaseDate": $release_date, "ReleaseID": $release_id, "ReleaseNumber": $release_number, "Visible": $visible} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get a Release by ID
#
# GET /api/v2/Releases/{ReleaseId}
# operationId: Release_GetRelease
export def "releases get" [
  release_id: int
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
]: nothing -> record<BuildDate: string, BundleIDs: list<string>, ReleaseDate: string, ReleaseID: int, ReleaseNumber: string, Visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'ReleaseId' must be non-empty" } }
  let full_url = (build-url $base ({release_id: (encode-path-segment $release_id)} | format pattern "/api/v2/Releases/{release_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Deletes the association between a release and a bundle.
#
# DELETE /api/v2/Releases/{ReleaseId}/Bundle/{BundleId}
# operationId: Release_DeleteReleaseBundle
export def "releases-bundle delete" [
  release_id: int
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'ReleaseId' must be non-empty" } }
  if ($bundle_id | is-empty) { error make --unspanned { msg: "path parameter 'BundleId' must be non-empty" } }
  let full_url = (build-url $base ({release_id: (encode-path-segment $release_id), bundle_id: (encode-path-segment $bundle_id)} | format pattern "/api/v2/Releases/{release_id}/Bundle/{bundle_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Associates the release with a bundle.
#
# POST /api/v2/Releases/{ReleaseId}/Bundle/{BundleId}
# operationId: Release_PostReleaseBundle
export def "releases-bundle create" [
  release_id: int
  bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'ReleaseId' must be non-empty" } }
  if ($bundle_id | is-empty) { error make --unspanned { msg: "path parameter 'BundleId' must be non-empty" } }
  let full_url = (build-url $base ({release_id: (encode-path-segment $release_id), bundle_id: (encode-path-segment $bundle_id)} | format pattern "/api/v2/Releases/{release_id}/Bundle/{bundle_id}") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Update a Release
#
# PUT /api/v2/Releases/{releaseId}
# operationId: Release_PutContentDefinition
export def "releases update-content-definition" [
  release_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build-date: string # Build Date (format: date-time)
  --bundle-i-ds: list<string> # IDs of AUC Bundles associated with this Release.
  --release-date: string # Release Date (format: date-time)
  --body-release-id: int # Release ID (format: int32)
  --release-number: string # Release Number
  --visible: oneof<nothing, bool> # Visible
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($release_id | is-empty) { error make --unspanned { msg: "path parameter 'releaseId' must be non-empty" } }
  let full_url = (build-url $base ({release_id: (encode-path-segment $release_id)} | format pattern "/api/v2/Releases/{release_id}") $auth.query)
  let req_body = {"BuildDate": $build_date, "BundleIDs": $bundle_i_ds, "ReleaseDate": $release_date, "ReleaseID": $body_release_id, "ReleaseNumber": $release_number, "Visible": $visible} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a summary of all Packages in a Bundle
#
# GET /api/v2/Reporting/BundleStatusSummary
# operationId: Reporting_BundleStatusSummary
export def "reporting-bundle-status-summary get" [
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
  --bundle-id: string # The BundleID
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<AverageDownloadTime: string, AverageInstallTime: string, Downloaded: int, Error: int, Installed: int, Package: string, PackageID: string, PackageStatusItems: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "BundleID" $bundle_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/BundleStatusSummary" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"BundleID": $bundle_id, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of bundles for UpdateGroup.
#
# GET /api/v2/Reporting/BundlesInUpdateGroup
# operationId: Reporting_BundlesInUpdateGroup
export def "reporting-bundles-in-update-group update" [
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
  --id: string # The UpdateGroupID
  --include-inactive: oneof<nothing, bool> # Include Inactive Bundles (true|false)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ID" $id "scalar") (serialize-qp "IncludeInactive" $include_inactive "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/BundlesInUpdateGroup" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ID": $id, "IncludeInactive": $include_inactive, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Client Information
#
# GET /api/v2/Reporting/ClientInfo
# operationId: Reporting_ClientInfo
export def "reporting-client-info get" [
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
  --client-id: string # The Client ID
]: nothing -> record<ClientID: string, Package: table<Categories: list, PackageDescription: string, PackageID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/ClientInfo" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ClientID": $client_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the current packages for an update group.
#
# GET /api/v2/Reporting/CurrentPackagesInUpdateGroup
# operationId: Reporting_CurrentPackagesInUpdateGroup
export def "reporting-current-packages-in-update-group get" [
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
  --id: string # The UpdateGroupID
  --subscription-type-filter: string@subscription-type-filter-completer # Optional. The subscription type filter to use. By default the Default packages (Required and IncludeByDefault) will be returned.
]: nothing -> table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ID" $id "scalar") (serialize-qp "SubscriptionTypeFilter" $subscription_type_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/CurrentPackagesInUpdateGroup" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ID": $id, "SubscriptionTypeFilter": $subscription_type_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Client in the Update System.
#
# GET /api/v2/Reporting/GetClient
# operationId: Reporting_GetClient
export def "reporting-get-client get" [
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
  --id: string # The Client ID
]: nothing -> record<ClientID: string, LastCheckin: string, Tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ID" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/GetClient" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ID": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of current Client Subscriptions.
#
# GET /api/v2/Reporting/GetSubscriptions
# operationId: Reporting_GetSubscriptions
export def "reporting-get-subscriptions get" [
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
  --client-id: string # Optional. Filter by Client ID
  --update-group-id: string # Optional. Filter by Update Group ID
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $client_id "scalar") (serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/GetSubscriptions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ClientID": $client_id, "UpdateGroupID": $update_group_id, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a summary report for a Specific Package
#
# GET /api/v2/Reporting/PackageStatusSummary
# operationId: Reporting_PackageStatusSummary
export def "reporting-package-status-summary get" [
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
  --package-id: string # The Package ID
]: nothing -> record<AverageDownloadTime: string, AverageInstallTime: string, Downloaded: int, Error: int, Installed: int, Package: string, PackageID: string, PackageStatusItems: table<ClientID: string, ClientKey: string, DownloadTime: string, Downloaded: string, InstallCompleted: string, InstallResult: string, InstallStarted: string, InstallTime: string, Percentage: string, Size: string, Timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PackageID" $package_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/PackageStatusSummary" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PackageID": $package_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of subscribed clients
#
# GET /api/v2/Reporting/RegisteredClients
# operationId: Reporting_RegisteredClients
export def "reporting-registered-clients get" [
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
  --update-group-id: string # Optional but required when including any or all of following parameters: ReportValue, ReportResult, ReportResultIsValid. The Update Group ID. If not provided, all clients will be returned.
  --client-id: string # Optional. Filter where ClientID matches a value. Wildcards are supported (*).
  --tag: string # Optional. Filter where Tag matches a value. Wildcards are supported (*).
  --report-result: string # Optional and UpdateGroupID must be included. Filter where ReportResult matches a value. Wildcards are supported (*).
  --report-result-is-valid: oneof<nothing, bool> # Optional and UpdateGroupID must be included. When 'true' filters results where ReportResult equals ReportResultExpected. When 'false' filters results where ValueToValidate does not equal ReportResults.
  --report-value: string # Optional and UpdateGroupID must be included. Filter where ReportValue matches a value. Wildcards are supported (*).
  --last-check-in-before: string # Optional. Filter where LastCheckIn occured before the provided date. (format: date-time)
  --last-check-in-after: string # Optional. Filter where LastCheckIn occured after the provided date. (format: date-time)
  --order-by: string # Optional. Specify the order in which results should be returned. Use this format: [FieldName] [ASC|ASCENDING|DESC|DESCENDING],... If sort direction is not provided for a field, it will be sorted ascending.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ClientID: string, LastCheckin: string, MinutesElapsed: int, ReportResult: string, ReportResultIsValid: bool, ReportValue: string, Tag: string>, Metadata: record<Limit: int, Offset: int, ReportResultExpected: string, ReportResultLabel: string, ReportValueLabel: string, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "ClientID" $client_id "scalar") (serialize-qp "Tag" $tag "scalar") (serialize-qp "ReportResult" $report_result "scalar") (serialize-qp "ReportResultIsValid" $report_result_is_valid "scalar") (serialize-qp "ReportValue" $report_value "scalar") (serialize-qp "LastCheckInBefore" $last_check_in_before "scalar") (serialize-qp "LastCheckInAfter" $last_check_in_after "scalar") (serialize-qp "OrderBy" $order_by "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/RegisteredClients" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdateGroupID": $update_group_id, "ClientID": $client_id, "Tag": $tag, "ReportResult": $report_result, "ReportResultIsValid": $report_result_is_valid, "ReportValue": $report_value, "LastCheckInBefore": $last_check_in_before, "LastCheckInAfter": $last_check_in_after, "OrderBy": $order_by, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of Update Groups. Update Groups are used by the client to register for a specific type of update.
#
# GET /api/v2/Reporting/UpdateGroups
# operationId: Reporting_UpdateGroups
export def "reporting-update-groups update" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/UpdateGroups" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get data for pie charts in UpdateMetrics.
#
# GET /api/v2/Reporting/UpdateMetrics
# operationId: Reporting_UpdateMetrics
export def "reporting-update-metrics update" [
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
  --update-group-id: string # The UpdateType in which clients must be for the report to include them.
  --bundle-number: int # Optional. Tells us which chart to show based upon filter. (format: int32)
]: nothing -> record<ActiveVersion: string, ActiveVersionByClient: table<BundleNumber: int, ClientCount: int, ReleaseName: string>, CurrentStateByClient: table<ClientCount: int, State: string>, CutOffDate: string, DataRefreshed: string, FilteredClientCount: int, PackageErrors: table<ClientCount: int, ErrorCode: string, LongDescription: string, ShortDescription: string>, TotalClientCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "bundleNumber" $bundle_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Reporting/UpdateMetrics" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdateGroupID": $update_group_id, "bundleNumber": $bundle_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Roles
#
# GET /api/v2/Roles
# operationId: Roles_GetRoles
export def "roles list" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --name: string # Optional. Finds a role with the given name.
  --permission-id: int # format: int32
  --permission-name: string # Optional. Filters roles by whether they contain the provided permission.
]: nothing -> record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "permissionID" $permission_id "scalar") (serialize-qp "permissionName" $permission_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Roles" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "name": $name, "permissionID": $permission_id, "permissionName": $permission_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a User Role
#
# POST /api/v2/Roles
# operationId: Roles_PostRole
export def "roles create" [
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
  description: string # Role description
  --id: int # The role's identifier. (format: int32)
  name: string # The name of the role. Must be alpha-numeric strings separated by a period (.).
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Roles" $auth.query)
  let req_body = {"Description": $description, "Id": $id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Deletes a User Role
#
# DELETE /api/v2/Roles/{id}
# operationId: Roles_DeleteRole
export def "roles delete" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Roles/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Gets a User Role
#
# GET /api/v2/Roles/{id}
# operationId: Roles_GetRole
export def "roles get" [
  id: int
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
]: nothing -> record<Description: string, Id: int, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Roles/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Updates a User Role
#
# PUT /api/v2/Roles/{id}
# operationId: Roles_PutRole
export def "roles update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Role description
  --body-id: int # The role's identifier. (format: int32)
  name: string # The name of the role. Must be alpha-numeric strings separated by a period (.).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Roles/{id}") $auth.query)
  let req_body = {"Description": $description, "Id": $body_id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get the Permissions for a Role
#
# GET /api/v2/Roles/{id}/Permissions
# operationId: Roles_GetRolePermissions
export def "roles-permissions get" [
  id: int
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
  --name: string # Filter by permission name. Optional.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<DataDescription: string, DataRequired: string, Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Roles/{id}/Permissions") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Manage the Permissions for a Role
#
# PUT /api/v2/Roles/{id}/Permissions
# operationId: Roles_PutRolePermissions
export def "roles-permissions update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Roles/{id}/Permissions") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get all user's in a role
#
# GET /api/v2/Roles/{id}/Users
# operationId: UserPermissions_GetUsers
export def "roles-users get-permissions" [
  id: int
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
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Roles/{id}/Users") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Role's users
#
# PUT /api/v2/Roles/{id}/Users
export def "roles-users update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Roles/{id}/Users") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a paged response of Global String Definitions.
#
# GET /api/v2/StringDefinitions
# operationId: StringDefinitions_GetDefinitions
export def "string-definitions list" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. Ignored if 'stringIds' is provided. (format: int32)
  --modified-after-timestamp: string # Optional. Return only the StringDefinition objects that have a Timestamp value greater than that provided. This will be an encoded byte array.
  --include-translations: oneof<nothing, bool> # Optional. Indicates whether to include the StringTranslations for the StringDefinition. Defaults to false.
  --string-text: string # Optional. The text for which to search in the StringDefinition object’s translations. Only StringDefinition objects for matching StringTranslation objects are returned. Does not filter if no value is provided. Supports beginning and/or ending wildcards. includeTranslations must be true.
  --description-text: string # Optional. The text for which to search in the StringDefinition description field. Only matching objects are returned. Does not filter if no value is provided. Supports beginning and/or ending wildcards.
  --use-full-text: oneof<nothing, bool> # Optional. This flag is used to determin whether to use the FullText Search or not.
  --include-deleted-languages: oneof<nothing, bool> # Optional. Indicates whether to include languages marked as deleted. includeTranslations must be true. Defaults to false.
  --language-ids: string # Optional. A comma-delimited list of language ids. Only StringTranslation objects with a matching language id will be returned. Optional. By default all locales are returned. includeTranslations must be true. The StringDefinition is still returned even if the filtered translations list is empty.
  --string-ids: string # Optional. A comma-delimited list of string ids. Up to 40 string IDs may be provided. May not be used with 'modifiedAfterTimestamp', 'stringText', 'descriptionText', or 'useFullText'.
  --matching-translations-only: oneof<nothing, bool> # Optional. If false, all translations for returned String Definitions are included. Must be used with 'stringText' provided and 'includeTranslations' = true.
]: nothing -> record<Entities: table<DescriptionForTranslator: string, DoNotTranslate: bool, Id: string, ParameterCount: int, Timestamp: string, Translations: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "modifiedAfterTimestamp" $modified_after_timestamp "scalar") (serialize-qp "includeTranslations" $include_translations "scalar") (serialize-qp "stringText" $string_text "scalar") (serialize-qp "descriptionText" $description_text "scalar") (serialize-qp "useFullText" $use_full_text "scalar") (serialize-qp "includeDeletedLanguages" $include_deleted_languages "scalar") (serialize-qp "languageIds" $language_ids "scalar") (serialize-qp "stringIds" $string_ids "scalar") (serialize-qp "matchingTranslationsOnly" $matching_translations_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/StringDefinitions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "modifiedAfterTimestamp": $modified_after_timestamp, "includeTranslations": $include_translations, "stringText": $string_text, "descriptionText": $description_text, "useFullText": $use_full_text, "includeDeletedLanguages": $include_deleted_languages, "languageIds": $language_ids, "stringIds": $string_ids, "matchingTranslationsOnly": $matching_translations_only} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create StringDefinition object. The originating translation must be provided. Accepts an array of StringDefinition objects. Returns nothing.
#
# POST /api/v2/StringDefinitions/Batch
# operationId: StringDefinitions_PostDefinition
export def "string-definitions-batch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/StringDefinitions/Batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update StringDefinition objects. Accepts an array of StringDefinition objects. This endpoint will add StringDefinitionChange objects to the database. The DescriptionForTranslator may not be modified after a String is submitted for translation.
#
# PUT /api/v2/StringDefinitions/Batch
# operationId: StringDefinitions_UpdateDefinitions
export def "string-definitions-batch update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/StringDefinitions/Batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a paged response of Global String Definitions.
#
# GET /api/v2/StringDefinitions/{ID}
# operationId: StringDefinitions_GetDefinition
export def "string-definitions get" [
  id: string
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
  --include-translations: oneof<nothing, bool> # Optional. Indicates whether to include the StringTranslations for the StringDefinition. Defaults to false.
  --include-deleted-languages: oneof<nothing, bool> # Optional. Indicates whether to include languages marked as deleted. includeTranslations must be true. Defaults to false.
  --language-ids: string # Optional. A comma-delimited list of language ids. Only StringTranslation objects with a matching language id will be returned. Optional. By default all locales are returned. includeTranslations must be true. The StringDefinition is still returned even if the filtered translations list is empty.
]: nothing -> record<DescriptionForTranslator: string, DoNotTranslate: bool, Id: string, ParameterCount: int, Timestamp: string, Translations: table<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "includeTranslations" $include_translations "scalar") (serialize-qp "includeDeletedLanguages" $include_deleted_languages "scalar") (serialize-qp "languageIds" $language_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/StringDefinitions/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeTranslations": $include_translations, "includeDeletedLanguages": $include_deleted_languages, "languageIds": $language_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a paged response of Global String Translations.
#
# GET /api/v2/StringTranslations
# operationId: StringTranslations_GetTranslations
export def "string-translations get" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --modified-after-timestamp: string # Optional. Return only the StringDefinition objects that have a Timestamp value greater than that provided. This will be an encoded byte array.
]: nothing -> record<Entities: table<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "modifiedAfterTimestamp" $modified_after_timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/StringTranslations" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "modifiedAfterTimestamp": $modified_after_timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update corrections to string translations
#
# PUT /api/v2/StringTranslations/Batch
# operationId: StringTranslations_UpdateTranslations
export def "string-translations-batch update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/StringTranslations/Batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a single translation based upon stringId and languageId
#
# GET /api/v2/StringTranslations/{stringId}/{languageId}
# operationId: StringTranslations_GetTranslation
export def "string-translations get-by-string-id-language-id" [
  string_id: string
  language_id: int
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
]: nothing -> record<AuthorId: int, LanguageId: int, State: string, StringId: string, StringValue: string, Timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($string_id | is-empty) { error make --unspanned { msg: "path parameter 'stringId' must be non-empty" } }
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageId' must be non-empty" } }
  let full_url = (build-url $base ({string_id: (encode-path-segment $string_id), language_id: (encode-path-segment $language_id)} | format pattern "/api/v2/StringTranslations/{string_id}/{language_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a string value or a state for a string translation.
#
# PUT /api/v2/StringTranslations/{stringId}/{languageId}
# operationId: StringTranslations_UpdateTranslation
export def "string-translations update" [
  string_id: string
  language_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-id: int # The id of the user to last edit thie translation (format: int32)
  --body-language-id: int # The id of the language of the translation (format: int32)
  --state: string@state-completer-3 # The state of the translation
  --body-string-id: string # The id of the string that is translated
  string_value: string # The translated string
  --timestamp: string # A value indicating the last modification of this translation. Read Only. (format: byte)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($string_id | is-empty) { error make --unspanned { msg: "path parameter 'stringId' must be non-empty" } }
  if ($language_id | is-empty) { error make --unspanned { msg: "path parameter 'languageId' must be non-empty" } }
  let full_url = (build-url $base ({string_id: (encode-path-segment $string_id), language_id: (encode-path-segment $language_id)} | format pattern "/api/v2/StringTranslations/{string_id}/{language_id}") $auth.query)
  let req_body = {"AuthorId": $author_id, "LanguageId": $body_language_id, "State": $state, "StringId": $body_string_id, "StringValue": $string_value, "Timestamp": $timestamp} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a paged response of TranslationKeys.
#
# GET /api/v2/TranslationKeys
# operationId: TranslationKeys_Get
export def "translation-keys list" [
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
  --limit: int # format: int32
  --offset: int # format: int32
  --key-names: string # Can filter by keyNames, a comma deliminated list.
]: nothing -> record<Entities: table<ID: int, KeyName: string, StringID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "keyNames" $key_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/TranslationKeys" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "keyNames": $key_names} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a translationKey object.
#
# POST /api/v2/TranslationKeys
# operationId: TranslationKeys_CreateTranslationKey
export def "translation-keys create" [
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
  --id: int # The identifier for the translationKey. Read Only. (format: int32)
  key_name: string # The key name of the item. One example is tkODX_HWIKM14R01
  string_id: string # Foreign key to StringDefinitionID
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/TranslationKeys" $auth.query)
  let req_body = {"ID": $id, "KeyName": $key_name, "StringID": $string_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get TranslationKey by ID
#
# GET /api/v2/TranslationKeys/{ID}
# operationId: TranslationKeys_GetTranslationKey
export def "translation-keys get" [
  id: int
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
]: nothing -> record<ID: int, KeyName: string, StringID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationKeys/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update the StringID of the translationKey object.
#
# PUT /api/v2/TranslationKeys/{ID}
# operationId: TranslationKeys_UpdateTranslationKey
export def "translation-keys update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: int # The identifier for the translationKey. Read Only. (format: int32)
  key_name: string # The key name of the item. One example is tkODX_HWIKM14R01
  string_id: string # Foreign key to StringDefinitionID
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationKeys/{id}") $auth.query)
  let req_body = {"ID": $body_id, "KeyName": $key_name, "StringID": $string_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get all TranslationRequest objects. Returns a PagedResponse of TranslationRequest objects with their language ids and string ids.
#
# GET /api/v2/TranslationRequests
# operationId: TranslationRequests_GetTranslationRequests
export def "translation-requests list" [
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
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> record<Entities: table<ApprovalUserId: int, CCEmailAddresses: list, ChargeToAccount: string, Deadline: string, Id: int, LocaleIds: list, Notes: string, QuestionsUserId: int, State: string, SubmittedBy: int, TranslatorEmail: string, TranslatorName: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/TranslationRequests" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a translation request. Accepts a TranslationRequest object. Returns the Id of the created object. The state of the TranslationRequest must be ‘NotSubmitted’.
#
# POST /api/v2/TranslationRequests
# operationId: TranslationRequests_CreateTranslationRequest
export def "translation-requests create" [
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
  --approval-user-id: int # The ID of the user from which approval for the request is required (format: int32)
  cc_email_addresses: list<string> # Additional email addresses to CC on emails pertaining to the request
  charge_to_account: string # The account to charge for the request
  deadline: string # The date by which the translations in the request are needed. Defaults to 30 days from the current date (format: date-time)
  --id: int # The ID of the request (format: int32)
  locale_ids: list<int> # Locale IDs to which these strings are requested to be translated
  notes: string # Additional notes or comments about the request
  --questions-user-id: int # The ID of the user to which to address questions regarding the request (format: int32)
  state: string@state-completer-4 # The state of the request
  --submitted-by: int # The ID of the User that submitted the request (format: int32)
  --translator-email: string # The email address for the translator
  --translator-name: string # The name of the translator
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/TranslationRequests" $auth.query)
  let req_body = {"ApprovalUserId": $approval_user_id, "CCEmailAddresses": $cc_email_addresses, "ChargeToAccount": $charge_to_account, "Deadline": $deadline, "Id": $id, "LocaleIds": $locale_ids, "Notes": $notes, "QuestionsUserId": $questions_user_id, "State": $state, "SubmittedBy": $submitted_by, "TranslatorEmail": $translator_email, "TranslatorName": $translator_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get a TranslationRequest object by id. Returns TranslationRequest object with its language ids and string ids.
#
# GET /api/v2/TranslationRequests/{Id}
# operationId: TranslationRequests_GetTranslationRequest
export def "translation-requests get" [
  id: int
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
]: nothing -> record<ApprovalUserId: int, CCEmailAddresses: list<string>, ChargeToAccount: string, Deadline: string, Id: int, LocaleIds: list<int>, Notes: string, QuestionsUserId: int, State: string, SubmittedBy: int, TranslatorEmail: string, TranslatorName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationRequests/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a TranslationRequest object by id. Accepts a TranslationRequest object.
#
# PUT /api/v2/TranslationRequests/{Id}
# operationId: TranslationRequests_UpdateTranslationRequest
export def "translation-requests update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --do-resend-request: oneof<nothing, bool>
  --approval-user-id: int # The ID of the user from which approval for the request is required (format: int32)
  cc_email_addresses: list<string> # Additional email addresses to CC on emails pertaining to the request
  charge_to_account: string # The account to charge for the request
  deadline: string # The date by which the translations in the request are needed. Defaults to 30 days from the current date (format: date-time)
  --body-id: int # The ID of the request (format: int32)
  locale_ids: list<int> # Locale IDs to which these strings are requested to be translated
  notes: string # Additional notes or comments about the request
  --questions-user-id: int # The ID of the user to which to address questions regarding the request (format: int32)
  state: string@state-completer-4 # The state of the request
  --submitted-by: int # The ID of the User that submitted the request (format: int32)
  --translator-email: string # The email address for the translator
  --translator-name: string # The name of the translator
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let qp = [(serialize-qp "doResendRequest" $do_resend_request "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationRequests/{id}") $qp $auth.query)
  let req_body = {"ApprovalUserId": $approval_user_id, "CCEmailAddresses": $cc_email_addresses, "ChargeToAccount": $charge_to_account, "Deadline": $deadline, "Id": $body_id, "LocaleIds": $locale_ids, "Notes": $notes, "QuestionsUserId": $questions_user_id, "State": $state, "SubmittedBy": $submitted_by, "TranslatorEmail": $translator_email, "TranslatorName": $translator_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"doResendRequest": $do_resend_request} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# No Documentation Found.
#
# PUT /api/v2/TranslationRequests/{Id}/Strings
# operationId: TranslationRequests_UpdateTranslationRequestStrings
export def "translation-requests-strings update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'Id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationRequests/{id}/Strings") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# No Documentation Found.
#
# PUT /api/v2/TranslationSetAttributes/Batch
# operationId: TranslationSets_UpdateTranslationSetAttributes
export def "translation-set-attributes-batch update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/TranslationSetAttributes/Batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete a set of TranslationSetAttribute object
#
# DELETE /api/v2/TranslationSetAttributes/{ID}
# operationId: TranslationSets_DeleteTranslationSetAttribute
export def "translation-set-attributes delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSetAttributes/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Update a TranslationSetAttribute object
#
# PUT /api/v2/TranslationSetAttributes/{ID}
# operationId: TranslationSets_UpdateTranslationSetAttribute
export def "translation-set-attributes update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --translation-set-id: int # The ID of the translation set to which this attribute belongs. (format: int32)
  --value: string # The value of this Attribute
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSetAttributes/{id}") $auth.query)
  let req_body = {"ID": $body_id, "Name": $name, "TranslationSetID": $translation_set_id, "Value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a PagedResponse of TranslationSet objects. Related TranslationSetStrings are NOT returned
#
# GET /api/v2/TranslationSets
# operationId: TranslationSets_GetTranslationSets
export def "translation-sets list" [
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
  --limit: int # format: int32
  --offset: int # format: int32
  --translation-request-id: int # format: int32
  --state: string@state-completer-5
  --string-id: string
  --language-id: int # format: int32
  --include-attributes: string # Names of Attributes to include when retrieving this submission. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> record<Entities: table<Attributes: list, FileIDs: list, Id: int, InDate: string, Notes: string, OutDate: string, State: string, TranslationRequestID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "translationRequestID" $translation_request_id "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "stringId" $string_id "scalar") (serialize-qp "languageId" $language_id "scalar") (serialize-qp "includeAttributes" $include_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/TranslationSets" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "translationRequestID": $translation_request_id, "state": $state, "stringId": $string_id, "languageId": $language_id, "includeAttributes": $include_attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a TranslationSet object by its id. Related TranslationSetStrings are NOT returned.
#
# GET /api/v2/TranslationSets/{ID}
# operationId: TranslationSets_GetTranslationSet
export def "translation-sets get" [
  id: int
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
  --include-attributes: string # Names of Attributes to include when retrieving this Translation set. This should be a comma-separated list. If not provided, Attributes are not included. If '*', all Attributes are included.
]: nothing -> record<Attributes: table<ID: int, Name: string, TranslationSetID: int, Value: string>, FileIDs: list<string>, Id: int, InDate: string, Notes: string, OutDate: string, State: string, TranslationRequestID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "includeAttributes" $include_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeAttributes": $include_attributes} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Translation Set. Accepts a TranslationSet object. Only the state property may be updated.
#
# PUT /api/v2/TranslationSets/{ID}
# operationId: TranslationSets_UpdateTranslationSet
# --Attributes item shape: {ID?: int, Name: string, TranslationSetID?: int, Value?: string}
export def "translation-sets update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Attributes of the Translation Set — item shape: {ID?: int, Name: string, TranslationSetID?: int, Value?: string}
  file_i_ds: list<string> # IDs for files related to this translation set. For example, the original and processed files
  --body-id: int # The id of the TranslationSet. (format: int32)
  --in-date: string # Read Only. The date the translation set was returned. (format: date-time)
  --notes: string # Notes on the TranslationSet
  --out-date: string # Read Only. The date the translation set was sent out. (format: date-time)
  state: string@state-completer-5 # An enum indicating the state of the translation set
  --translation-request-id: int # Read Only. The Id of the TranslationRequest which generated this translation set. (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}") $auth.query)
  let req_body = {"Attributes": $attributes, "FileIDs": $file_i_ds, "Id": $body_id, "InDate": $in_date, "Notes": $notes, "OutDate": $out_date, "State": $state, "TranslationRequestID": $translation_request_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a PagedResponse of TranslationSetAttribute objects
#
# GET /api/v2/TranslationSets/{ID}/Attributes
# operationId: TranslationSets_GetTranslationSetAttributes
export def "translation-sets-attributes get" [
  id: int
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
  --limit: int # format: int32
  --offset: int # format: int32
  --name: string
]: nothing -> record<Entities: table<ID: int, Name: string, TranslationSetID: int, Value: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}/Attributes") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a TranslationSetAttribute object
#
# POST /api/v2/TranslationSets/{ID}/Attributes
# operationId: TranslationSets_PostTranslationSetAttribute
export def "translation-sets-attributes create" [
  id: int
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
  --body-id: int # The ID of this attribute. (format: int32)
  name: string # The name of this Attribute.
  --translation-set-id: int # The ID of the translation set to which this attribute belongs. (format: int32)
  --value: string # The value of this Attribute
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}/Attributes") $auth.query)
  let req_body = {"ID": $body_id, "Name": $name, "TranslationSetID": $translation_set_id, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# No Documentation Found.
#
# POST /api/v2/TranslationSets/{ID}/Attributes/Batch
# operationId: TranslationSets_PostTranslationSetAttributes
export def "translation-sets-attributes-batch create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}/Attributes/Batch") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets the information needed to translate a string in a translation set
#
# GET /api/v2/TranslationSets/{ID}/SourceStrings
# operationId: TranslationSets_GetSourceStrings
export def "translation-sets-source-strings get" [
  id: int
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
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> record<Entities: table<DescriptionForTranslator: string, LanguageID: int, StringID: string, StringValue: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}/SourceStrings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the statistics for translation sets such as the language ids and count of string definitions.
#
# GET /api/v2/TranslationSets/{ID}/Statistics
# operationId: TranslationSets_GetStatistics
export def "translation-sets-statistics get" [
  id: int
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
]: nothing -> record<LanguageIDs: list<int>, StringCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}/Statistics") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get a PagedResponse of TranslationSetString objects
#
# GET /api/v2/TranslationSets/{ID}/Strings
# operationId: TranslationSets_GetTranslationSetStrings
export def "translation-sets-strings get" [
  id: int
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
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> record<Entities: table<LanguageID: int, StringID: string, StringValue: string, TranslationSetId: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}/Strings") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# No Documentation Found.
#
# PUT /api/v2/TranslationSets/{ID}/Strings
# operationId: TranslationSets_UpdateTranslationSetStrings
export def "translation-sets-strings update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/TranslationSets/{id}/Strings") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a list of current Client Subscriptions.
#
# GET /api/v2/UpdateGroupClientRelationships
# operationId: UpdateGroupClientRelationships_GetSubscriptions
export def "update-group-client-relationships get-subscriptions" [
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
  --client-id: string # Optional. Filter by Client ID
  --update-group-id: string # Optional. Filter by Update Group ID
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --active: oneof<nothing, bool> # Optional. Filter by Active
]: nothing -> record<Entities: table<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $client_id "scalar") (serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "Active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateGroupClientRelationships" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ClientID": $client_id, "UpdateGroupID": $update_group_id, "limit": $limit, "offset": $offset, "Active": $active} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a subscription
#
# POST /api/v2/UpdateGroupClientRelationships
# operationId: UpdateGroupClientRelationships_PostSubscription
export def "update-group-client-relationships create-subscription" [
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
  --active: oneof<nothing, bool> # The subscription status. The status is active by default.
  client_id: string # Read Only after creation. The client id of the subscriber.
  --last-checkin: string # ReadOnly. The timestamp of the last checkin. (format: date-time)
  --relationship-id: string # Read Only after creation. The relationship id. A relationship id will be assigned if not provided on creation.
  update_group_id: string # Read Only after creation. The update group to subscribe to.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroupClientRelationships" $auth.query)
  let req_body = {"Active": $active, "ClientID": $client_id, "LastCheckin": $last_checkin, "RelationshipID": $relationship_id, "UpdateGroupID": $update_group_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# DEPRECATED. Set client subscription status for an update group.
#
# PUT /api/v2/UpdateGroupClientRelationships
# operationId: UpdateGroupClientRelationships_PutSubscriptionByClientIDUpdateGroupID
export def "update-group-client-relationships update-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The Client ID. This can be a client ID that has not been registered yet.
  --update-group-id: string # The Update Group ID
  --active: oneof<nothing, bool> # Subscribe the client to the Update Group.
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $client_id "scalar") (serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "Active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateGroupClientRelationships" $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"ClientID": $client_id, "UpdateGroupID": $update_group_id, "Active": $active} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Get a subscription by RelationshipID
#
# GET /api/v2/UpdateGroupClientRelationships/{RelationshipID}
# operationId: UpdateGroupClientRelationships_GetSubscription
export def "update-group-client-relationships get-subscription" [
  relationship_id: string
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
]: nothing -> record<Active: bool, ClientID: string, LastCheckin: string, RelationshipID: string, UpdateGroupID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($relationship_id | is-empty) { error make --unspanned { msg: "path parameter 'RelationshipID' must be non-empty" } }
  let full_url = (build-url $base ({relationship_id: (encode-path-segment $relationship_id)} | format pattern "/api/v2/UpdateGroupClientRelationships/{relationship_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Updates a Subscription
#
# PUT /api/v2/UpdateGroupClientRelationships/{RelationshipID}
# operationId: UpdateGroupClientRelationships_PutSubscription
export def "update-group-client-relationships update-subscription-by-relationship-id" [
  relationship_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # The subscription status. The status is active by default.
  client_id: string # Read Only after creation. The client id of the subscriber.
  --last-checkin: string # ReadOnly. The timestamp of the last checkin. (format: date-time)
  --body-relationship-id: string # Read Only after creation. The relationship id. A relationship id will be assigned if not provided on creation.
  update_group_id: string # Read Only after creation. The update group to subscribe to.
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($relationship_id | is-empty) { error make --unspanned { msg: "path parameter 'RelationshipID' must be non-empty" } }
  let full_url = (build-url $base ({relationship_id: (encode-path-segment $relationship_id)} | format pattern "/api/v2/UpdateGroupClientRelationships/{relationship_id}") $auth.query)
  let req_body = {"Active": $active, "ClientID": $client_id, "LastCheckin": $last_checkin, "RelationshipID": $body_relationship_id, "UpdateGroupID": $update_group_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Update Group Subscriptions
#
# GET /api/v2/UpdateGroupSubscriptions
# operationId: UpdateGroupSubscriptions_GetUpdateGroupSubscriptions
export def "update-group-subscriptions list" [
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
  --update-group-id: string # Optional. Filter by Update Group ID.
  --package-type-id: string # Optional. Filter by Package Type ID.
  --client-id: string # Optional. Filter by Client ID.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdateGroupID" $update_group_id "scalar") (serialize-qp "PackageTypeID" $package_type_id "scalar") (serialize-qp "ClientID" $client_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateGroupSubscriptions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdateGroupID": $update_group_id, "PackageTypeID": $package_type_id, "ClientID": $client_id, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add an Update Group Subscription
#
# POST /api/v2/UpdateGroupSubscriptions
# operationId: UpdateGroupSubscriptions_PostUpdateGroupSubscription
export def "update-group-subscriptions create" [
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
  client_id: string # The ClientID.
  --include: oneof<nothing, bool> # True to receive content of type indicated by PackageTypeID.
  package_type_id: string # The PackageType to set subscription status for
  update_group_id: string # The Update Group this subscription is relevant for.
  --update-group-subscription-id: int # The Update Group Subscription ID. This ID will be automatically assigned when creating an Update Group Subscription. (format: int32)
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroupSubscriptions" $auth.query)
  let req_body = {"ClientID": $client_id, "Include": $include, "PackageTypeID": $package_type_id, "UpdateGroupID": $update_group_id, "UpdateGroupSubscriptionID": $update_group_subscription_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# No Documentation Found.
#
# POST /api/v2/UpdateGroupSubscriptions/Batch
# operationId: UpdateGroupSubscriptions_PostUpdateGroupSubscriptions
export def "update-group-subscriptions-batch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroupSubscriptions/Batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# No Documentation Found.
#
# PUT /api/v2/UpdateGroupSubscriptions/Batch
# operationId: UpdateGroupSubscriptions_PutUpdateGroupSubscriptions
export def "update-group-subscriptions-batch update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroupSubscriptions/Batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete an Update Group Subscription
#
# DELETE /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# operationId: UpdateGroupSubscriptions_DeleteUpdateGroupSubscription
export def "update-group-subscriptions delete" [
  update_group_subscription_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($update_group_subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'UpdateGroupSubscriptionID' must be non-empty" } }
  let full_url = (build-url $base ({update_group_subscription_id: (encode-path-segment $update_group_subscription_id)} | format pattern "/api/v2/UpdateGroupSubscriptions/{update_group_subscription_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get an Update Group Subscription
#
# GET /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# operationId: UpdateGroupSubscriptions_GetUpdateGroupSubscription
export def "update-group-subscriptions get" [
  update_group_subscription_id: int
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
]: nothing -> record<ClientID: string, Include: bool, PackageTypeID: string, UpdateGroupID: string, UpdateGroupSubscriptionID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($update_group_subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'UpdateGroupSubscriptionID' must be non-empty" } }
  let full_url = (build-url $base ({update_group_subscription_id: (encode-path-segment $update_group_subscription_id)} | format pattern "/api/v2/UpdateGroupSubscriptions/{update_group_subscription_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update an Update Group Subscription
#
# PUT /api/v2/UpdateGroupSubscriptions/{UpdateGroupSubscriptionID}
# operationId: UpdateGroupSubscriptions_PutUpdateGroupSubscription
export def "update-group-subscriptions update" [
  update_group_subscription_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # The ClientID.
  --include: oneof<nothing, bool> # True to receive content of type indicated by PackageTypeID.
  package_type_id: string # The PackageType to set subscription status for
  update_group_id: string # The Update Group this subscription is relevant for.
  --body-update-group-subscription-id: int # The Update Group Subscription ID. This ID will be automatically assigned when creating an Update Group Subscription. (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($update_group_subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'UpdateGroupSubscriptionID' must be non-empty" } }
  let full_url = (build-url $base ({update_group_subscription_id: (encode-path-segment $update_group_subscription_id)} | format pattern "/api/v2/UpdateGroupSubscriptions/{update_group_subscription_id}") $auth.query)
  let req_body = {"ClientID": $client_id, "Include": $include, "PackageTypeID": $package_type_id, "UpdateGroupID": $update_group_id, "UpdateGroupSubscriptionID": $body_update_group_subscription_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a list of Update Groups. Update Groups are used by the client to register for a specific type of update.
#
# GET /api/v2/UpdateGroups
# operationId: UpdateGroups_Get
export def "update-groups list" [
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
  --user-id: int # Optional. The user ID to sort update groups by the user's access (format: int32)
]: nothing -> record<Entities: table<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateGroups" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "userID": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a new Update Group. The report field is a string that has a dot based request for a specific piece of submitted data.
#
# POST /api/v2/UpdateGroups
# operationId: UpdateGroups_Post
export def "update-groups create" [
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
  description: string # The description of the update group
  --id: string
  --inventory-frequency: int # The time in minutes between inventory checks. Default value is 1440 minutes (one day). (format: int32)
  --inventory-package: string # The Package ID of the package used for inventory
  --localized-description: string # Optional. The StringID used to localize the description of the update group
  --localized-name: string # Optional. The StringID used to localize the name of the update group
  priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --report-field: string # A field to return in the status report for this update group. Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}. (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  update_type: string # The update type name
  --validating-field: string # A field used for validation in the status report for this update group. Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}. (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  --value-to-validate: string # The value to validate the ValidationField against.
  --version: string # The version of the UpdateGroup, this value is incremented with each modification to a related Bundle or PackageType (format: byte)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UpdateGroups" $auth.query)
  let req_body = {"Description": $description, "ID": $id, "InventoryFrequency": $inventory_frequency, "InventoryPackage": $inventory_package, "LocalizedDescription": $localized_description, "LocalizedName": $localized_name, "Priority": $priority, "ReportField": $report_field, "UpdateType": $update_type, "ValidatingField": $validating_field, "ValueToValidate": $value_to_validate, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete an Update Group.
#
# DELETE /api/v2/UpdateGroups/{ID}
# operationId: UpdateGroups_Delete
export def "update-groups delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/UpdateGroups/{id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a specific Update Group by ID.
#
# GET /api/v2/UpdateGroups/{ID}
export def "update-groups get" [
  id: string
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
]: nothing -> record<Description: string, ID: string, InventoryFrequency: int, InventoryPackage: string, LocalizedDescription: string, LocalizedName: string, Priority: int, ReportField: string, UpdateType: string, ValidatingField: string, ValueToValidate: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/UpdateGroups/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Modify an Update Group.
#
# PUT /api/v2/UpdateGroups/{ID}
# operationId: UpdateGroups_Put
export def "update-groups update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # The description of the update group
  --body-id: string
  --inventory-frequency: int # The time in minutes between inventory checks. Default value is 1440 minutes (one day). (format: int32)
  --inventory-package: string # The Package ID of the package used for inventory
  --localized-description: string # Optional. The StringID used to localize the description of the update group
  --localized-name: string # Optional. The StringID used to localize the name of the update group
  priority: int # The execution priority of the package relative to other packages in the bundle. Range 1 - 100, lower value indication higher priority. (format: int32)
  --report-field: string # A field to return in the status report for this update group. Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}. (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  update_type: string # The update type name
  --validating-field: string # A field used for validation in the status report for this update group. Specify the field with the format [Label]: {[InventoryPackageID].[Category].[Attribute]}. (i.e. example: {bec778ca-278d-424a-867a-4653a1a19e86.MyCategory.MyAttribute})
  --value-to-validate: string # The value to validate the ValidationField against.
  --version: string # The version of the UpdateGroup, this value is incremented with each modification to a related Bundle or PackageType (format: byte)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/UpdateGroups/{id}") $auth.query)
  let req_body = {"Description": $description, "ID": $body_id, "InventoryFrequency": $inventory_frequency, "InventoryPackage": $inventory_package, "LocalizedDescription": $localized_description, "LocalizedName": $localized_name, "Priority": $priority, "ReportField": $report_field, "UpdateType": $update_type, "ValidatingField": $validating_field, "ValueToValidate": $value_to_validate, "Version": $version} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a list of bundles for UpdateGroup.
#
# GET /api/v2/UpdateGroups/{ID}/Bundles
# operationId: UpdateGroups_GetUpdateGroupBundles
export def "update-groups-bundles get" [
  id: string
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
  --include-inactive: oneof<nothing, bool> # Include Inactive Bundles (true|false)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Active: bool, BundleID: string, BundleNumber: int, Description: string, UpdateGroupID: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let qp = [(serialize-qp "IncludeInactive" $include_inactive "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/UpdateGroups/{id}/Bundles") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"IncludeInactive": $include_inactive, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an update group a user could see.
#
# DELETE /api/v2/UpdateGroups/{id}/Users/{userID}
# operationId: UpdateGroups_RemoveUpdateGroupUser
export def "update-groups-users delete" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/api/v2/UpdateGroups/{id}/Users/{user_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Add an updateGroup that a user can see.
#
# POST /api/v2/UpdateGroups/{id}/Users/{userID}
# operationId: UpdateGroups_AddUpdateGroupUser
export def "update-groups-users create" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userID' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), user_id: (encode-path-segment $user_id)} | format pattern "/api/v2/UpdateGroups/{id}/Users/{user_id}") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Checks the Client ID into the Update System.
#
# GET /api/v2/UpdateSystem
# operationId: UpdateSystem_GetCheckin
export def "update-system get-checkin" [
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
  --client-id: string # The Client ID to check-in. If this is a new client ID it will be added to Clients.
  --preview: oneof<nothing, bool> # Get Pkgs w\o updating Datetimes(true|false)
  --run-all-inventories: oneof<nothing, bool> # Force return inventories. Defaults to false.
]: nothing -> record<Packages: table<Autorun: bool, CRC: string, Description: string, LocalizedName: string, Notes: string, PackageID: string, PackageTypeID: string, PreviousVersion: int, ReleaseDate: string, Released: bool, RemoveOnSuccess: bool, Size: int, Switches: string, Url: string, Version: int>, RemovePackages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClientID" $client_id "scalar") (serialize-qp "Preview" $preview "scalar") (serialize-qp "RunAllInventories" $run_all_inventories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UpdateSystem" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ClientID": $client_id, "Preview": $preview, "RunAllInventories": $run_all_inventories} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get UserContentDefinitions
#
# GET /api/v2/UserContentDefinitions
# operationId: UserContentDefinitions_GetUserContentDefinitions
export def "user-content-definitions list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --user-id: int # Optional. Filter by UserID. (format: int32)
  --content-definition-id: int # Optional. Filter by ContentDefinitionID (format: int32)
]: nothing -> record<Entities: table<ContentDefinitionID: int, UserContentDefinitionID: int, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "userID" $user_id "scalar") (serialize-qp "contentDefinitionID" $content_definition_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/UserContentDefinitions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "userID": $user_id, "contentDefinitionID": $content_definition_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a UserContentDefinition
#
# POST /api/v2/UserContentDefinitions
# operationId: UserContentDefinitions_PostUserContentDefinition
export def "user-content-definitions create" [
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
  --content-definition-id: int # The ID of the ContentDefinition. (format: int32)
  --user-content-definition-id: int # Read Only. The ID of the User to ContentDefinition relationship. (format: int32)
  --user-id: int # The ID of the user. (format: int32)
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/UserContentDefinitions" $auth.query)
  let req_body = {"ContentDefinitionID": $content_definition_id, "UserContentDefinitionID": $user_content_definition_id, "UserID": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a UserContentDefinition
#
# DELETE /api/v2/UserContentDefinitions/{userContentDefinitionID}
# operationId: UserContentDefinitions_DeleteUserContentDefinition
export def "user-content-definitions delete" [
  user_content_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_content_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'userContentDefinitionID' must be non-empty" } }
  let full_url = (build-url $base ({user_content_definition_id: (encode-path-segment $user_content_definition_id)} | format pattern "/api/v2/UserContentDefinitions/{user_content_definition_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a UserContentDefinition by ID
#
# GET /api/v2/UserContentDefinitions/{userContentDefinitionID}
# operationId: UserContentDefinitions_GetUserContentDefinition
export def "user-content-definitions get" [
  user_content_definition_id: int
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
]: nothing -> record<ContentDefinitionID: int, UserContentDefinitionID: int, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_content_definition_id | is-empty) { error make --unspanned { msg: "path parameter 'userContentDefinitionID' must be non-empty" } }
  let full_url = (build-url $base ({user_content_definition_id: (encode-path-segment $user_content_definition_id)} | format pattern "/api/v2/UserContentDefinitions/{user_content_definition_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get users
#
# GET /api/v2/Users
# operationId: Users_Get
export def "users list" [
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
  --username: string # Optional. Search by username. Supports beginning and ending wildcards (*).
  --email: string # Optional. Search by email. Supports beginning and ending wildcards (*).
  --name: string # Optional. Search by name. Supports beginning and ending wildcards (*).
  --has-role: string # Optional. Return only users having the provided role name.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "hasRole" $has_role "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Users" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"username": $username, "email": $email, "name": $name, "hasRole": $has_role, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a user
#
# POST /api/v2/Users
# operationId: Users_Post
export def "users create" [
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
  --change-password: string # Never Returned. When changing a user's password, this field must contain the new password.
  --email: string # The user's email address
  --name: string # The user's name
  --password: string # Never Returned. Required when creating a new user or updating a user. When changing a user's password this field must contain the current password.
  --user-id: int # The user ID (format: int32)
  --username: string # The username used for authentication
]: any -> record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Users" $auth.query)
  let req_body = {"ChangePassword": $change_password, "Email": $email, "Name": $name, "Password": $password, "UserID": $user_id, "Username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets the current user
#
# GET /api/v2/Users/Current
# operationId: Users_GetCurrentUser
export def "users-current get" [
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
]: nothing -> record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Users/Current" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a user
#
# PUT /api/v2/Users/Current
# operationId: Users_PutCurrentUser
export def "users-current update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --change-password: string # Never Returned. When changing a user's password, this field must contain the new password.
  --email: string # The user's email address
  --name: string # The user's name
  --password: string # Never Returned. Required when creating a new user or updating a user. When changing a user's password this field must contain the current password.
  --user-id: int # The user ID (format: int32)
  --username: string # The username used for authentication
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Users/Current" $auth.query)
  let req_body = {"ChangePassword": $change_password, "Email": $email, "Name": $name, "Password": $password, "UserID": $user_id, "Username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a user's permissions
#
# GET /api/v2/Users/Current/Permissions
export def "users-current-permissions get" [
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
  --permission: string # Filter by permission name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<PermissionId: int, PermissionName: string, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Permission" $permission "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Users/Current/Permissions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Permission": $permission, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the current user's roles
#
# GET /api/v2/Users/Current/Roles
# operationId: UserPermissions_GetCurrentUserRoles
export def "users-current-roles get-permissions" [
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
  --role: string # Filter by role name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Role" $role "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Users/Current/Roles" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Role": $role, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a user
#
# DELETE /api/v2/Users/{id}
# operationId: Users_Delete
export def "users delete" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Users/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a specific user
#
# GET /api/v2/Users/{id}
export def "users get" [
  id: int
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
]: nothing -> record<ChangePassword: string, Email: string, Name: string, Password: string, UserID: int, Username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Users/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update a user
#
# PUT /api/v2/Users/{id}
# operationId: Users_Put
export def "users update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --change-password: string # Never Returned. When changing a user's password, this field must contain the new password.
  --email: string # The user's email address
  --name: string # The user's name
  --password: string # Never Returned. Required when creating a new user or updating a user. When changing a user's password this field must contain the current password.
  --user-id: int # The user ID (format: int32)
  --username: string # The username used for authentication
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Users/{id}") $auth.query)
  let req_body = {"ChangePassword": $change_password, "Email": $email, "Name": $name, "Password": $password, "UserID": $user_id, "Username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a user's permissions
#
# GET /api/v2/Users/{id}/Permissions
# operationId: UserPermissions_GetPermissions
export def "users-permissions get" [
  id: int
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
  --permission: string # Filter by permission name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<PermissionId: int, PermissionName: string, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "Permission" $permission "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Users/{id}/Permissions") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Permission": $permission, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a user's roles
#
# GET /api/v2/Users/{id}/Roles
# operationId: UserPermissions_GetRoles
export def "users-roles get-permissions" [
  id: int
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
  --role: string # Filter by role name. Supports ending wildcard (*). Optional.
  --limit: int # The page limit. The default page limit is 10. (format: int32)
  --offset: int # The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<Description: string, Id: int, Name: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "Role" $role "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Users/{id}/Roles") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Role": $role, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a user's roles
#
# PUT /api/v2/Users/{id}/Roles
# operationId: UserPermissions_Put
export def "users-roles update-permissions" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v2/Users/{id}/Roles") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets voucher history data
#
# GET /api/v2/VoucherHistory
# operationId: VoucherHistory_GetVoucherHistory
export def "voucher-history get" [
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
  --voucher-code: string # Optional. Filter history data by Voucher Code.
  --changed-before: string # Optional. Filter history data where changes occured before provided date. (format: date-time)
  --changed-after: string # Optional. Filter history data where changes occured after provided date. (format: date-time)
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ChangedDate: string, CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, ID: int, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "VoucherCode" $voucher_code "scalar") (serialize-qp "ChangedBefore" $changed_before "scalar") (serialize-qp "ChangedAfter" $changed_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/VoucherHistory" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"VoucherCode": $voucher_code, "ChangedBefore": $changed_before, "ChangedAfter": $changed_after, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a list of vouchers
#
# GET /api/v2/Vouchers
# operationId: Vouchers_Get
export def "vouchers list" [
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
  --type: string@type-completer # Optional. Filter vouchers by Type
  --dealer-code: string # Optional. Filter vouchers by DealerCode
  --license-to: string # Optional. Filter vouchers by LicenseTo. Wildcard supported (*).
  --purpose: string # Optional. Filter vouchers by Purpose. Wildcard supported (*).
  --order-number: string # Optional. Filter vouchers by OrderNumber
  --email: string # Optional. Filter vouchers by Email. Wildcard supported (*).
  --modified-by: string # Optional. Filter vouchers by ModifiedBy
  --created-after: string # Optional. Filter vouchers by CreatedDate (format: date-time)
  --created-before: string # Optional. Filter vouchers by CreatedDate (format: date-time)
  --punched-after: string # Optional. Filter vouchers by PunchedDate (format: date-time)
  --punched-before: string # Optional. Filter vouchers by PunchedDate (format: date-time)
  --punched: oneof<nothing, bool> # Optional. Filter vouchers by Punched status
  --expiration-after: string # Optional. Filter vouchers by ExpirationDate (format: date-time)
  --expiration-before: string # Optional. Filter vouchers by ExpirationDate (format: date-time)
  --deleted: string@deleted-completer # Optional. Filter vouchers by Deleted state. By default only vouchers that are not deleted are returned.
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Type" $type "scalar") (serialize-qp "DealerCode" $dealer_code "scalar") (serialize-qp "LicenseTo" $license_to "scalar") (serialize-qp "Purpose" $purpose "scalar") (serialize-qp "OrderNumber" $order_number "scalar") (serialize-qp "Email" $email "scalar") (serialize-qp "ModifiedBy" $modified_by "scalar") (serialize-qp "CreatedAfter" $created_after "scalar") (serialize-qp "CreatedBefore" $created_before "scalar") (serialize-qp "PunchedAfter" $punched_after "scalar") (serialize-qp "PunchedBefore" $punched_before "scalar") (serialize-qp "Punched" $punched "scalar") (serialize-qp "ExpirationAfter" $expiration_after "scalar") (serialize-qp "ExpirationBefore" $expiration_before "scalar") (serialize-qp "Deleted" $deleted "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/Vouchers" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Type": $type, "DealerCode": $dealer_code, "LicenseTo": $license_to, "Purpose": $purpose, "OrderNumber": $order_number, "Email": $email, "ModifiedBy": $modified_by, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "PunchedAfter": $punched_after, "PunchedBefore": $punched_before, "Punched": $punched, "ExpirationAfter": $expiration_after, "ExpirationBefore": $expiration_before, "Deleted": $deleted, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a voucher
#
# POST /api/v2/Vouchers
# operationId: Vouchers_Post
export def "vouchers create" [
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
  --created-date: string # Read-Only. The date the voucher was created. (format: date-time)
  --dealer-code: string # The dealer code the voucher is assigned to. Required for commercial and right to repair vouchers.
  --deleted: oneof<nothing, bool> # Read-Only. True if voucher has been deleted.
  --email: string # Required for internal vouchers.
  --expiration-date: string # The expiration date of the voucher. Required for Temporary and Right to Repair Vouchers. (format: date-time)
  --license-to: string # Required for Internal Vouchers
  --modified-by: string # Read-Only. The user that made the last modification to the voucher.
  --order-number: string # The order number of a license. Required for Commercial and Right To Repair Vouchers. Not supported for other Vouchers.
  --punched: oneof<nothing, bool> # True if voucher has aleady been used. False if the voucher has not been used.
  --punched-date: string # Read-Only. The date the voucher was punched. (format: date-time)
  --purpose: string # Required for Internal Vouchers. Not supported for other Vouchers.
  --type: string@type-completer # The type of voucher. Commercial is the default if not specified.
  --voucher-code: string # The voucher code.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/Vouchers" $auth.query)
  let req_body = {"CreatedDate": $created_date, "DealerCode": $dealer_code, "Deleted": $deleted, "Email": $email, "ExpirationDate": $expiration_date, "LicenseTo": $license_to, "ModifiedBy": $modified_by, "OrderNumber": $order_number, "Punched": $punched, "PunchedDate": $punched_date, "Purpose": $purpose, "Type": $type, "VoucherCode": $voucher_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a voucher
#
# DELETE /api/v2/Vouchers/{VoucherCode}
# operationId: Vouchers_Delete
export def "vouchers delete" [
  voucher_code: string
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
  if ($voucher_code | is-empty) { error make --unspanned { msg: "path parameter 'VoucherCode' must be non-empty" } }
  let full_url = (build-url $base ({voucher_code: (encode-path-segment $voucher_code)} | format pattern "/api/v2/Vouchers/{voucher_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a voucher
#
# GET /api/v2/Vouchers/{VoucherCode}
export def "vouchers get" [
  voucher_code: string
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
  --deleted: string@deleted-completer # Optional. Filter vouchers by Deleted state. By default only vouchers that are not deleted are returned.
]: nothing -> record<CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voucher_code | is-empty) { error make --unspanned { msg: "path parameter 'VoucherCode' must be non-empty" } }
  let qp = [(serialize-qp "Deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voucher_code: (encode-path-segment $voucher_code)} | format pattern "/api/v2/Vouchers/{voucher_code}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Deleted": $deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a voucher
#
# PUT /api/v2/Vouchers/{VoucherCode}
# operationId: Vouchers_Put
export def "vouchers update" [
  voucher_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-date: string # Read-Only. The date the voucher was created. (format: date-time)
  --dealer-code: string # The dealer code the voucher is assigned to. Required for commercial and right to repair vouchers.
  --deleted: oneof<nothing, bool> # Read-Only. True if voucher has been deleted.
  --email: string # Required for internal vouchers.
  --expiration-date: string # The expiration date of the voucher. Required for Temporary and Right to Repair Vouchers. (format: date-time)
  --license-to: string # Required for Internal Vouchers
  --modified-by: string # Read-Only. The user that made the last modification to the voucher.
  --order-number: string # The order number of a license. Required for Commercial and Right To Repair Vouchers. Not supported for other Vouchers.
  --punched: oneof<nothing, bool> # True if voucher has aleady been used. False if the voucher has not been used.
  --punched-date: string # Read-Only. The date the voucher was punched. (format: date-time)
  --purpose: string # Required for Internal Vouchers. Not supported for other Vouchers.
  --type: string@type-completer # The type of voucher. Commercial is the default if not specified.
  --body-voucher-code: string # The voucher code.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voucher_code | is-empty) { error make --unspanned { msg: "path parameter 'VoucherCode' must be non-empty" } }
  let full_url = (build-url $base ({voucher_code: (encode-path-segment $voucher_code)} | format pattern "/api/v2/Vouchers/{voucher_code}") $auth.query)
  let req_body = {"CreatedDate": $created_date, "DealerCode": $dealer_code, "Deleted": $deleted, "Email": $email, "ExpirationDate": $expiration_date, "LicenseTo": $license_to, "ModifiedBy": $modified_by, "OrderNumber": $order_number, "Punched": $punched, "PunchedDate": $punched_date, "Purpose": $purpose, "Type": $type, "VoucherCode": $body_voucher_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get a voucher's history.
#
# GET /api/v2/Vouchers/{VoucherCode}/VoucherHistory
# operationId: Vouchers_GetVoucherHistory
export def "vouchers-voucher-history get" [
  voucher_code: string
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
  --limit: int # Optional. The page limit. The default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. The default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<ChangedDate: string, CreatedDate: string, DealerCode: string, Deleted: bool, Email: string, ExpirationDate: string, ID: int, LicenseTo: string, ModifiedBy: string, OrderNumber: string, Punched: bool, PunchedDate: string, Purpose: string, Type: string, VoucherCode: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($voucher_code | is-empty) { error make --unspanned { msg: "path parameter 'VoucherCode' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({voucher_code: (encode-path-segment $voucher_code)} | format pattern "/api/v2/Vouchers/{voucher_code}/VoucherHistory") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Activities
#
# GET /api/v2/activities
# operationId: Activities_GetActivities
export def "activities get" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted activity, or not
]: nothing -> record<Entities: table<ActivityID: int, Deleted: bool, Name: string, Parameters: list, Steps: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "isIncludeDeleted" $is_include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/activities" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "isIncludeDeleted": $is_include_deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an Activity
#
# POST /api/v2/activities
# operationId: Activities_PostActivity
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
# --Steps item shape: {ActivityID?: int, ActivityStepID?: int, ImplementationID?: string, RunOrder?: int, StepID?: int, StepName?: string, UseConfig?: string}
export def "activities create-activity" [
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
  --activity-id: int # The ID of the activity (format: int32)
  --deleted: oneof<nothing, bool>
  --name: string # The name of the activity
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/activities" $auth.query)
  let req_body = {"ActivityID": $activity_id, "Deleted": $deleted, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Mark the delete flag for the Activity
#
# DELETE /api/v2/activities/{activityID}
# operationId: Activities_DeleteActivity
export def "activities delete-activity" [
  activity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityID' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/api/v2/activities/{activity_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get an Activity by ID
#
# GET /api/v2/activities/{activityID}
# operationId: Activities_GetActivity
export def "activities get-activity" [
  activity_id: int
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
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted activity, or not
]: nothing -> record<ActivityID: int, Deleted: bool, Name: string, Parameters: table<Direction: string, Name: string, Type: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityID' must be non-empty" } }
  let qp = [(serialize-qp "isIncludeDeleted" $is_include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/api/v2/activities/{activity_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"isIncludeDeleted": $is_include_deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an Activity
#
# PUT /api/v2/activities/{activityID}
# operationId: Activities_PutActivity
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
# --Steps item shape: {ActivityID?: int, ActivityStepID?: int, ImplementationID?: string, RunOrder?: int, StepID?: int, StepName?: string, UseConfig?: string}
export def "activities update-activity" [
  activity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-activity-id: int # The ID of the activity (format: int32)
  --deleted: oneof<nothing, bool>
  --name: string # The name of the activity
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityID' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/api/v2/activities/{activity_id}") $auth.query)
  let req_body = {"ActivityID": $body_activity_id, "Deleted": $deleted, "Name": $name} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get ActivityRuns
#
# GET /api/v2/activityRuns
# operationId: ActivityRuns_GetActivityRuns
export def "activity-runs list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --status: string@status-completer-2 # Optional. Filter activity runs by status. Value should be a comma separated list of status to include. If not specified, the default status filter is “InProgress”.
]: nothing -> record<Entities: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/activityRuns" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "status": $status} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an ActivityRun by ID
#
# GET /api/v2/activityRuns/{activityRunID}
# operationId: ActivityRuns_GetActivityRun
export def "activity-runs get" [
  activity_run_id: int
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
]: nothing -> record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_run_id | is-empty) { error make --unspanned { msg: "path parameter 'activityRunID' must be non-empty" } }
  let full_url = (build-url $base ({activity_run_id: (encode-path-segment $activity_run_id)} | format pattern "/api/v2/activityRuns/{activity_run_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update an ActivityRun
#
# PUT /api/v2/activityRuns/{activityRunID}
# operationId: ActivityRuns_PutActivityRun
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Value?: string}
# --Status shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
# --Steps item shape: {ActivityID?: int, ActivityStepID?: int, ImplementationID?: string, RunOrder?: int, StepID?: int, StepName?: string, UseConfig?: string}
export def "activity-runs update" [
  activity_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-activity-run-id: int # The identifier for the ActivityRun (format: int32)
  --end-date: string # Read Only. The UTC date and time when the activity completed (format: date-time)
  --job-activity-id: int # Read Only. The ID of the Job Activity that defines this activity run (format: int32)
  --job-run-id: int # Read Only. The ID of the JobRun under which this ActivityRun is executing (format: int32)
  --start-date: string # Read Only. The UTC date and time when the activity started (format: date-time)
  status: record # A DTO for an IActivityRunStatus — shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_run_id | is-empty) { error make --unspanned { msg: "path parameter 'activityRunID' must be non-empty" } }
  let full_url = (build-url $base ({activity_run_id: (encode-path-segment $activity_run_id)} | format pattern "/api/v2/activityRuns/{activity_run_id}") $auth.query)
  let req_body = {"ActivityRunID": $body_activity_run_id, "EndDate": $end_date, "JobActivityID": $job_activity_id, "JobRunID": $job_run_id, "StartDate": $start_date, "Status": $status} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get the ActivityRunStatus of an ActivityRun
#
# GET /api/v2/activityRuns/{activityRunID}/status
# operationId: ActivityRuns_GetActivityRunStatus
export def "activity-runs-status get" [
  activity_run_id: int
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
]: nothing -> record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_run_id | is-empty) { error make --unspanned { msg: "path parameter 'activityRunID' must be non-empty" } }
  let full_url = (build-url $base ({activity_run_id: (encode-path-segment $activity_run_id)} | format pattern "/api/v2/activityRuns/{activity_run_id}/status") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update the ActivityRunStatus of an ActivityRun
#
# PUT /api/v2/activityRuns/{activityRunID}/status
# operationId: ActivityRuns_PutActivityRunStatus
export def "activity-runs-status update" [
  activity_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-step: int # The activity step currently executing, indicated by numeric order (format: int32)
  --status: string@status-completer-2 # The status of the ActivityRun
  --step-progress: int # The percent progress from the currently executing step. This value shall be null if progress is not available (format: int32)
  --step-status: string # The status text from the currently executing step
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_run_id | is-empty) { error make --unspanned { msg: "path parameter 'activityRunID' must be non-empty" } }
  let full_url = (build-url $base ({activity_run_id: (encode-path-segment $activity_run_id)} | format pattern "/api/v2/activityRuns/{activity_run_id}/status") $auth.query)
  let req_body = {"CurrentStep": $current_step, "Status": $status, "StepProgress": $step_progress, "StepStatus": $step_status} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Agents
#
# GET /api/v2/agents
# operationId: Agents_GetAgents
export def "agents get" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
]: nothing -> record<Entities: table<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record, StepConfigurations: list, UserID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/agents" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an Agent
#
# POST /api/v2/agents
# operationId: Agents_PostAgent
# --Status shape: {LastStatusUpdate?: string, Online: bool}
# --StepConfigurations item shape: {Configurations?: list<string>, StepImplementationID: string}
export def "agents create" [
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
  --agent-id: int # The id of the Agent (format: int32)
  keep_alive_interval: int # The 'Heartbeat Interval' used by the Build Agent. (format: int32)
  machine_name: string # The machine name of the computer the agent is running on
  status: record # A DTO for an IAgentStatus — shape: {LastStatusUpdate?: string, Online: bool}
  user_id: int # The UserID of the Agent (format: int32)
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/agents" $auth.query)
  let req_body = {"AgentID": $agent_id, "KeepAliveInterval": $keep_alive_interval, "MachineName": $machine_name, "Status": $status, "UserID": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get Agent associated with the current user
#
# GET /api/v2/agents/Current
# operationId: Agents_GetCurrentAgentAsync
export def "agents-current get-async" [
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
]: nothing -> record<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record<LastStatusUpdate: string, Online: bool>, StepConfigurations: table<Configurations: list, StepImplementationID: string>, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/agents/Current" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get the ActivityRun of Agent associated with the current user
#
# GET /api/v2/agents/Current/ActivityRun
# operationId: Agents_GetCurrentAgentActivityRun
export def "agents-current-activity-run get" [
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
]: nothing -> record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/agents/Current/ActivityRun" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Delete an Agent
#
# DELETE /api/v2/agents/{agentID}
# operationId: Agents_DeleteAgent
export def "agents delete" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($agent_id | is-empty) { error make --unspanned { msg: "path parameter 'agentID' must be non-empty" } }
  let full_url = (build-url $base ({agent_id: (encode-path-segment $agent_id)} | format pattern "/api/v2/agents/{agent_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get Agent
#
# GET /api/v2/agents/{agentID}
# operationId: Agents_GetAgentAsync
export def "agents get-async" [
  agent_id: int
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
]: nothing -> record<AgentID: int, KeepAliveInterval: int, MachineName: string, Status: record<LastStatusUpdate: string, Online: bool>, StepConfigurations: table<Configurations: list, StepImplementationID: string>, UserID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($agent_id | is-empty) { error make --unspanned { msg: "path parameter 'agentID' must be non-empty" } }
  let full_url = (build-url $base ({agent_id: (encode-path-segment $agent_id)} | format pattern "/api/v2/agents/{agent_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update an Agent
#
# PUT /api/v2/agents/{agentID}
# operationId: Agents_PutAgent
# --Status shape: {LastStatusUpdate?: string, Online: bool}
# --StepConfigurations item shape: {Configurations?: list<string>, StepImplementationID: string}
export def "agents update" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-agent-id: int # The id of the Agent (format: int32)
  keep_alive_interval: int # The 'Heartbeat Interval' used by the Build Agent. (format: int32)
  machine_name: string # The machine name of the computer the agent is running on
  status: record # A DTO for an IAgentStatus — shape: {LastStatusUpdate?: string, Online: bool}
  user_id: int # The UserID of the Agent (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($agent_id | is-empty) { error make --unspanned { msg: "path parameter 'agentID' must be non-empty" } }
  let full_url = (build-url $base ({agent_id: (encode-path-segment $agent_id)} | format pattern "/api/v2/agents/{agent_id}") $auth.query)
  let req_body = {"AgentID": $body_agent_id, "KeepAliveInterval": $keep_alive_interval, "MachineName": $machine_name, "Status": $status, "UserID": $user_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get an Agent's ActivityRun
#
# GET /api/v2/agents/{agentID}/ActivityRun
# operationId: Agents_GetAgentActivityRun
export def "agents-activity-run get" [
  agent_id: int
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
]: nothing -> record<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: record<CurrentStep: int, Status: string, StepProgress: int, StepStatus: string>, Steps: table<ActivityID: int, ActivityStepID: int, ImplementationID: string, ParameterMappings: list, RunOrder: int, StepID: int, StepName: string, UseConfig: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($agent_id | is-empty) { error make --unspanned { msg: "path parameter 'agentID' must be non-empty" } }
  let full_url = (build-url $base ({agent_id: (encode-path-segment $agent_id)} | format pattern "/api/v2/agents/{agent_id}/ActivityRun") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Update the ActivityRun assigned to the Agent.
#
# PUT /api/v2/agents/{agentID}/ActivityRun
# operationId: Agents_PutAgentActivityRun
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Value?: string}
# --Status shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
# --Steps item shape: {ActivityID?: int, ActivityStepID?: int, ImplementationID?: string, RunOrder?: int, StepID?: int, StepName?: string, UseConfig?: string}
export def "agents-activity-run update" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-run-id: int # The identifier for the ActivityRun (format: int32)
  --end-date: string # Read Only. The UTC date and time when the activity completed (format: date-time)
  --job-activity-id: int # Read Only. The ID of the Job Activity that defines this activity run (format: int32)
  --job-run-id: int # Read Only. The ID of the JobRun under which this ActivityRun is executing (format: int32)
  --start-date: string # Read Only. The UTC date and time when the activity started (format: date-time)
  status: record # A DTO for an IActivityRunStatus — shape: {CurrentStep?: int, Status?: "Ready"|"InProgress"|"Succeeded"|"Cancelled"|"Failed", StepProgress?: int, StepStatus?: string}
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($agent_id | is-empty) { error make --unspanned { msg: "path parameter 'agentID' must be non-empty" } }
  let full_url = (build-url $base ({agent_id: (encode-path-segment $agent_id)} | format pattern "/api/v2/agents/{agent_id}/ActivityRun") $auth.query)
  let req_body = {"ActivityRunID": $activity_run_id, "EndDate": $end_date, "JobActivityID": $job_activity_id, "JobRunID": $job_run_id, "StartDate": $start_date, "Status": $status} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Update an Agent
#
# PUT /api/v2/agents/{agentID}/Status
# operationId: Agents_PutAgentStatus
export def "agents-status update" [
  agent_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-status-update: string # ReadOnly. The UTC date and time of the last status update (format: date-time)
  --online: oneof<nothing, bool> # Indicates if the agent is online
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($agent_id | is-empty) { error make --unspanned { msg: "path parameter 'agentID' must be non-empty" } }
  let full_url = (build-url $base ({agent_id: (encode-path-segment $agent_id)} | format pattern "/api/v2/agents/{agent_id}/Status") $auth.query)
  let req_body = {"LastStatusUpdate": $last_status_update, "Online": $online} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get JobRuns
#
# GET /api/v2/jobRuns
# operationId: JobRuns_GetJobRuns
export def "job-runs list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --include-activity-run-details: oneof<nothing, bool> # Optional. Indicates whether to include ActivityRun details. Defaults to false.
]: nothing -> record<Entities: table<ActivityRuns: list, EndDate: string, JobID: int, JobRunID: int, Parameters: list, StartDate: string, Status: string>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "includeActivityRunDetails" $include_activity_run_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/jobRuns" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "includeActivityRunDetails": $include_activity_run_details} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a JobRun
#
# POST /api/v2/jobRuns
# operationId: JobRuns_PostJobRun
# --ActivityRuns item shape: {ActivityRunID?: int, EndDate?: string, JobActivityID?: int, JobRunID?: int, StartDate?: string, Status: record}
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Value?: string}
export def "job-runs create" [
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
  --end-date: string # The UTC date and time when the job completed (format: date-time)
  --job-id: int # The ID of the job that defines the run (format: int32)
  --job-run-id: int # The ID of this JobRun (format: int32)
  --start-date: string # The UTC date and time when the job started (format: date-time)
  --status: string@status-completer-2 # The status of this JobRun
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/jobRuns" $auth.query)
  let req_body = {"EndDate": $end_date, "JobID": $job_id, "JobRunID": $job_run_id, "StartDate": $start_date, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a JobRun
#
# DELETE /api/v2/jobRuns/{jobRunID}
# operationId: JobRuns_DeleteJobRun
export def "job-runs delete" [
  job_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_run_id | is-empty) { error make --unspanned { msg: "path parameter 'jobRunID' must be non-empty" } }
  let full_url = (build-url $base ({job_run_id: (encode-path-segment $job_run_id)} | format pattern "/api/v2/jobRuns/{job_run_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a JobRun by ID
#
# GET /api/v2/jobRuns/{jobRunID}
# operationId: JobRuns_GetJobRun
export def "job-runs get" [
  job_run_id: int
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
  --include-activity-run-details: oneof<nothing, bool> # Optional. Indicates whether to include ActivityRun details. Defaults to false.
]: nothing -> record<ActivityRuns: table<ActivityRunID: int, EndDate: string, JobActivityID: int, JobRunID: int, Parameters: list, StartDate: string, Status: record, Steps: list>, EndDate: string, JobID: int, JobRunID: int, Parameters: table<Direction: string, Name: string, Value: string>, StartDate: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_run_id | is-empty) { error make --unspanned { msg: "path parameter 'jobRunID' must be non-empty" } }
  let qp = [(serialize-qp "includeActivityRunDetails" $include_activity_run_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_run_id: (encode-path-segment $job_run_id)} | format pattern "/api/v2/jobRuns/{job_run_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeActivityRunDetails": $include_activity_run_details} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a JobRun
#
# PUT /api/v2/jobRuns/{jobRunID}
# operationId: JobRuns_PutJobRun
# --ActivityRuns item shape: {ActivityRunID?: int, EndDate?: string, JobActivityID?: int, JobRunID?: int, StartDate?: string, Status: record}
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Value?: string}
export def "job-runs update" [
  job_run_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # The UTC date and time when the job completed (format: date-time)
  --job-id: int # The ID of the job that defines the run (format: int32)
  --body-job-run-id: int # The ID of this JobRun (format: int32)
  --start-date: string # The UTC date and time when the job started (format: date-time)
  --status: string@status-completer-2 # The status of this JobRun
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_run_id | is-empty) { error make --unspanned { msg: "path parameter 'jobRunID' must be non-empty" } }
  let full_url = (build-url $base ({job_run_id: (encode-path-segment $job_run_id)} | format pattern "/api/v2/jobRuns/{job_run_id}") $auth.query)
  let req_body = {"EndDate": $end_date, "JobID": $job_id, "JobRunID": $body_job_run_id, "StartDate": $start_date, "Status": $status} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Jobs
#
# GET /api/v2/jobs
# operationId: Jobs_GetJobs
export def "jobs list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted job, or not
]: nothing -> record<Entities: table<Activities: list, Deleted: bool, JobID: int, Name: string, Parameters: list>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "isIncludeDeleted" $is_include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/jobs" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "isIncludeDeleted": $is_include_deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Job
#
# POST /api/v2/jobs
# operationId: Jobs_PostJob
# --Activities item shape: {ActivityID?: int, JobActivityID?: int, JobID?: int, RunOrder?: int}
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
export def "jobs create" [
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
  --deleted: oneof<nothing, bool> # Indicates if the job has been deleted.
  --job-id: int # The ID of the job (format: int32)
  --name: string # The name of the job
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/jobs" $auth.query)
  let req_body = {"Deleted": $deleted, "JobID": $job_id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Mark the delete flag for the Job
#
# DELETE /api/v2/jobs/{jobID}
# operationId: Jobs_DeleteJob
export def "jobs delete" [
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobID' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/api/v2/jobs/{job_id}") $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a Job by ID
#
# GET /api/v2/jobs/{jobID}
# operationId: Jobs_GetJob
export def "jobs get" [
  job_id: int
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
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted job, or not
]: nothing -> record<Activities: table<ActivityID: int, JobActivityID: int, JobID: int, ParameterMappings: list, RunOrder: int>, Deleted: bool, JobID: int, Name: string, Parameters: table<Direction: string, Name: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobID' must be non-empty" } }
  let qp = [(serialize-qp "isIncludeDeleted" $is_include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/api/v2/jobs/{job_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"isIncludeDeleted": $is_include_deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Job
#
# PUT /api/v2/jobs/{jobID}
# operationId: Jobs_PutJob
# --Activities item shape: {ActivityID?: int, JobActivityID?: int, JobID?: int, RunOrder?: int}
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
export def "jobs update" [
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleted: oneof<nothing, bool> # Indicates if the job has been deleted.
  --body-job-id: int # The ID of the job (format: int32)
  --name: string # The name of the job
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobID' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/api/v2/jobs/{job_id}") $auth.query)
  let req_body = {"Deleted": $deleted, "JobID": $body_job_id, "Name": $name} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Steps
#
# GET /api/v2/steps
# operationId: Steps_GetSteps
export def "steps list" [
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
  --limit: int # Optional. The page limit. If not specified, the default page limit is 10. (format: int32)
  --offset: int # Optional. The page offset. If not specified, the default page offset is 0. (format: int32)
  --include-deleted: oneof<nothing, bool> # Does it include deleted step, or not
]: nothing -> record<Entities: table<ConfigRequired: bool, Deleted: bool, Description: string, ImplementationID: string, Name: string, Parameters: list, StepID: int>, Metadata: record<Limit: int, Offset: int, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/steps" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "includeDeleted": $include_deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Step
#
# POST /api/v2/steps
# operationId: Steps_PostStep
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
export def "steps create" [
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
  --config-required: oneof<nothing, bool> # Indicates if the step requires configuration values to be provided by the build agent
  --deleted: oneof<nothing, bool> # Read Only. Indicates if the record is deleted.
  --description: string # A description of the step to be presented to a user
  implementation_id: string # The implementation ID used to lookup the step implementation when it is executed
  name: string # The name of the step
  --step-id: int # The ID of the step (format: int32)
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/steps" $auth.query)
  let req_body = {"ConfigRequired": $config_required, "Deleted": $deleted, "Description": $description, "ImplementationID": $implementation_id, "Name": $name, "StepID": $step_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get a Step by ID
#
# GET /api/v2/steps/{stepID}
# operationId: Steps_GetStep
export def "steps get" [
  step_id: int
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
  --is-include-deleted: oneof<nothing, bool> # Does it include deleted step, or not
]: nothing -> record<ConfigRequired: bool, Deleted: bool, Description: string, ImplementationID: string, Name: string, Parameters: table<Direction: string, Name: string, Type: string>, StepID: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($step_id | is-empty) { error make --unspanned { msg: "path parameter 'stepID' must be non-empty" } }
  let qp = [(serialize-qp "isIncludeDeleted" $is_include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({step_id: (encode-path-segment $step_id)} | format pattern "/api/v2/steps/{step_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"isIncludeDeleted": $is_include_deleted} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Step
#
# PUT /api/v2/steps/{stepID}
# operationId: Steps_PutStep
# --Parameters item shape: {Direction?: "Input"|"Output", Name?: string, Type?: "String"|"Boolean"|"Integer"|"Float"|"StringDictionary"}
export def "steps update" [
  step_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-required: oneof<nothing, bool> # Indicates if the step requires configuration values to be provided by the build agent
  --deleted: oneof<nothing, bool> # Read Only. Indicates if the record is deleted.
  --description: string # A description of the step to be presented to a user
  implementation_id: string # The implementation ID used to lookup the step implementation when it is executed
  name: string # The name of the step
  --body-step-id: int # The ID of the step (format: int32)
]: any -> record<DeveloperMessage: string, ErrorCode: int, MoreInfo: string, UserMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($step_id | is-empty) { error make --unspanned { msg: "path parameter 'stepID' must be non-empty" } }
  let full_url = (build-url $base ({step_id: (encode-path-segment $step_id)} | format pattern "/api/v2/steps/{step_id}") $auth.query)
  let req_body = {"ConfigRequired": $config_required, "Deleted": $deleted, "Description": $description, "ImplementationID": $implementation_id, "Name": $name, "StepID": $body_step_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}
