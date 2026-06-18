# Auto-generated client for  vv4 (Hunt Valley)
# Source: https://api.apis.guru/v2/specs/drchrono.com/v4 (Hunt Valley)/openapi.json
# Auth: --token flag or $env._TOKEN

const BASE_URL = "https://app.drchrono.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o _TOKEN | default "" }
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

def base-url-completer [] { ["https://app.drchrono.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "allergies list" } } | get name | first)
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

# Retrieve or search patient allergies
#
# GET /api/allergies
# operationId: allergies_list
export def "allergies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> record<data: table<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/allergies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient allergy
#
# POST /api/allergies
# operationId: allergies_create
export def "allergies create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/allergies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient allergy
#
# GET /api/allergies/{id}
# operationId: allergies_read
export def "allergies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<description: string, doctor: int, id: int, notes: string, patient: int, reaction: string, rxnorm: string, snomed_reaction: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/allergies/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient allergy
#
# PATCH /api/allergies/{id}
# operationId: allergies_partial_update
export def "allergies update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/allergies/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient allergy
#
# PUT /api/allergies/{id}
# operationId: allergies_update
export def "allergies update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/allergies/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient amendments. You can only interact with amendments created by your API application
#
# GET /api/amendments
# operationId: amendments_list
export def "amendments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> record<data: table<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/amendments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient amendments to a patient's clinical records
#
# POST /api/amendments
# operationId: amendments_create
export def "amendments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> record<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointment" $appointment "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/amendments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing patient amendment, you can only interact with amendments created by your API application
#
# DELETE /api/amendments/{id}
# operationId: amendments_delete
export def "amendments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointment" $appointment "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/amendments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient amendment, you can only interact with amendments created by your API application
#
# GET /api/amendments/{id}
# operationId: amendments_read
export def "amendments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> record<amendment_file: string, amendment_name: string, appointment: int, comments: string, doctor: int, id: int, patient: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointment" $appointment "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/amendments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient amendment, you can only interact with amendments created by your API application
#
# PATCH /api/amendments/{id}
# operationId: amendments_partial_update
export def "amendments update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointment" $appointment "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/amendments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient amendment, you can only interact with amendments created by your API application
#
# PUT /api/amendments/{id}
# operationId: amendments_update
export def "amendments update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointment" $appointment "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/amendments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search appointment profiles for a doctor's calendar
#
# GET /api/appointment_profiles
# operationId: appointment_profiles_list
export def "appointment-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/appointment_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create appointment profiles for a doctor's calendar
#
# POST /api/appointment_profiles
# operationId: appointment_profiles_create
export def "appointment-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/appointment_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing appointment profile
#
# DELETE /api/appointment_profiles/{id}
# operationId: appointment_profiles_delete
export def "appointment-profiles delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointment_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing appointment profile
#
# GET /api/appointment_profiles/{id}
# operationId: appointment_profiles_read
export def "appointment-profiles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, color: string, doctor: int, duration: int, id: int, name: string, online_scheduling: bool, reason: string, sort_order: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointment_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing appointment profile
#
# PATCH /api/appointment_profiles/{id}
# operationId: appointment_profiles_partial_update
export def "appointment-profiles update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointment_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing appointment profile
#
# PUT /api/appointment_profiles/{id}
# operationId: appointment_profiles_update
export def "appointment-profiles update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointment_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search appointment templates for a doctor's calendar
#
# GET /api/appointment_templates
# operationId: appointment_templates_list
export def "appointment-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --profile: int
  --office: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: list, profile: int, scheduled_time: string, week_days: list>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/appointment_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create appointment templates for a doctor's calendar
#
# POST /api/appointment_templates
# operationId: appointment_templates_create
export def "appointment-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --profile: int
  --office: int
  --doctor: int
]: nothing -> record<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: table<end: string, start: string>, profile: int, scheduled_time: string, week_days: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile" $profile "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/appointment_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing appointment template
#
# DELETE /api/appointment_templates/{id}
# operationId: appointment_templates_delete
export def "appointment-templates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --profile: int
  --office: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile" $profile "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointment_templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing appointment template
#
# GET /api/appointment_templates/{id}
# operationId: appointment_templates_read
export def "appointment-templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --profile: int
  --office: int
  --doctor: int
]: nothing -> record<archived: bool, date_end: string, date_start: string, duration: int, exam_room: int, id: int, office: int, open_slots: table<end: string, start: string>, profile: int, scheduled_time: string, week_days: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile" $profile "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointment_templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing appointment template
#
# PATCH /api/appointment_templates/{id}
# operationId: appointment_templates_partial_update
export def "appointment-templates update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --profile: int
  --office: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile" $profile "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointment_templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing appointment template
#
# PUT /api/appointment_templates/{id}
# operationId: appointment_templates_update
export def "appointment-templates update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --profile: int
  --office: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "profile" $profile "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointment_templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search appointment or breaks. Note: Either `since`, `date` or `date_range` parameter must be specified.
#
# GET /api/appointments
# operationId: appointments_list
export def "appointments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> record<data: table<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: list, billing_provider: string, billing_status: string, clinical_note: record, cloned_from: int, color: string, created_at: string, custom_fields: list, custom_vitals: list, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list, icd9_codes: list, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: list, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: list, supervising_provider: string, updated_at: string, vitals: record>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/appointments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new appointment or break on doctor's calendar
#
# POST /api/appointments
# operationId: appointments_create
export def "appointments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> record<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, billing_provider: string, billing_status: string, clinical_note: record<locked: bool, pdf: string, updated_at: string>, cloned_from: int, color: string, created_at: string, custom_fields: table<created_at: string, field_type: int, field_value: string, updated_at: string>, custom_vitals: table<value: string, vital_type: int>, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list<string>, icd9_codes: list<string>, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: table<id: int, scheduled_time: string, type: string>, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: table<appointment: string, datetime: string, from_status: string, to_status: string>, supervising_provider: string, updated_at: string, vitals: record<blood_pressure_1: int, blood_pressure_2: int, bmi: string, head_circumference: float, head_circumference_units: string, height: float, height_units: string, oxygen_saturation: float, pain: string, pulse: int, respiratory_rate: int, smoking_status: string, temperature: float, temperature_units: string, weight: float, weight_units: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/appointments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing appointment or break
#
# DELETE /api/appointments/{id}
# operationId: appointments_delete
export def "appointments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing appointment or break
#
# GET /api/appointments/{id}
# operationId: appointments_read
export def "appointments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> record<allow_overlapping: bool, appt_is_break: bool, base_recurring_appointment: string, billing_notes: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, billing_provider: string, billing_status: string, clinical_note: record<locked: bool, pdf: string, updated_at: string>, cloned_from: int, color: string, created_at: string, custom_fields: table<created_at: string, field_type: int, field_value: string, updated_at: string>, custom_vitals: table<value: string, vital_type: int>, deleted_flag: bool, doctor: int, duration: int, exam_room: int, extended_updated_at: string, first_billed_date: string, icd10_codes: list<string>, icd9_codes: list<string>, id: string, ins1_status: string, ins2_status: string, is_virtual_base: bool, is_walk_in: bool, last_billed_date: string, notes: string, office: int, patient: int, primary_insurance_id_number: string, primary_insurer_name: string, primary_insurer_payer_id: string, profile: int, reason: string, recurring_appointment: bool, reminder_profile: string, reminders: table<id: int, scheduled_time: string, type: string>, scheduled_time: string, secondary_insurance_id_number: string, secondary_insurer_name: string, secondary_insurer_payer_id: string, status: string, status_transitions: table<appointment: string, datetime: string, from_status: string, to_status: string>, supervising_provider: string, updated_at: string, vitals: record<blood_pressure_1: int, blood_pressure_2: int, bmi: string, head_circumference: float, head_circumference_units: string, height: float, height_units: string, oxygen_saturation: float, pain: string, pulse: int, respiratory_rate: int, smoking_status: string, temperature: float, temperature_units: string, weight: float, weight_units: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing appointment or break
#
# PATCH /api/appointments/{id}
# operationId: appointments_partial_update
export def "appointments update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing appointment or break
#
# PUT /api/appointments/{id}
# operationId: appointments_update
export def "appointments update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/appointments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search billing profiles
#
# GET /api/billing_profiles
# operationId: billing_profiles_list
export def "billing-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, cpt_codes: list, created_at: string, custom_procedure_codes: list, doctor: string, hcpcs_codes: list, icd10_codes: list, icd9_codes: list, id: int, name: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/billing_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing billing profiles
#
# GET /api/billing_profiles/{id}
# operationId: billing_profiles_read
export def "billing-profiles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, cpt_codes: table<code: string, diagnosis_pointers_icd10: list, diagnosis_pointers_icd9: list, modifiers: list, ndc_code: list, price: string, quantity: string>, created_at: string, custom_procedure_codes: table<code: string, price: string, quantity: string>, doctor: string, hcpcs_codes: table<code: string, diagnosis_pointers_icd10: list, diagnosis_pointers_icd9: list, modifiers: list, ndc_code: list, price: string, quantity: string>, icd10_codes: list<string>, icd9_codes: list<string>, id: int, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/billing_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search care plans
#
# GET /api/care_plans
# operationId: care_plans_list
export def "care-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --plan-type: int
  --doctor: int
]: nothing -> record<data: table<appointment: string, code: string, code_system: string, created_at: string, description: string, id: int, instructions: string, patient: string, plan_type: string, scheduled_date: string, title: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "plan_type" $plan_type "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/care_plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing care plan
#
# GET /api/care_plans/{id}
# operationId: care_plans_read
export def "care-plans get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --plan-type: int
  --doctor: int
]: nothing -> record<appointment: string, code: string, code_system: string, created_at: string, description: string, id: int, instructions: string, patient: string, plan_type: string, scheduled_date: string, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "plan_type" $plan_type "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/care_plans/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/care_team_members
#
# operationId: care_team_members_list
export def "care-team-members list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --appointment: int
  --doctor: int
]: nothing -> record<data: table<appointment: string, created_at: string, id: int, patient: string, user: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/care_team_members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/care_team_members/{id}
#
# operationId: care_team_members_read
export def "care-team-members get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --appointment: int
  --doctor: int
]: nothing -> record<appointment: string, created_at: string, id: int, patient: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/care_team_members/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search billing notes
#
# GET /api/claim_billing_notes
# operationId: claim_billing_notes_list
export def "claim-billing-notes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --appointment: int
  --doctor: int
]: nothing -> record<data: table<appointment: int, created_at: string, created_by: string, id: int, text: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/claim_billing_notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new billing note
#
# POST /api/claim_billing_notes
# operationId: claim_billing_notes_create
export def "claim-billing-notes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --doctor: int
]: nothing -> record<appointment: int, created_at: string, created_by: string, id: int, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointment" $appointment "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/claim_billing_notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing billing note
#
# GET /api/claim_billing_notes/{id}
# operationId: claim_billing_notes_read
export def "claim-billing-notes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --doctor: int
]: nothing -> record<appointment: int, created_at: string, created_by: string, id: int, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointment" $appointment "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/claim_billing_notes/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search clinical note field types
#
# GET /api/clinical_note_field_types
# operationId: clinical_note_field_types_list
export def "clinical-note-field-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> record<data: table<allowed_values: list, archived: bool, clinical_note_template: string, comment: string, data_type: string, id: int, name: string, required: bool>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "clinical_note_template" $clinical_note_template "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clinical_note_field_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing clinial note field type
#
# GET /api/clinical_note_field_types/{id}
# operationId: clinical_note_field_types_read
export def "clinical-note-field-types get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clinical-note-template: int
  --doctor: int
]: nothing -> record<allowed_values: list<string>, archived: bool, clinical_note_template: string, comment: string, data_type: string, id: int, name: string, required: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clinical_note_template" $clinical_note_template "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/clinical_note_field_types/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search clinical note field values
#
# GET /api/clinical_note_field_values
# operationId: clinical_note_field_values_list
export def "clinical-note-field-values list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> record<data: table<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "clinical_note_field" $clinical_note_field "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "clinical_note_template" $clinical_note_template "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clinical_note_field_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create clinical note field value
#
# POST /api/clinical_note_field_values
# operationId: clinical_note_field_values_create
export def "clinical-note-field-values create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> record<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clinical_note_field" $clinical_note_field "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "clinical_note_template" $clinical_note_template "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clinical_note_field_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing clinical note field value
#
# GET /api/clinical_note_field_values/{id}
# operationId: clinical_note_field_values_read
export def "clinical-note-field-values get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> record<appointment: int, clinical_note_field: int, created_at: string, id: int, updated_at: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clinical_note_field" $clinical_note_field "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "clinical_note_template" $clinical_note_template "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/clinical_note_field_values/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing clinical note field value
#
# PATCH /api/clinical_note_field_values/{id}
# operationId: clinical_note_field_values_partial_update
export def "clinical-note-field-values update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clinical_note_field" $clinical_note_field "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "clinical_note_template" $clinical_note_template "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/clinical_note_field_values/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing clinical note field value
#
# PUT /api/clinical_note_field_values/{id}
# operationId: clinical_note_field_values_update
export def "clinical-note-field-values update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clinical-note-field: int
  --since: string
  --appointment: int
  --clinical-note-template: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clinical_note_field" $clinical_note_field "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "clinical_note_template" $clinical_note_template "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/clinical_note_field_values/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search clinical note templates
#
# GET /api/clinical_note_templates
# operationId: clinical_note_templates_list
export def "clinical-note-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, clinical_note_fields: list, doctor: string, id: int, is_onpatient: bool, is_persistent: bool, name: string, order: record, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clinical_note_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing clinical note tempalte
#
# GET /api/clinical_note_templates/{id}
# operationId: clinical_note_templates_read
export def "clinical-note-templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, clinical_note_fields: table<allowed_values: list, archived: bool, clinical_note_template: int, data_type: string, name: string, required: bool>, doctor: string, id: int, is_onpatient: bool, is_persistent: bool, name: string, order: record<on_complete_note: int, on_ipad: int>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/clinical_note_templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/clinical_notes
#
# operationId: clinical_notes_list
export def "clinical-notes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> record<data: table<appointment: string, archived: bool, clinical_note_sections: list, patient: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/clinical_notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/clinical_notes/{id}
#
# operationId: clinical_notes_read
export def "clinical-notes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --date-range: string
  --date: string
]: nothing -> record<appointment: string, archived: bool, clinical_note_sections: table<clinical_note_template: int, name: string, values: list>, patient: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/clinical_notes/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search communicatioin (phone call) logs
#
# GET /api/comm_logs
# operationId: comm_logs_list
export def "comm-logs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<data: table<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/comm_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create communication (phone call) logs
#
# POST /api/comm_logs
# operationId: comm_logs_create
export def "comm-logs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/comm_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing communication (phone call) logs
#
# GET /api/comm_logs/{id}
# operationId: comm_logs_read
export def "comm-logs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<appointment: int, archived: bool, author: string, cash_charged: float, created_at: string, doctor: int, duration: int, id: int, message: string, patient: int, scheduled_time: string, title: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/comm_logs/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing communication (phone call) logs
#
# PATCH /api/comm_logs/{id}
# operationId: comm_logs_partial_update
export def "comm-logs update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/comm_logs/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing communication (phone call) logs
#
# PUT /api/comm_logs/{id}
# operationId: comm_logs_update
export def "comm-logs update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/comm_logs/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient consent forms
#
# GET /api/consent_forms
# operationId: consent_forms_list
export def "consent-forms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/consent_forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a patient consent form
#
# POST /api/consent_forms
# operationId: consent_forms_create
export def "consent-forms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/consent_forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient consent form
#
# GET /api/consent_forms/{id}
# operationId: consent_forms_read
export def "consent-forms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, assign_by_default: bool, created_at: string, doctor: int, id: int, is_mandatory: bool, order: int, title: string, updated_at: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/consent_forms/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient consent form
#
# PATCH /api/consent_forms/{id}
# operationId: consent_forms_partial_update
export def "consent-forms update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/consent_forms/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient consent form
#
# PUT /api/consent_forms/{id}
# operationId: consent_forms_update
export def "consent-forms update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/consent_forms/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign (apply) a consent form to appointment
#
# POST /api/consent_forms/{id}/apply_to_appointment
# operationId: consent_forms_apply_to_appointment
export def "consent-forms-apply-to-appointment create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/consent_forms/{id}/apply_to_appointment") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unassign (unapply) a consent form from appointment
#
# POST /api/consent_forms/{id}/unapply_from_appointment
# operationId: consent_forms_unapply_from_appointment
export def "consent-forms-unapply-from-appointment create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/consent_forms/{id}/unapply_from_appointment") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search custom appointment fields
#
# GET /api/custom_appointment_fields
# operationId: custom_appointment_fields_list
export def "custom-appointment-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/custom_appointment_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create custom appointment fields
#
# POST /api/custom_appointment_fields
# operationId: custom_appointment_fields_create
export def "custom-appointment-fields create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/custom_appointment_fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing custom appointment field
#
# GET /api/custom_appointment_fields/{id}
# operationId: custom_appointment_fields_read
export def "custom-appointment-fields get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, created_at: string, doctor: string, field_desc: string, field_name: string, id: int, order: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/custom_appointment_fields/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing custom appointment field
#
# PATCH /api/custom_appointment_fields/{id}
# operationId: custom_appointment_fields_partial_update
export def "custom-appointment-fields update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/custom_appointment_fields/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing custom appointment field
#
# PUT /api/custom_appointment_fields/{id}
# operationId: custom_appointment_fields_update
export def "custom-appointment-fields update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/custom_appointment_fields/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search custom demographics fields
#
# GET /api/custom_demographics
# operationId: custom_demographics_list
export def "custom-demographics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/custom_demographics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create custom demographics fields
#
# POST /api/custom_demographics
# operationId: custom_demographics_create
export def "custom-demographics create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/custom_demographics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing custom demographics field
#
# GET /api/custom_demographics/{id}
# operationId: custom_demographics_read
export def "custom-demographics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<allowed_values: string, archived: bool, description: string, doctor: int, id: int, name: string, template_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/custom_demographics/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing custom demographics field
#
# PATCH /api/custom_demographics/{id}
# operationId: custom_demographics_partial_update
export def "custom-demographics update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/custom_demographics/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing custom demographics field
#
# PUT /api/custom_demographics/{id}
# operationId: custom_demographics_update
export def "custom-demographics update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/custom_demographics/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search custom insurance plan names
#
# GET /api/custom_insurance_plan_names
# operationId: custom_insurance_plan_names_list
export def "custom-insurance-plan-names list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --user: int
  --name: string
  --doctor: int
]: nothing -> record<data: table<archived: bool, created_at: string, doctor: string, id: int, insurance_plan_name: string, updated_at: string, user: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/custom_insurance_plan_names" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing custom insurance plan name
#
# GET /api/custom_insurance_plan_names/{id}
# operationId: custom_insurance_plan_names_read
export def "custom-insurance-plan-names get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --user: int
  --name: string
  --doctor: int
]: nothing -> record<archived: bool, created_at: string, doctor: string, id: int, insurance_plan_name: string, updated_at: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/custom_insurance_plan_names/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search custom vital types
#
# GET /api/custom_vitals
# operationId: custom_vitals_list
export def "custom-vitals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<allowed_values: list, archived: bool, data_type: string, description: string, doctor: string, fraction_delimiter: string, id: int, is_fraction_field: bool, name: string, unit: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/custom_vitals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing custom vital type
#
# GET /api/custom_vitals/{id}
# operationId: custom_vitals_read
export def "custom-vitals get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<allowed_values: list<string>, archived: bool, data_type: string, description: string, doctor: string, fraction_delimiter: string, id: int, is_fraction_field: bool, name: string, unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/custom_vitals/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search doctors within practice group
#
# GET /api/doctors
# operationId: doctors_list
export def "doctors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<cell_phone: string, country: string, email: string, first_name: string, group_npi_number: string, home_phone: string, id: int, is_account_suspended: bool, job_title: string, last_name: string, npi_number: string, office_phone: string, practice_group: string, practice_group_name: string, profile_picture: string, specialty: string, suffix: string, timezone: string, website: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/doctors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing dcotor
#
# GET /api/doctors/{id}
# operationId: doctors_read
export def "doctors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<cell_phone: string, country: string, email: string, first_name: string, group_npi_number: string, home_phone: string, id: int, is_account_suspended: bool, job_title: string, last_name: string, npi_number: string, office_phone: string, practice_group: string, practice_group_name: string, profile_picture: string, specialty: string, suffix: string, timezone: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/doctors/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search documents
#
# GET /api/documents
# operationId: documents_list
export def "documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create documents
#
# POST /api/documents
# operationId: documents_create
export def "documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing appointment template
#
# DELETE /api/documents/{id}
# operationId: documents_delete
export def "documents delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/documents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing appointment template
#
# GET /api/documents/{id}
# operationId: documents_read
export def "documents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<archived: bool, date: string, description: string, doctor: int, document: string, id: int, metatags: string, patient: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/documents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing appointment template
#
# PATCH /api/documents/{id}
# operationId: documents_partial_update
export def "documents update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/documents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing appointment template
#
# PUT /api/documents/{id}
# operationId: documents_update
export def "documents update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/documents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search past eligibility checks for patient
#
# GET /api/eligibility_checks
# operationId: eligibility_checks_list
export def "eligibility-checks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --appointment: int
  --appointment-date: string
  --doctor: int
  --query-date-range: string
  --appointment-date-range: string
  --query-date: string
  --patient: int
]: nothing -> record<data: table<appointment: string, cob_level: string, coverage_details: string, coverage_subscriber: string, eligibility: string, patient: string, payer_name: string, query_date: string, request_service_type: string, service_type_description: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "appointment_date" $appointment_date "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "query_date_range" $query_date_range "scalar") (serialize-qp "appointment_date_range" $appointment_date_range "scalar") (serialize-qp "query_date" $query_date "scalar") (serialize-qp "patient" $patient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/eligibility_checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing past eligibility check
#
# GET /api/eligibility_checks/{id}
# operationId: eligibility_checks_read
export def "eligibility-checks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appointment: int
  --appointment-date: string
  --doctor: int
  --query-date-range: string
  --appointment-date-range: string
  --query-date: string
  --patient: int
]: nothing -> record<appointment: string, cob_level: string, coverage_details: string, coverage_subscriber: string, eligibility: string, patient: string, payer_name: string, query_date: string, request_service_type: string, service_type_description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointment" $appointment "scalar") (serialize-qp "appointment_date" $appointment_date "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "query_date_range" $query_date_range "scalar") (serialize-qp "appointment_date_range" $appointment_date_range "scalar") (serialize-qp "query_date" $query_date "scalar") (serialize-qp "patient" $patient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/eligibility_checks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search EOB objects
#
# GET /api/eobs
# operationId: eobs_list
export def "eobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/eobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create EOB object
#
# POST /api/eobs
# operationId: eobs_create
export def "eobs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/eobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing EOB object
#
# GET /api/eobs/{id}
# operationId: eobs_read
export def "eobs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<check_date: string, deposit_date: string, doctor: int, id: int, insurance_payer_id: string, insurance_payer_name: string, insurance_payer_trace_number: string, payment_method: string, posted_date: string, scanned_eob: string, total_paid: float, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/eobs/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/fee_schedules
#
# operationId: fee_schedules_list
export def "fee-schedules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --code: string
  --code-type: string
  --since: string
  --payer-id: string
  --doctor: int
]: nothing -> record<data: table<allowed_amount: float, base_price: float, billing_description: string, cash_price: float, code: string, code_type: string, cpt_hcpcs_modifier1: string, cpt_hcpcs_modifier2: string, cpt_hcpcs_modifier3: string, cpt_hcpcs_modifier4: string, created_at: string, description: string, doctor: int, id: int, insured_out_of_network_price: float, insured_price: float, ndc_code: string, ndc_quantity: float, ndc_units: string, office: int, payer_id: string, picklist_category: string, plan_name: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "code_type" $code_type "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "payer_id" $payer_id "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/fee_schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/fee_schedules/{id}
#
# operationId: fee_schedules_read
export def "fee-schedules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --code-type: string
  --since: string
  --payer-id: string
  --doctor: int
]: nothing -> record<allowed_amount: float, base_price: float, billing_description: string, cash_price: float, code: string, code_type: string, cpt_hcpcs_modifier1: string, cpt_hcpcs_modifier2: string, cpt_hcpcs_modifier3: string, cpt_hcpcs_modifier4: string, created_at: string, description: string, doctor: int, id: int, insured_out_of_network_price: float, insured_price: float, ndc_code: string, ndc_quantity: float, ndc_units: string, office: int, payer_id: string, picklist_category: string, plan_name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "code_type" $code_type "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "payer_id" $payer_id "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/fee_schedules/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search implantable devices
#
# GET /api/implantable_devices
# operationId: implantable_devices_list
export def "implantable-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --mu-date: string
  --patient: int
  --mu-date-range: string
  --doctor: int
]: nothing -> record<data: table<archived: bool, brand_name: string, company_name: string, created_at: string, expiration_date: string, gmdn_pt_name: string, id: int, manufacturing_date: string, patient: string, procedure: string, serial_number: string, status: string, udi: string, updated_at: string, version_or_model: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "mu_date" $mu_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "mu_date_range" $mu_date_range "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/implantable_devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing implantable device
#
# GET /api/implantable_devices/{id}
# operationId: implantable_devices_read
export def "implantable-devices get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mu-date: string
  --patient: int
  --mu-date-range: string
  --doctor: int
]: nothing -> record<archived: bool, brand_name: string, company_name: string, created_at: string, expiration_date: string, gmdn_pt_name: string, id: int, manufacturing_date: string, patient: string, procedure: string, serial_number: string, status: string, udi: string, updated_at: string, version_or_model: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mu_date" $mu_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "mu_date_range" $mu_date_range "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/implantable_devices/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/insurances
#
# operationId: insurances_list
export def "insurances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --payer-type: string # One of `"emdeon"`, `"gateway"`, `"ihcfa"`
  --term: string # Search term, which can be either a partial name, partial ID or the state.
]: nothing -> record<data: table<payer_id: string, payer_name: string, state: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "payer_type" $payer_type "scalar") (serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/insurances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/insurances/{id}
#
# operationId: insurances_read
export def "insurances get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payer-type: string # One of `"emdeon"`, `"gateway"`, `"ihcfa"`
  --term: string # Search term, which can be either a partial name, partial ID or the state.
]: nothing -> record<payer_id: string, payer_name: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payer_type" $payer_type "scalar") (serialize-qp "term" $term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/insurances/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search inventory categories
#
# GET /api/inventory_categories
# operationId: inventory_categories_list
export def "inventory-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --doctor: int
]: nothing -> record<data: table<archived: bool, category_type: string, created_at: string, doctor: string, id: int, name: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/inventory_categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing inventory category
#
# GET /api/inventory_categories/{id}
# operationId: inventory_categories_read
export def "inventory-categories get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> record<archived: bool, category_type: string, created_at: string, doctor: string, id: int, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/inventory_categories/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search vaccine inventories
#
# GET /api/inventory_vaccines
# operationId: inventory_vaccines_list
export def "inventory-vaccines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --status: string
  --cvx-code: string
  --since: string
  --doctor: int
]: nothing -> record<data: table<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "cvx_code" $cvx_code "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/inventory_vaccines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create vaccine inventory
#
# POST /api/inventory_vaccines
# operationId: inventory_vaccines_create
export def "inventory-vaccines create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --cvx-code: string
  --since: string
  --doctor: int
]: nothing -> record<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "cvx_code" $cvx_code "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/inventory_vaccines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing vaccine inventory
#
# GET /api/inventory_vaccines/{id}
# operationId: inventory_vaccines_read
export def "inventory-vaccines get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --cvx-code: string
  --since: string
  --doctor: int
]: nothing -> record<category: int, cost: float, created_at: string, current_quantity: int, cvx_code: string, doctor: int, expiry: string, id: int, lot_number: string, manufacturer: string, manufacturer_code: string, name: string, note: string, original_quantity: int, price: float, price_with_tax: float, sales_tax_applicable: bool, status: string, updated_at: string, vaccination_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "cvx_code" $cvx_code "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/inventory_vaccines/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search lab order documents
#
# GET /api/lab_documents
# operationId: lab_documents_list
export def "lab-documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --doctor: int
]: nothing -> record<data: table<document: string, id: int, lab_order: int, timestamp: string, type: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create lab order documents. An example lab workflow is as following: - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/lab_documents
# operationId: lab_documents_create
export def "lab-documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> record<document: string, id: int, lab_order: int, timestamp: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing lab order document
#
# DELETE /api/lab_documents/{id}
# operationId: lab_documents_delete
export def "lab-documents delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_documents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing lab order document
#
# GET /api/lab_documents/{id}
# operationId: lab_documents_read
export def "lab-documents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> record<document: string, id: int, lab_order: int, timestamp: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_documents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing lab order document
#
# PATCH /api/lab_documents/{id}
# operationId: lab_documents_partial_update
export def "lab-documents update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_documents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing lab order document
#
# PUT /api/lab_documents/{id}
# operationId: lab_documents_update
export def "lab-documents update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_documents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search lab orders
#
# GET /api/lab_orders
# operationId: lab_orders_list
export def "lab-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --doctor: int
]: nothing -> record<data: table<accession_number: string, doctor: int, documents: list, icd10_codes: list, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create lab orders. An example lab workflow is as following: - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/lab_orders
# operationId: lab_orders_create
export def "lab-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing lab order
#
# DELETE /api/lab_orders/{id}
# operationId: lab_orders_delete
export def "lab-orders delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_orders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing lab order
#
# GET /api/lab_orders/{id}
# operationId: lab_orders_read
export def "lab-orders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_orders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing lab order
#
# PATCH /api/lab_orders/{id}
# operationId: lab_orders_partial_update
export def "lab-orders update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_orders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing lab order
#
# PUT /api/lab_orders/{id}
# operationId: lab_orders_update
export def "lab-orders update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_orders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/lab_orders_summary
#
# operationId: lab_orders_summary_list
export def "lab-orders-summary list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<data: table<accession_number: string, doctor: int, documents: list, icd10_codes: list, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_orders_summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/lab_orders_summary/{id}
#
# operationId: lab_orders_summary_read
export def "lab-orders-summary get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<accession_number: string, doctor: int, documents: list<string>, icd10_codes: table<code: string, description: string>, id: int, notes: string, patient: int, priority: string, requisition_id: string, status: string, sublab: int, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_orders_summary/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search lab results
#
# GET /api/lab_results
# operationId: lab_results_list
export def "lab-results list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --order: int
  --doctor: int
]: nothing -> record<data: table<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create lab results. An example lab workflow is as following: - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/lab_results
# operationId: lab_results_create
export def "lab-results create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> record<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing lab result
#
# DELETE /api/lab_results/{id}
# operationId: lab_results_delete
export def "lab-results delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_results/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing lab result
#
# GET /api/lab_results/{id}
# operationId: lab_results_read
export def "lab-results get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> record<abnormal_status: string, comments: string, document: int, group_code: string, id: int, is_abnormal: string, lab_order: string, lab_test: int, normal_range: string, observation_code: string, observation_description: string, specimen_received: string, status: string, test_performed: string, unit: string, value: string, value_is_numeric: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_results/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing lab result
#
# PATCH /api/lab_results/{id}
# operationId: lab_results_partial_update
export def "lab-results update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_results/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing lab result
#
# PUT /api/lab_results/{id}
# operationId: lab_results_update
export def "lab-results update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_results/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search lab tests
#
# GET /api/lab_tests
# operationId: lab_tests_list
export def "lab-tests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --order: int
  --doctor: int
]: nothing -> record<data: table<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_tests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create lab tests. An example lab workflow is as following: - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/lab_tests
# operationId: lab_tests_create
export def "lab-tests create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> record<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lab_tests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing lab test
#
# DELETE /api/lab_tests/{id}
# operationId: lab_tests_delete
export def "lab-tests delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_tests/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing lab test
#
# GET /api/lab_tests/{id}
# operationId: lab_tests_read
export def "lab-tests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> record<code: string, collection_date: string, description: string, id: int, internal_notes: string, lab_order: int, name: string, report_notes: string, specimen_condition: string, specimen_source: string, specimen_total_volume: float, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_tests/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing lab test
#
# PATCH /api/lab_tests/{id}
# operationId: lab_tests_partial_update
export def "lab-tests update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_tests/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing lab test
#
# PUT /api/lab_tests/{id}
# operationId: lab_tests_update
export def "lab-tests update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/lab_tests/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search billing line items
#
# GET /api/line_items
# operationId: line_items_list
export def "line-items list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> record<data: table<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "posted_date" $posted_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "service_date" $service_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/line_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create billing line item for appointments
#
# POST /api/line_items
# operationId: line_items_create
export def "line-items create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "posted_date" $posted_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "service_date" $service_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/line_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/line_items/{id}
#
# operationId: line_items_delete
export def "line-items delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "posted_date" $posted_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "service_date" $service_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/line_items/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing billing line item
#
# GET /api/line_items/{id}
# operationId: line_items_read
export def "line-items get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "posted_date" $posted_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "service_date" $service_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/line_items/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/line_items/{id}
#
# operationId: line_items_partial_update
export def "line-items update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "posted_date" $posted_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "service_date" $service_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/line_items/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/line_items/{id}
#
# operationId: line_items_update
export def "line-items update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --posted-date: string
  --patient: int
  --office: int
  --doctor: int
  --since: string
  --appointment: int
  --service-date: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "posted_date" $posted_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "service_date" $service_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/line_items/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient medications
#
# GET /api/medications
# operationId: medications_list
export def "medications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> record<data: table<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/medications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient medications
#
# POST /api/medications
# operationId: medications_create
export def "medications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/medications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient medications
#
# GET /api/medications/{id}
# operationId: medications_read
export def "medications get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<appointment: int, date_prescribed: string, date_started_taking: string, date_stopped_taking: string, daw: bool, dispense_quantity: float, doctor: int, dosage_quantity: string, dosage_units: string, frequency: string, id: int, indication: string, name: string, ndc: string, notes: string, number_refills: int, order_status: string, patient: int, pharmacy_note: string, prn: bool, route: string, rxnorm: string, signature_note: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/medications/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient medications
#
# PATCH /api/medications/{id}
# operationId: medications_partial_update
export def "medications update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/medications/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient medications
#
# PUT /api/medications/{id}
# operationId: medications_update
export def "medications update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/medications/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Append a message to the "pharmacy_note" section of the prescription, in a new paragraph
#
# PATCH /api/medications/{id}/append_to_pharmacy_note
# operationId: medications_append_to_pharmacy_note
export def "medications-append-to-pharmacy-note create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/medications/{id}/append_to_pharmacy_note") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search messages in doctor's message center
#
# GET /api/messages
# operationId: messages_list
export def "messages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> record<data: table<archived: bool, attachment: string, doctor: int, id: int, message_notes: list, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "responsible_user" $responsible_user "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "received_since" $received_since "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create messages in doctor's message center
#
# POST /api/messages
# operationId: messages_create
export def "messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> record<archived: bool, attachment: string, doctor: int, id: int, message_notes: table<created_at: string, created_by: string, text: string>, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "responsible_user" $responsible_user "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "received_since" $received_since "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing message in doctor's message center
#
# DELETE /api/messages/{id}
# operationId: messages_delete
export def "messages delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "responsible_user" $responsible_user "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "received_since" $received_since "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing message in doctor's message center
#
# GET /api/messages/{id}
# operationId: messages_read
export def "messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> record<archived: bool, attachment: string, doctor: int, id: int, message_notes: table<created_at: string, created_by: string, text: string>, owner: string, patient: int, read: bool, received_at: string, responsible_user: string, starred: bool, title: string, type: string, updated_at: string, workflow_step: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "responsible_user" $responsible_user "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "received_since" $received_since "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing message in doctor's message center
#
# PATCH /api/messages/{id}
# operationId: messages_partial_update
export def "messages update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "responsible_user" $responsible_user "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "received_since" $received_since "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing message in doctor's message center
#
# PUT /api/messages/{id}
# operationId: messages_update
export def "messages update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
  --responsible-user: int
  --updated-since: string
  --received-since: string
  --owner: int
  --type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "responsible_user" $responsible_user "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "received_since" $received_since "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search offices
#
# GET /api/offices
# operationId: offices_list
export def "offices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: list, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/offices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing office
#
# GET /api/offices/{id}
# operationId: offices_read
export def "offices get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: table<day: int, hour: int, minute: int>, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/offices/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing office
#
# PATCH /api/offices/{id}
# operationId: offices_partial_update
export def "offices update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/offices/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing office
#
# PUT /api/offices/{id}
# operationId: offices_update
export def "offices update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/offices/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an exam room to the office
#
# POST /api/offices/{id}/add_exam_room
# operationId: offices_add_exam_room
export def "offices-add-exam-room create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<address: string, archived: bool, city: string, country: string, doctor: string, end_time: string, exam_rooms: string, fax_number: string, id: int, name: string, online_scheduling: bool, online_timeslots: table<day: int, hour: int, minute: int>, phone_number: string, start_time: string, state: string, tax_id_number_professional: string, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/offices/{id}/add_exam_room") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient communications for CQM
#
# GET /api/patient_communications
# operationId: patient_communications_list
export def "patient-communications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_communications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient communication for CQM
#
# POST /api/patient_communications
# operationId: patient_communications_create
export def "patient-communications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_communications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient communication for CQM
#
# GET /api/patient_communications/{id}
# operationId: patient_communications_read
export def "patient-communications get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_communications/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient communication for CQM
#
# PATCH /api/patient_communications/{id}
# operationId: patient_communications_partial_update
export def "patient-communications update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_communications/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient communication for CQM
#
# PUT /api/patient_communications/{id}
# operationId: patient_communications_update
export def "patient-communications update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_communications/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient flag types
#
# GET /api/patient_flag_types
# operationId: patient_flag_types_list
export def "patient-flag-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_flag_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient flag types
#
# POST /api/patient_flag_types
# operationId: patient_flag_types_create
export def "patient-flag-types create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_flag_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient flag type
#
# GET /api/patient_flag_types/{id}
# operationId: patient_flag_types_read
export def "patient-flag-types get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_flag_types/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient flag type
#
# PATCH /api/patient_flag_types/{id}
# operationId: patient_flag_types_partial_update
export def "patient-flag-types update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_flag_types/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient flag type
#
# PUT /api/patient_flag_types/{id}
# operationId: patient_flag_types_update
export def "patient-flag-types update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_flag_types/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient interventions for CQM
#
# GET /api/patient_interventions
# operationId: patient_interventions_list
export def "patient-interventions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_interventions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient intervention for CQM
#
# POST /api/patient_interventions
# operationId: patient_interventions_create
export def "patient-interventions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_interventions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient intervention for CQM
#
# GET /api/patient_interventions/{id}
# operationId: patient_interventions_read
export def "patient-interventions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_interventions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient intervention for CQM
#
# PATCH /api/patient_interventions/{id}
# operationId: patient_interventions_partial_update
export def "patient-interventions update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_interventions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient intervention for CQM
#
# PUT /api/patient_interventions/{id}
# operationId: patient_interventions_update
export def "patient-interventions update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_interventions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/patient_lab_results
#
# operationId: patient_lab_results_list
export def "patient-lab-results list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<data: table<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "ordering_doctor" $ordering_doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_lab_results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/patient_lab_results
#
# operationId: patient_lab_results_create
export def "patient-lab-results create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering_doctor" $ordering_doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_lab_results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/patient_lab_results/{id}
#
# operationId: patient_lab_results_delete
export def "patient-lab-results delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering_doctor" $ordering_doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_lab_results/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/patient_lab_results/{id}
#
# operationId: patient_lab_results_read
export def "patient-lab-results get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<created_at: string, date_test_performed: string, doctor_comments: string, doctor_signoff: bool, id: int, lab_abnormal_flag: string, lab_imported_from_ccr: string, lab_normal_range: string, lab_normal_range_units: string, lab_order_status: string, lab_result_value: string, lab_result_value_as_float: float, lab_result_value_units: string, loinc_code: string, ordering_doctor: int, patient: int, scanned_in_result: string, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering_doctor" $ordering_doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_lab_results/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/patient_lab_results/{id}
#
# operationId: patient_lab_results_partial_update
export def "patient-lab-results update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering_doctor" $ordering_doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_lab_results/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/patient_lab_results/{id}
#
# operationId: patient_lab_results_update
export def "patient-lab-results update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ordering-doctor: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering_doctor" $ordering_doctor "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_lab_results/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/patient_messages
#
# operationId: patient_messages_list
export def "patient-messages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<data: table<attachments: list, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/patient_messages
#
# operationId: patient_messages_create
export def "patient-messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<attachments: table<attachment: string, created_at: string, doctor: int, updated_at: string>, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/patient_messages/{id}
#
# operationId: patient_messages_read
export def "patient-messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<attachments: table<attachment: string, created_at: string, doctor: int, updated_at: string>, body: string, created_at: string, doctor: int, id: int, message: string, patient: int, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/patient_messages/{id}
#
# operationId: patient_messages_partial_update
export def "patient-messages update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/patient_messages/{id}
#
# operationId: patient_messages_update
export def "patient-messages update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient payment logs
#
# GET /api/patient_payment_log
# operationId: patient_payment_log_list
export def "patient-payment-log list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --office: int
  --doctor: int
]: nothing -> record<data: table<action: string, amount: float, appointment: string, created_by: string, doctor: string, id: int, patient: string, payment_method: string, source: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_payment_log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient payment log
#
# GET /api/patient_payment_log/{id}
# operationId: patient_payment_log_read
export def "patient-payment-log get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --office: int
  --doctor: int
]: nothing -> record<action: string, amount: float, appointment: string, created_by: string, doctor: string, id: int, patient: string, payment_method: string, source: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "office" $office "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_payment_log/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient payments
#
# GET /api/patient_payments
# operationId: patient_payments_list
export def "patient-payments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<data: table<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient payment
#
# POST /api/patient_payments
# operationId: patient_payments_create
export def "patient-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient payment
#
# GET /api/patient_payments/{id}
# operationId: patient_payments_read
export def "patient-payments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<amount: float, appointment: int, created_at: string, created_by: string, doctor: int, id: int, line_item: int, notes: string, patient: int, payment_method: string, payment_transaction_type: string, posted_date: string, received_date: string, trace_number: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_payments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient physical exams for CQM
#
# GET /api/patient_physical_exams
# operationId: patient_physical_exams_list
export def "patient-physical-exams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_physical_exams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient physical exam for CQM
#
# POST /api/patient_physical_exams
# operationId: patient_physical_exams_create
export def "patient-physical-exams create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_physical_exams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient physical exam for CQM
#
# GET /api/patient_physical_exams/{id}
# operationId: patient_physical_exams_read
export def "patient-physical-exams get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_physical_exams/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient physical exam for CQM
#
# PATCH /api/patient_physical_exams/{id}
# operationId: patient_physical_exams_partial_update
export def "patient-physical-exams update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_physical_exams/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient physical exam for CQM
#
# PUT /api/patient_physical_exams/{id}
# operationId: patient_physical_exams_update
export def "patient-physical-exams update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_physical_exams/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/patient_risk_assessments
#
# operationId: patient_risk_assessments_list
export def "patient-risk-assessments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> record<data: table<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_risk_assessments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/patient_risk_assessments
#
# operationId: patient_risk_assessments_create
export def "patient-risk-assessments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_risk_assessments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/patient_risk_assessments/{id}
#
# operationId: patient_risk_assessments_read
export def "patient-risk-assessments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<code: string, code_system: string, created_at: string, doctor: int, effective_time: string, id: int, name: string, patient: int, value_code: string, value_code_system: string, value_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_risk_assessments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/patient_risk_assessments/{id}
#
# operationId: patient_risk_assessments_partial_update
export def "patient-risk-assessments update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_risk_assessments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/patient_risk_assessments/{id}
#
# operationId: patient_risk_assessments_update
export def "patient-risk-assessments update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_risk_assessments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient vaccine records
#
# GET /api/patient_vaccine_records
# operationId: patient_vaccine_records_list
export def "patient-vaccine-records list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> record<data: table<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: list, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "cvx_code" $cvx_code "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_vaccine_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient vaccine records
#
# POST /api/patient_vaccine_records
# operationId: patient_vaccine_records_create
export def "patient-vaccine-records create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> record<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: table<id: int, max_age_months: int, min_age_months: int, title: string>, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cvx_code" $cvx_code "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patient_vaccine_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient vaccine records
#
# GET /api/patient_vaccine_records/{id}
# operationId: patient_vaccine_records_read
export def "patient-vaccine-records get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> record<administered_at: int, administered_by: string, administration_start: string, amount: float, comments: string, completion_status: string, consent_form: int, cpt_code: string, created_at: string, cvx_code: string, doses: table<id: int, max_age_months: int, min_age_months: int, title: string>, entered_by: string, funding_eligibility: string, id: int, name: string, next_dose_date: string, observed_immunity: string, ordering_doctor: int, patient: int, record_source: string, route: string, site: string, units: string, updated_at: string, vaccine_inventory: int, vis: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cvx_code" $cvx_code "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_vaccine_records/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient vaccine records
#
# PATCH /api/patient_vaccine_records/{id}
# operationId: patient_vaccine_records_partial_update
export def "patient-vaccine-records update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cvx_code" $cvx_code "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_vaccine_records/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient vaccine records
#
# PUT /api/patient_vaccine_records/{id}
# operationId: patient_vaccine_records_update
export def "patient-vaccine-records update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cvx-code: string
  --patient: int
  --since: string
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cvx_code" $cvx_code "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patient_vaccine_records/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patients
#
# GET /api/patients
# operationId: patients_list
export def "patients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> record<data: table<address: string, auto_accident_insurance: record, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: list, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list, patient_flags: list, patient_flags_attached: list, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record, race: string, referring_doctor: record, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record, social_security_number: string, state: string, tertiary_insurance: record, updated_at: string, workers_comp_insurance: record, zip_code: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient
#
# POST /api/patients
# operationId: patients_create
export def "patients create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing patient
#
# DELETE /api/patients/{id}
# operationId: patients_delete
export def "patients delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient
#
# GET /api/patients/{id}
# operationId: patients_read
export def "patients get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient
#
# PATCH /api/patients/{id}
# operationId: patients_partial_update
export def "patients update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient
#
# PUT /api/patients/{id}
# operationId: patients_update
export def "patients update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve patient CCDA
#
# GET /api/patients/{id}/ccda
# operationId: patients_ccda
export def "patients-ccda get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}/ccda") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke sent onpatient invites
#
# DELETE /api/patients/{id}/onpatient_access
# operationId: patients_onpatient_access_delete
export def "patients-onpatient-access delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}/onpatient_access") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search existing onpatient access invites
#
# GET /api/patients/{id}/onpatient_access
# operationId: patients_onpatient_access_read
export def "patients-onpatient-access get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}/onpatient_access") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send new onpatient invite to patient
#
# POST /api/patients/{id}/onpatient_access
# operationId: patients_onpatient_access_create
export def "patients-onpatient-access create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}/onpatient_access") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve patient QRDA1
#
# GET /api/patients/{id}/qrda1
# operationId: patients_qrda1
export def "patients-qrda1 get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --preferred-language: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
  --race: string
  --chart-id: string
  --email: string
  --ethnicity: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "preferred_language" $preferred_language "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar") (serialize-qp "race" $race "scalar") (serialize-qp "chart_id" $chart_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "ethnicity" $ethnicity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients/{id}/qrda1") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/patients_summary
#
# operationId: patients_summary_list
export def "patients-summary list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> record<data: table<address: string, auto_accident_insurance: record, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: list, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list, patient_flags: list, patient_flags_attached: list, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record, race: string, referring_doctor: record, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record, social_security_number: string, state: string, tertiary_insurance: record, updated_at: string, workers_comp_insurance: record, zip_code: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patients_summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/patients_summary
#
# operationId: patients_summary_create
export def "patients-summary create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/patients_summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/patients_summary/{id}
#
# operationId: patients_summary_delete
export def "patients-summary delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients_summary/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/patients_summary/{id}
#
# operationId: patients_summary_read
export def "patients-summary get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> record<address: string, auto_accident_insurance: record<auto_accident_case_number: string, auto_accident_claim_rep_address: string, auto_accident_claim_rep_city: string, auto_accident_claim_rep_is_insurer: bool, auto_accident_claim_rep_name: string, auto_accident_claim_rep_state: string, auto_accident_claim_rep_zip: string, auto_accident_company: string, auto_accident_date_of_accident: string, auto_accident_disabled_from_date: string, auto_accident_disabled_to_date: string, auto_accident_had_similar_condition: bool, auto_accident_is_subscriber_the_patient: bool, auto_accident_notes: string, auto_accident_patient_relationship_to_subscriber: string, auto_accident_payer_address: string, auto_accident_payer_city: string, auto_accident_payer_id: string, auto_accident_payer_state: string, auto_accident_payer_zip: string, auto_accident_policy_number: string, auto_accident_return_to_work_date: string, auto_accident_significant_injury: string, auto_accident_significant_injury_notes: string, auto_accident_similar_condition_date: string, auto_accident_similar_condition_notes: string, auto_accident_state_of_occurrence: string, auto_accident_still_under_care: bool, auto_accident_subscriber_address: string, auto_accident_subscriber_city: string, auto_accident_subscriber_date_of_birth: string, auto_accident_subscriber_first_name: string, auto_accident_subscriber_last_name: string, auto_accident_subscriber_middle_name: string, auto_accident_subscriber_phone_number: string, auto_accident_subscriber_social_security: string, auto_accident_subscriber_state: string, auto_accident_subscriber_suffix: string, auto_accident_subscriber_zip_code: string, auto_accident_treatment_duration: string, auto_accident_will_require_therapy: bool, auto_accident_will_require_therapy_rec: string>, cell_phone: string, chart_id: string, city: string, copay: string, custom_demographics: table<field_type: int, updated_at: string, value: string>, date_of_birth: string, date_of_first_appointment: string, date_of_last_appointment: string, default_pharmacy: string, disable_sms_messages: bool, doctor: int, email: string, emergency_contact_name: string, emergency_contact_phone: string, emergency_contact_relation: string, employer: string, employer_address: string, employer_city: string, employer_state: string, employer_zip_code: string, ethnicity: string, first_name: string, gender: string, home_phone: string, id: int, last_name: string, middle_name: string, nick_name: string, office_phone: string, offices: list<int>, patient_flags: table<archived: bool, color: string, created_at: string, doctor: int, id: int, name: string, priority: int, updated_at: string>, patient_flags_attached: table<archived: bool, created_at: string, flag_text: string, flag_type: int, id: int, updated_at: string>, patient_payment_profile: string, patient_photo: string, patient_photo_date: string, patient_status: string, preferred_language: string, primary_care_physician: string, primary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, race: string, referring_doctor: record<address: string, email: string, fax: string, first_name: string, last_name: string, middle_name: string, npi: string, phone: string, provider_number: string, provider_qualifier: string, specialty: string, suffix: string>, referring_source: string, responsible_party_email: string, responsible_party_name: string, responsible_party_phone: string, responsible_party_relation: string, secondary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, social_security_number: string, state: string, tertiary_insurance: record<insurance_claim_office_number: string, insurance_company: string, insurance_group_name: string, insurance_group_number: string, insurance_id_number: string, insurance_payer_id: string, insurance_plan_name: string, insurance_plan_type: string, is_subscriber_the_patient: bool, patient_relationship_to_subscriber: string, photo_back: string, photo_front: string, subscriber_address: string, subscriber_city: string, subscriber_country: string, subscriber_date_of_birth: string, subscriber_first_name: string, subscriber_gender: string, subscriber_last_name: string, subscriber_middle_name: string, subscriber_social_security: string, subscriber_state: string, subscriber_suffix: string, subscriber_zip_code: string>, updated_at: string, workers_comp_insurance: record<property_and_casualty_agency_claim_number: string, workers_comp_carrier_code: string, workers_comp_case_number: string, workers_comp_company: string, workers_comp_date_of_accident: string, workers_comp_group_name: string, workers_comp_group_number: string, workers_comp_notes: string, workers_comp_payer_address: string, workers_comp_payer_city: string, workers_comp_payer_id: string, workers_comp_payer_state: string, workers_comp_payer_zip: string, workers_comp_state_of_occurrence: string, workers_comp_wcb: string, workers_comp_wcb_rating_code: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients_summary/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/patients_summary/{id}
#
# operationId: patients_summary_partial_update
export def "patients-summary update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients_summary/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/patients_summary/{id}
#
# operationId: patients_summary_update
export def "patients-summary update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string
  --last-name: string
  --doctor: int
  --gender: string
  --since: string
  --date-of-birth: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "gender" $gender "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "date_of_birth" $date_of_birth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/patients_summary/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search prescription messages
#
# GET /api/prescription_messages
# operationId: prescription_messages_list
export def "prescription-messages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --parent-message: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<data: table<created_at: string, doctor: int, id: int, json_data: string, message_direction: string, message_status: string, message_type: string, parent_message: string, patient: int, pharmacy: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "parent_message" $parent_message "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/prescription_messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing prescription message
#
# GET /api/prescription_messages/{id}
# operationId: prescription_messages_read
export def "prescription-messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-message: int
  --since: string
  --patient: int
  --doctor: int
]: nothing -> record<created_at: string, doctor: int, id: int, json_data: string, message_direction: string, message_status: string, message_type: string, parent_message: string, patient: int, pharmacy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_message" $parent_message "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/prescription_messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search patient problems
#
# GET /api/problems
# operationId: problems_list
export def "problems list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --patient: int
  --doctor: int
]: nothing -> record<data: table<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/problems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create patient problems
#
# POST /api/problems
# operationId: problems_create
export def "problems create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/problems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing patient problems
#
# GET /api/problems/{id}
# operationId: problems_read
export def "problems get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> record<date_changed: string, date_diagnosis: string, date_onset: string, description: string, doctor: int, icd_code: string, icd_version: string, id: int, info_url: string, name: string, notes: string, patient: int, snomed_ct_code: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/problems/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient problems
#
# PATCH /api/problems/{id}
# operationId: problems_partial_update
export def "problems update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/problems/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing patient problems
#
# PUT /api/problems/{id}
# operationId: problems_update
export def "problems update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --patient: int
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/problems/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/procedures
#
# operationId: procedures_list
export def "procedures list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --mu-date: string
  --patient: int
  --doctor: int
  --mu-date-range: string
  --appointment: int
  --service-date: string
]: nothing -> record<data: table<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "mu_date" $mu_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "mu_date_range" $mu_date_range "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "service_date" $service_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/procedures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/procedures/{id}
#
# operationId: procedures_read
export def "procedures get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mu-date: string
  --patient: int
  --doctor: int
  --mu-date-range: string
  --appointment: int
  --service-date: string
]: nothing -> record<adjustment: float, allowed: float, appointment: int, balance_ins: float, balance_pt: float, balance_total: string, billed: float, billing_status: string, code: string, denied_flag: bool, description: string, diagnosis_pointers: list<string>, doctor: string, expected_reimbursement: float, id: int, ins1_paid: float, ins2_paid: float, ins3_paid: float, ins_total: string, insurance_status: string, modifiers: list<string>, paid_total: string, patient: string, posted_date: string, price: float, procedure_type: string, pt_paid: float, quantity: float, service_date: string, units: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mu_date" $mu_date "scalar") (serialize-qp "patient" $patient "scalar") (serialize-qp "doctor" $doctor "scalar") (serialize-qp "mu_date_range" $mu_date_range "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "service_date" $service_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/procedures/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search reminder profiles
#
# GET /api/reminder_profiles
# operationId: reminder_profiles_list
export def "reminder-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<doctor: int, id: int, name: string, reminders: list>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/reminder_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create reminder profile
#
# POST /api/reminder_profiles
# operationId: reminder_profiles_create
export def "reminder-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<doctor: int, id: int, name: string, reminders: table<amount: int, type: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/reminder_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing reminder profile
#
# DELETE /api/reminder_profiles/{id}
# operationId: reminder_profiles_delete
export def "reminder-profiles delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/reminder_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing reminder profile
#
# GET /api/reminder_profiles/{id}
# operationId: reminder_profiles_read
export def "reminder-profiles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<doctor: int, id: int, name: string, reminders: table<amount: int, type: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/reminder_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing reminder profile
#
# PATCH /api/reminder_profiles/{id}
# operationId: reminder_profiles_partial_update
export def "reminder-profiles update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/reminder_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing reminder profile
#
# PUT /api/reminder_profiles/{id}
# operationId: reminder_profiles_update
export def "reminder-profiles update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/reminder_profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search sub vendors
#
# GET /api/sublabs
# operationId: sublabs_list
export def "sublabs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
]: nothing -> record<data: table<facility_code: string, id: int, name: string, vendor_name: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/sublabs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create sub-vendors - When you get orders, submit them via `/api/lab_orders`, such that doctors can see them in drchrono. - When results come in, submit the result document PDF via `/api/lab_documents` and submit the results data via `/api/lab_results` - Update `/api/lab_orders` status
#
# POST /api/sublabs
# operationId: sublabs_create
export def "sublabs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<facility_code: string, id: int, name: string, vendor_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/sublabs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing sub vendor
#
# DELETE /api/sublabs/{id}
# operationId: sublabs_delete
export def "sublabs delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/sublabs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing sub vendor
#
# GET /api/sublabs/{id}
# operationId: sublabs_read
export def "sublabs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<facility_code: string, id: int, name: string, vendor_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/sublabs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing sub vendor
#
# PATCH /api/sublabs/{id}
# operationId: sublabs_partial_update
export def "sublabs update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/sublabs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing sub vendor
#
# PUT /api/sublabs/{id}
# operationId: sublabs_update
export def "sublabs update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/sublabs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search task categories
#
# GET /api/task_categories
# operationId: task_categories_list
export def "task-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
]: nothing -> record<data: table<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/task_categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task category
#
# POST /api/task_categories
# operationId: task_categories_create
export def "task-categories create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> record<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/task_categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing task category
#
# GET /api/task_categories/{id}
# operationId: task_categories_read
export def "task-categories get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> record<archived: bool, created_at: string, id: int, is_global: string, name: string, practice_group: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_categories/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task category
#
# PATCH /api/task_categories/{id}
# operationId: task_categories_partial_update
export def "task-categories update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_categories/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task category
#
# PUT /api/task_categories/{id}
# operationId: task_categories_update
export def "task-categories update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_categories/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search task notes
#
# GET /api/task_notes
# operationId: task_notes_list
export def "task-notes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --task: int
  --since: string
]: nothing -> record<data: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "task" $task "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/task_notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task note
#
# POST /api/task_notes
# operationId: task_notes_create
export def "task-notes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --task: int
  --since: string
]: nothing -> record<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "task" $task "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/task_notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing task note
#
# GET /api/task_notes/{id}
# operationId: task_notes_read
export def "task-notes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --task: int
  --since: string
]: nothing -> record<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "task" $task "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_notes/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task note
#
# PATCH /api/task_notes/{id}
# operationId: task_notes_partial_update
export def "task-notes update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --task: int
  --since: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "task" $task "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_notes/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task note
#
# PUT /api/task_notes/{id}
# operationId: task_notes_update
export def "task-notes update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --task: int
  --since: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "task" $task "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_notes/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search task statuses
#
# GET /api/task_statuses
# operationId: task_statuses_list
export def "task-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --since: string
]: nothing -> record<data: table<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/task_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task status
#
# POST /api/task_statuses
# operationId: task_statuses_create
export def "task-statuses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> record<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/task_statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing task status
#
# GET /api/task_statuses/{id}
# operationId: task_statuses_read
export def "task-statuses get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> record<archived: bool, created_at: string, id: int, name: string, practice_group: int, status_category: string, task_category: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_statuses/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task status
#
# PATCH /api/task_statuses/{id}
# operationId: task_statuses_partial_update
export def "task-statuses update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_statuses/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task status
#
# PUT /api/task_statuses/{id}
# operationId: task_statuses_update
export def "task-statuses update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_statuses/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search task templates
#
# GET /api/task_templates
# operationId: task_templates_list
export def "task-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> record<data: table<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/task_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task template
#
# POST /api/task_templates
# operationId: task_templates_create
export def "task-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> record<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/task_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing task template
#
# GET /api/task_templates/{id}
# operationId: task_templates_read
export def "task-templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> record<archived: bool, created_at: string, default_assignee_group: int, default_assignee_user: string, default_category: int, default_due_date_offset: string, default_note: string, default_priority: string, default_status: int, default_title: string, id: int, name: string, practice_group: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task template
#
# PATCH /api/task_templates/{id}
# operationId: task_templates_partial_update
export def "task-templates update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task template
#
# PUT /api/task_templates/{id}
# operationId: task_templates_update
export def "task-templates update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee-user: int
  --status: int
  --assignee-group: int
  --since: string
  --category: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/task_templates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search tasks
#
# GET /api/tasks
# operationId: tasks_list
export def "tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> record<data: table<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: list, category: int, created_at: string, created_by: string, due_date: record, id: int, notes: list, priority: string, status: int, title: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "due_at_date" $due_at_date "scalar") (serialize-qp "due_at_unknown" $due_at_unknown "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "due_at_since" $due_at_since "scalar") (serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "due_at_range" $due_at_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task
#
# POST /api/tasks
# operationId: tasks_create
export def "tasks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> record<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: table<task: int, type: string, value: int>, category: int, created_at: string, created_by: string, due_date: record<time: string>, id: int, notes: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, priority: string, status: int, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "due_at_date" $due_at_date "scalar") (serialize-qp "due_at_unknown" $due_at_unknown "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "due_at_since" $due_at_since "scalar") (serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "due_at_range" $due_at_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing task
#
# GET /api/tasks/{id}
# operationId: tasks_read
export def "tasks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> record<archived: bool, assigned_by: string, assignee_group: int, assignee_user: string, associated_items: table<task: int, type: string, value: int>, category: int, created_at: string, created_by: string, due_date: record<time: string>, id: int, notes: table<archived: bool, created_at: string, created_by: string, id: int, task: int, text: string, updated_at: string>, priority: string, status: int, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "due_at_date" $due_at_date "scalar") (serialize-qp "due_at_unknown" $due_at_unknown "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "due_at_since" $due_at_since "scalar") (serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "due_at_range" $due_at_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/tasks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task
#
# PATCH /api/tasks/{id}
# operationId: tasks_partial_update
export def "tasks update-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "due_at_date" $due_at_date "scalar") (serialize-qp "due_at_unknown" $due_at_unknown "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "due_at_since" $due_at_since "scalar") (serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "due_at_range" $due_at_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/tasks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing task
#
# PUT /api/tasks/{id}
# operationId: tasks_update
export def "tasks update-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: int
  --category: int
  --due-at-date: string
  --due-at-unknown: string
  --since: string
  --due-at-since: string
  --assignee-user: int
  --assignee-group: int
  --due-at-range: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "due_at_date" $due_at_date "scalar") (serialize-qp "due_at_unknown" $due_at_unknown "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "due_at_since" $due_at_since "scalar") (serialize-qp "assignee_user" $assignee_user "scalar") (serialize-qp "assignee_group" $assignee_group "scalar") (serialize-qp "due_at_range" $due_at_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/tasks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search insurance transactions associated with billing line items
#
# GET /api/transactions
# operationId: transactions_list
export def "transactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --line-item: int
  --posted-date: string
  --appointment: int
  --since: string
  --doctor: int
]: nothing -> record<data: table<adjustment: float, adjustment_group_code: string, adjustment_reason: string, appointment: int, check_date: string, claim_status: string, created_at: string, doctor: int, id: int, ins_name: int, ins_paid: float, line_item: int, patient: int, posted_date: string, trace_number: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "line_item" $line_item "scalar") (serialize-qp "posted_date" $posted_date "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing insurance transaction
#
# GET /api/transactions/{id}
# operationId: transactions_read
export def "transactions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --line-item: int
  --posted-date: string
  --appointment: int
  --since: string
  --doctor: int
]: nothing -> record<adjustment: float, adjustment_group_code: string, adjustment_reason: string, appointment: int, check_date: string, claim_status: string, created_at: string, doctor: int, id: int, ins_name: int, ins_paid: float, line_item: int, patient: int, posted_date: string, trace_number: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "line_item" $line_item "scalar") (serialize-qp "posted_date" $posted_date "scalar") (serialize-qp "appointment" $appointment "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/transactions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search user groups
#
# GET /api/user_groups
# operationId: user_groups_list
export def "user-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<archived: bool, created_at: string, id: int, members: list, name: string, practice_group: string, updated_at: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing user group
#
# GET /api/user_groups/{id}
# operationId: user_groups_read
export def "user-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<archived: bool, created_at: string, id: int, members: list<string>, name: string, practice_group: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/user_groups/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve or search users, `/api/users/current` can be used to identify logged in user, it will redirect to `/api/users/{current_user_id}`
#
# GET /api/users
# operationId: users_list
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --page-size: int
  --doctor: int
]: nothing -> record<data: table<doctor: string, id: string, is_doctor: string, is_staff: string, permissions: string, practice_group: string, username: string>, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an existing user, `/api/users/current` can be used to identify logged in user, it will redirect to `/api/users/{current_user_id}`
#
# GET /api/users/{id}
# operationId: users_read
export def "users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doctor: int
]: nothing -> record<doctor: string, id: string, is_doctor: string, is_staff: string, permissions: string, practice_group: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doctor" $doctor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
