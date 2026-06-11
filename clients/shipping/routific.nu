# Auto-generated client for Routific Route Optimization API v1.11
# Source: https://raw.githubusercontent.com/api-evangelist/routific/main/openapi/routific-route-optimization-api-openapi.yml
# Auth: --token flag or $env.ROUTIFIC_ROUTE_OPTIMIZATION_API_TOKEN

const BASE_URL = "https://api.routific.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ROUTIFIC_ROUTE_OPTIMIZATION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.routific.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "vrp solveVrp" } } | get name | first)
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

# Solve Vehicle Routing Problem
#
# POST /v1/vrp
# operationId: solveVrp
# --options shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
export def "vrp solveVrp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  visits: record # Map of visit ID to visit definition.
  fleet: record # Map of vehicle ID to vehicle definition.
  --options: record # Tunable parameters that adjust how the optimization engine runs. — shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
]: any -> record<status: string, total_travel_time: int, total_idle_time: int, total_working_time: int, total_visit_lateness: int, num_late_visits: int, total_overtime: int, vehicle_overtime: record, num_unserved: int, unserved: any, solution: record, polylines: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vrp")
  let body = {visits: $visits, fleet: $fleet, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Solve Vehicle Routing Problem (Async)
#
# POST /v1/vrp-long
# operationId: solveVrpLong
# --options shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
export def "vrp-long solveVrpLong" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  visits: record # Map of visit ID to visit definition.
  fleet: record # Map of vehicle ID to vehicle definition.
  --options: record # Tunable parameters that adjust how the optimization engine runs. — shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
]: any -> record<job_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vrp-long")
  let body = {visits: $visits, fleet: $fleet, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Solve Pickup And Delivery Problem (Async)
#
# POST /v1/pdp-long
# operationId: solvePdpLong
# --options shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
export def "pdp-long solvePdpLong" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  visits: record
  fleet: record
  --options: record # Tunable parameters that adjust how the optimization engine runs. — shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
]: any -> record<job_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/pdp-long")
  let body = {visits: $visits, fleet: $fleet, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Optimization Job Status
#
# GET /jobs/{job_id}
# operationId: getJob
export def "jobs get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<job_id: string, status: string, created_at: string, finished_at: string, output: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobs/($job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Insert New Visits Into VRP Solution
#
# POST /v1/fix
# operationId: fixVrp
# --options shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
export def "fix fixVrp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  visits: record
  fleet: record
  --options: record # Tunable parameters that adjust how the optimization engine runs. — shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
  solution: record # Existing solution — map of vehicle ID to ordered list of visit IDs.
  unserved: list # New visit IDs to insert into the existing solution.
]: any -> record<status: string, total_travel_time: int, total_idle_time: int, total_working_time: int, total_visit_lateness: int, num_late_visits: int, total_overtime: int, vehicle_overtime: record, num_unserved: int, unserved: any, solution: record, polylines: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fix")
  let body = {visits: $visits, fleet: $fleet, options: $options, solution: $solution, unserved: $unserved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Insert New Visits Into PDP Solution
#
# POST /v1/fix-pdp
# operationId: fixPdp
# --options shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
export def "fix-pdp fixPdp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  visits: record
  fleet: record
  --options: record # Tunable parameters that adjust how the optimization engine runs. — shape: {traffic?: "faster"|"fast"|"normal"|"slow"|"very slow", min_visits_per_vehicle?: int, balance?: bool, visit_balance_coefficient?: float, min_vehicles?: bool, shortest_distance?: bool, squash_durations?: int, max_vehicle_overtime?: int, max_visit_lateness?: int, polylines?: bool, avoid_tolls?: bool, geocoder?: "google"|"here"}
  solution: record
  unserved: list
]: any -> record<status: string, total_travel_time: int, total_idle_time: int, total_working_time: int, total_visit_lateness: int, num_late_visits: int, total_overtime: int, vehicle_overtime: record, num_unserved: int, unserved: any, solution: record, polylines: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fix-pdp")
  let body = {visits: $visits, fleet: $fleet, options: $options, solution: $solution, unserved: $unserved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
