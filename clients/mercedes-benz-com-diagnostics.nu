# Auto-generated client for Remote Diagnostic Support v1.0
# Source: https://api.apis.guru/v2/specs/mercedes-benz.com/diagnostics/1.0/swagger.json
# Auth: --token flag or $env.REMOTE_DIAGNOSTIC_SUPPORT_TOKEN

const BASE_URL = "https://api.mercedes-benz.com/remotediagnostic_tryout/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o REMOTE_DIAGNOSTIC_SUPPORT_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.mercedes-benz.com/remotediagnostic_tryout/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json;charset=utf-8" "application/x.exve.org.dtcreadout.v1+json;charset=utf-8"] }
def accept-completer-1 [] { ["application/json;charset=utf-8" "application/x.exve.org.dtcSnapshotReadout.v1+json;charset=utf-8"] }
def accept-completer-2 [] { ["application/json;charset=utf-8" "application/x.exve.org.ecureadout.v1+json;charset=utf-8"] }
def accept-completer-3 [] { ["application/json;charset=utf-8" "application/x.exve.org.resourceReadout.v1+json;charset=utf-8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "vehicles-dtc-readouts get-data-list-by-ecu-using-create" } } | get name | first)
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

# View the List of DTCs for specific vehicleId.
#
# POST /vehicles/{vehicleId}/dtcReadouts
# operationId: getDtcDataListByEcuUsingPOST
export def "vehicles-dtc-readouts get-data-list-by-ecu-using-create" [
  vehicle_id: string
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
  --ecu-id: string # Return DTCs from this ECU id only. Default: Return DTCs from all ECUs.
  --dtc-status: string # Returns DTCs with this statuses only. Default: Return DTCs with all statuses.
]: nothing -> record<dtcReadout: record<asyncEstimatedComplete: string, asyncProgress: int, asyncStatus: string, asyncWait: int, exveErrorId: string, exveErrorMsg: string, exveErrorRef: string, exveNote: string, id: string, messageTimestamp: string, receivedTimestamp: string, vehicleId: string, dtcs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vehicle_id | is-empty) { error make --unspanned { msg: "path parameter 'vehicleId' must be non-empty" } }
  let qp = [(serialize-qp "ecuId" $ecu_id "scalar") (serialize-qp "dtcStatus" $dtc_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vehicle_id: (encode-path-segment $vehicle_id)} | format pattern "/vehicles/{vehicle_id}/dtcReadouts") $qp $auth.query)
  let accept_val = ($accept | default "application/x.exve.org.dtcreadout.v1+json;charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ecuId": $ecu_id, "dtcStatus": $dtc_status} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201 202]
}

# View the List of DTC Snapshot for specific vehicleId.
#
# POST /vehicles/{vehicleId}/ecuId/{ecuId}/dtcId/{dtcId}/dtcSnapshotReadouts
# operationId: getDtcSnapshotReadoutsUsingPOST
export def "vehicles-ecu-id-dtc-id-dtc-snapshot-readouts get-using-create" [
  vehicle_id: string
  ecu_id: string
  dtc_id: string
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
]: nothing -> record<dtcSnapshotReadout: record<asyncEstimatedComplete: string, asyncProgress: int, asyncStatus: string, asyncWait: int, exveErrorId: string, exveErrorMsg: string, exveErrorRef: string, exveNote: string, id: string, messageTimestamp: string, receivedTimestamp: string, vehicleId: string, dtcId: string, dtcSnapshotParameters: list<record>, ecuId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vehicle_id | is-empty) { error make --unspanned { msg: "path parameter 'vehicleId' must be non-empty" } }
  if ($ecu_id | is-empty) { error make --unspanned { msg: "path parameter 'ecuId' must be non-empty" } }
  if ($dtc_id | is-empty) { error make --unspanned { msg: "path parameter 'dtcId' must be non-empty" } }
  let full_url = (build-url $base ({vehicle_id: (encode-path-segment $vehicle_id), ecu_id: (encode-path-segment $ecu_id), dtc_id: (encode-path-segment $dtc_id)} | format pattern "/vehicles/{vehicle_id}/ecuId/{ecu_id}/dtcId/{dtc_id}/dtcSnapshotReadouts") $auth.query)
  let accept_val = ($accept | default "application/x.exve.org.dtcSnapshotReadout.v1+json;charset=utf-8")
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
  send-post $req null $insecure $raw $allow_errors $full [201 202 204]
}

# View the List of ECU for specific vehicleId.
#
# POST /vehicles/{vehicleId}/ecuReadouts
# operationId: getEcuDataListByVehicleIdUsingPOST
export def "vehicles-ecu-readouts get-data-list-by-using-create" [
  vehicle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --ecu-id: string # Return this ECU id only. Default: Return all ECUs.
]: nothing -> record<ecuReadout: record<asyncEstimatedComplete: string, asyncProgress: int, asyncStatus: string, asyncWait: int, exveErrorId: string, exveErrorMsg: string, exveErrorRef: string, exveNote: string, id: string, messageTimestamp: string, receivedTimestamp: string, vehicleId: string, ecus: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vehicle_id | is-empty) { error make --unspanned { msg: "path parameter 'vehicleId' must be non-empty" } }
  let qp = [(serialize-qp "ecuId" $ecu_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vehicle_id: (encode-path-segment $vehicle_id)} | format pattern "/vehicles/{vehicle_id}/ecuReadouts") $qp $auth.query)
  let accept_val = ($accept | default "application/x.exve.org.ecureadout.v1+json;charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ecuId": $ecu_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201 202]
}

# View the List of resources
#
# POST /vehicles/{vehicleId}/resourceReadouts
# operationId: getResourceReadoutsUsingPOST
export def "vehicles-resource-readouts get-using-create" [
  vehicle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
]: nothing -> record<resourceReadout: record<asyncEstimatedComplete: string, asyncProgress: int, asyncStatus: string, asyncWait: int, exveErrorId: string, exveErrorMsg: string, exveErrorRef: string, exveNote: string, id: string, messageTimestamp: string, receivedTimestamp: string, vehicleId: string, resources: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vehicle_id | is-empty) { error make --unspanned { msg: "path parameter 'vehicleId' must be non-empty" } }
  let full_url = (build-url $base ({vehicle_id: (encode-path-segment $vehicle_id)} | format pattern "/vehicles/{vehicle_id}/resourceReadouts") $auth.query)
  let accept_val = ($accept | default "application/x.exve.org.resourceReadout.v1+json;charset=utf-8")
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
  send-post $req null $insecure $raw $allow_errors $full [201 202]
}
