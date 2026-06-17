# Auto-generated client for Remote Diagnostic Support v1.0
# Source: https://api.apis.guru/v2/specs/mercedes-benz.com/diagnostics/1.0/swagger.json
# Auth: --token flag or $env.REMOTE_DIAGNOSTIC_SUPPORT_TOKEN

const BASE_URL = "https://api.mercedes-benz.com/remotediagnostic_tryout/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REMOTE_DIAGNOSTIC_SUPPORT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.mercedes-benz.com/remotediagnostic_tryout/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json;charset=utf-8" "application/x.exve.org.dtcreadout.v1+json;charset=utf-8"] }
def accept-completer-1 [] { ["application/json;charset=utf-8" "application/x.exve.org.dtcSnapshotReadout.v1+json;charset=utf-8"] }
def accept-completer-2 [] { ["application/json;charset=utf-8" "application/x.exve.org.ecureadout.v1+json;charset=utf-8"] }
def accept-completer-3 [] { ["application/json;charset=utf-8" "application/x.exve.org.resourceReadout.v1+json;charset=utf-8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "vehicles-dtc-readouts get-dtc-data-list" } } | get name | first)
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
export def "vehicles-dtc-readouts get-dtc-data-list" [
  vehicle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ecu-id: string # Return DTCs from this ECU id only. Default: Return DTCs from all ECUs.
  --dtc-status: string # Returns DTCs with this statuses only. Default: Return DTCs with all statuses.
]: nothing -> record<dtcReadout: record<asyncEstimatedComplete: string, asyncProgress: int, asyncStatus: string, asyncWait: int, exveErrorId: string, exveErrorMsg: string, exveErrorRef: string, exveNote: string, id: string, messageTimestamp: string, receivedTimestamp: string, vehicleId: string, dtcs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ecuId" $ecu_id "scalar") (serialize-qp "dtcStatus" $dtc_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vehicle_id: $vehicle_id} | format pattern "/vehicles/{vehicle_id}/dtcReadouts") $qp)
  let accept_val = ($accept | default "application/x.exve.org.dtcreadout.v1+json;charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View the List of DTC Snapshot for specific vehicleId.
#
# POST /vehicles/{vehicleId}/ecuId/{ecuId}/dtcId/{dtcId}/dtcSnapshotReadouts
# operationId: getDtcSnapshotReadoutsUsingPOST
export def "vehicles-ecu-id-dtc-id-dtc-snapshot-readouts get-dtc-snapshot-readouts-using-post" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<dtcSnapshotReadout: record<asyncEstimatedComplete: string, asyncProgress: int, asyncStatus: string, asyncWait: int, exveErrorId: string, exveErrorMsg: string, exveErrorRef: string, exveNote: string, id: string, messageTimestamp: string, receivedTimestamp: string, vehicleId: string, dtcId: string, dtcSnapshotParameters: list<record>, ecuId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({vehicle_id: $vehicle_id, ecu_id: $ecu_id, dtc_id: $dtc_id} | format pattern "/vehicles/{vehicle_id}/ecuId/{ecu_id}/dtcId/{dtc_id}/dtcSnapshotReadouts"))
  let accept_val = ($accept | default "application/x.exve.org.dtcSnapshotReadout.v1+json;charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View the List of ECU for specific vehicleId.
#
# POST /vehicles/{vehicleId}/ecuReadouts
# operationId: getEcuDataListByVehicleIdUsingPOST
export def "vehicles-ecu-readouts get-ecu-data-list" [
  vehicle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --ecu-id: string # Return this ECU id only. Default: Return all ECUs.
]: nothing -> record<ecuReadout: record<asyncEstimatedComplete: string, asyncProgress: int, asyncStatus: string, asyncWait: int, exveErrorId: string, exveErrorMsg: string, exveErrorRef: string, exveNote: string, id: string, messageTimestamp: string, receivedTimestamp: string, vehicleId: string, ecus: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ecuId" $ecu_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vehicle_id: $vehicle_id} | format pattern "/vehicles/{vehicle_id}/ecuReadouts") $qp)
  let accept_val = ($accept | default "application/x.exve.org.ecureadout.v1+json;charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View the List of resources
#
# POST /vehicles/{vehicleId}/resourceReadouts
# operationId: getResourceReadoutsUsingPOST
export def "vehicles-resource-readouts get-resource-readouts-using-post" [
  vehicle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-3 # Response content type
]: nothing -> record<resourceReadout: record<asyncEstimatedComplete: string, asyncProgress: int, asyncStatus: string, asyncWait: int, exveErrorId: string, exveErrorMsg: string, exveErrorRef: string, exveNote: string, id: string, messageTimestamp: string, receivedTimestamp: string, vehicleId: string, resources: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({vehicle_id: $vehicle_id} | format pattern "/vehicles/{vehicle_id}/resourceReadouts"))
  let accept_val = ($accept | default "application/x.exve.org.resourceReadout.v1+json;charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
