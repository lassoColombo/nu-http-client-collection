# Auto-generated client for Statutory Instruments API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/statutoryinstruments/v1/openapi.json
# Auth: --token flag or $env.STATUTORY_INSTRUMENTS_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STATUTORY_INSTRUMENTS_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def LaidPaper-completer [] { ["ProposedNegative" "StatutoryInstrument"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def StatutoryInstrumentType-completer [] { ["DraftAffirmative" "DraftNegative" "MadeAffirmative" "MadeNegative"] }
def ParliamentaryProcessConcluded-completer [] { ["Concluded" "NotConcluded"] }
def House-completer [] { ["Commons" "Lords"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "business-item GetBusinessItemById" } } | get name | first)
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

# Returns business item by ID.
#
# GET /api/v1/BusinessItem/{id}
# operationId: GetBusinessItemById
export def "business-item GetBusinessItemById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --LaidPaper: string@LaidPaper-completer # Business item by laid paper type
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<businessItemUri: string, houseId: string, houseName: string, houseUri: string, houses: list<record>, id: string, itemDate: string, laidPaperType: string, link: string, procedureStepId: string, procedureStepUri: string, sequence: int, statutoryInstrumentId: string, statutoryInstrumentUri: string, stepName: string, workpackageProcedureUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LaidPaper" $LaidPaper "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/BusinessItem/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all laying bodies.
#
# GET /api/v1/LayingBody
# operationId: GetLayingBodies
export def "laying-body GetLayingBodies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<links: list, value: record>, itemsPerPage: int, links: table<href: string, method: string, rel: string>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/LayingBody")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all procedures.
#
# GET /api/v1/Procedure
# operationId: GetProceduresV1
export def "procedure GetProceduresV1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<links: list, value: record>, itemsPerPage: int, links: table<href: string, method: string, rel: string>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Procedure")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns procedure by ID.
#
# GET /api/v1/Procedure/{id}
# operationId: GetProceduresByIdV1
export def "procedure GetProceduresByIdV1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<description: string, id: string, name: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Procedure/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of proposed negative statutory instruments.
#
# GET /api/v1/ProposedNegativeStatutoryInstrument
# operationId: GetProposedNegativeStatutoryInstruments
export def "proposed-negative-statutory-instrument GetProposedNegativeStatutoryInstruments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Name: string # Proposed negative statutory instruments with the name provided
  --RecommendedForProcedureChange: oneof<nothing, bool> # Proposed negative statutory instruments recommended for procedure change
  --DepartmentId: int # Proposed negative statutory instruments with the department ID specified (format: int32)
  --LayingBodyId: string # Proposed negative statutory instruments with the laying body ID specified
  --Skip: int # The number of records to skip from the first, default is 0 (format: int32)
  --Take: int # The number of records to return, default is 20 (format: int32)
]: nothing -> record<items: table<links: list, value: record>, itemsPerPage: int, links: table<href: string, method: string, rel: string>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "RecommendedForProcedureChange" $RecommendedForProcedureChange "scalar") (serialize-qp "DepartmentId" $DepartmentId "scalar") (serialize-qp "LayingBodyId" $LayingBodyId "scalar") (serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/ProposedNegativeStatutoryInstrument" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns proposed negative statutory instrument by ID.
#
# GET /api/v1/ProposedNegativeStatutoryInstrument/{id}
# operationId: GetProposedNegativeStatutoryInstrumentById
export def "proposed-negative-statutory-instrument GetProposedNegativeStatutoryInstrumentById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<commonsLayingDate: string, commonsPublishedDate: string, departmentId: int, id: string, layingBodyDepartment: record<departmentId: int, id: string, name: string>, layingBodyId: string, layingBodyName: string, link: string, lordsLayingDate: string, lordsPublishedDate: string, name: string, procedure: record<id: string, name: string, uri: string>, procedureName: string, procedureUri: string, statutoryInstrument: record<id: string, name: string>, statutoryInstrumentPaperId: string, statutoryInstrumentPaperName: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/ProposedNegativeStatutoryInstrument/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns business items belonging to a proposed negative statutory instrument.
#
# GET /api/v1/ProposedNegativeStatutoryInstrument/{id}/BusinessItems
# operationId: GetBusinessItemsByProposedNegativeStatutoryInstrumentId
export def "proposed-negative-statutory-instrument-business-items GetBusinessItemsByProposedNegativeStatutoryInstrumentId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<links: list, value: record>, itemsPerPage: int, links: table<href: string, method: string, rel: string>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/ProposedNegativeStatutoryInstrument/($id)/BusinessItems")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of statutory instruments.
#
# GET /api/v1/StatutoryInstrument
# operationId: GetStatutoryInstruments
export def "statutory-instrument GetStatutoryInstruments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Name: string # Statutory instruments with the name specified
  --StatutoryInstrumentType: string@StatutoryInstrumentType-completer # Statutory instruments where the statutory instrument type is the type provided
  --ScheduledDebate: oneof<nothing, bool> # Statutory instrument which contains a scheduled debate
  --MotionToStop: oneof<nothing, bool> # Statutory instruments which contains a motion to stop
  --ConcernsRaisedByCommittee: oneof<nothing, bool> # Statutory instruments which contains concerns raised by committee
  --ParliamentaryProcessConcluded: string@ParliamentaryProcessConcluded-completer # Statutory instruments where the parliamentary process is concluded or notconcluded
  --DepartmentId: int # Statutory instruments with the department ID specified (format: int32)
  --LayingBodyId: string # Statutory instruments with the laying body ID specified
  --House: string@House-completer # Statutory instruments laid in the house specified
  --Skip: int # The number of records to skip from the first, default is 0 (format: int32)
  --Take: int # The number of records to return, default is 20 (format: int32)
]: nothing -> record<items: table<links: list, value: record>, itemsPerPage: int, links: table<href: string, method: string, rel: string>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Name" $Name "scalar") (serialize-qp "StatutoryInstrumentType" $StatutoryInstrumentType "scalar") (serialize-qp "ScheduledDebate" $ScheduledDebate "scalar") (serialize-qp "MotionToStop" $MotionToStop "scalar") (serialize-qp "ConcernsRaisedByCommittee" $ConcernsRaisedByCommittee "scalar") (serialize-qp "ParliamentaryProcessConcluded" $ParliamentaryProcessConcluded "scalar") (serialize-qp "DepartmentId" $DepartmentId "scalar") (serialize-qp "LayingBodyId" $LayingBodyId "scalar") (serialize-qp "House" $House "scalar") (serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/StatutoryInstrument" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a statutory instrument by ID.
#
# GET /api/v1/StatutoryInstrument/{id}
# operationId: GetStatutoryInstrumentById
export def "statutory-instrument GetStatutoryInstrumentById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<commonsLayingDate: string, commonsPublishedDate: string, departmentId: int, id: string, layingBodyDepartment: record<departmentId: int, id: string, name: string>, layingBodyId: string, layingBodyName: string, link: string, lordsLayingDate: string, lordsPublishedDate: string, name: string, paperComingIntoForceDate: string, paperComingIntoForceNote: string, paperMadeDate: string, paperNumber: int, paperPrefix: string, paperYear: string, procedure: record<id: string, name: string, uri: string>, procedureName: string, procedureUri: string, proposedNegativeStatutoryInstrument: record<id: string, name: string>, proposedNegativeStatutoryInstrumentPaperId: string, proposedNegativeStatutoryInstrumentPaperName: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/StatutoryInstrument/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns business items belonging to statutory instrument with ID.
#
# GET /api/v1/StatutoryInstrument/{id}/BusinessItems
# operationId: GetBusinessItemsByStatutoryInstrumentId
export def "statutory-instrument-business-items GetBusinessItemsByStatutoryInstrumentId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<links: list, value: record>, itemsPerPage: int, links: table<href: string, method: string, rel: string>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/StatutoryInstrument/($id)/BusinessItems")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
