# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Detailed Facility Report (DFR) v0.0.0
# Source: https://api.apis.guru/v2/specs/epa.gov/dfr/0.0.0/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____DETAILED_FACILITY_REPORT__DFR_TOKEN

const BASE_URL = "https://echodata.epa.gov/echo"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____DETAILED_FACILITY_REPORT__DFR_TOKEN | default "" }
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

def base-url-completer [] { ["https://echodata.epa.gov/echo"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def output-completer [] { ["JSON" "JSONP" "XML"] }
def p-missinglate-completer [] { ["LATE" "MISSING"] }
def p-qmtype-completer [] { ["MONTH" "QUARTER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "dfr-rest-servicesair-3-yr-download get" } } | get name | first)
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

# Downloads the complete Air Compliance History Section of the DFR
#
# GET /dfr_rest_services.air_3_yr_download
export def "dfr-rest-servicesair-3-yr-download get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.air_3_yr_download")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the complete Air Compliance History Section of the DFR
#
# POST /dfr_rest_services.air_3_yr_download
export def "dfr-rest-servicesair-3-yr-download post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.air_3_yr_download")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads NPDES Effluent Violation Information by month and quarter.
#
# GET /dfr_rest_services.cwa_3_yr_effluent_download
export def "dfr-rest-servicescwa-3-yr-effluent-download get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.cwa_3_yr_effluent_download")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads NPDES Effluent Violation Information by month and quarter.
#
# POST /dfr_rest_services.cwa_3_yr_effluent_download
export def "dfr-rest-servicescwa-3-yr-effluent-download post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.cwa_3_yr_effluent_download")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads NPDES Compliance Schedule, Permit Schedule and Single Event Violation Information by month and quarter.
#
# GET /dfr_rest_services.cwa_3_yr_sepscs_download
export def "dfr-rest-servicescwa-3-yr-sepscs-download get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.cwa_3_yr_sepscs_download")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads NPDES Compliance Schedule, Permit Schedule and Single Event Violation Information by month and quarter.
#
# POST /dfr_rest_services.cwa_3_yr_sepscs_download
export def "dfr-rest-servicescwa-3-yr-sepscs-download post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.cwa_3_yr_sepscs_download")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Air Compliance Report Service
#
# GET /dfr_rest_services.get_air_compliance
export def "dfr-rest-servicesget-air-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<AirCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_air_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Air Compliance Report Service
#
# POST /dfr_rest_services.get_air_compliance
export def "dfr-rest-servicesget-air-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<AirCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_air_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Air Quality Report Service
#
# GET /dfr_rest_services.get_air_quality
export def "dfr-rest-servicesget-air-quality get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_air_quality" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Air Quality Report Service
#
# POST /dfr_rest_services.get_air_quality
export def "dfr-rest-servicesget-air-quality post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_air_quality")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Placeholder
#
# GET /dfr_rest_services.get_aws_docs
export def "dfr-rest-servicesget-aws-docs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_aws_docs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Placeholder
#
# POST /dfr_rest_services.get_aws_docs
export def "dfr-rest-servicesget-aws-docs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_aws_docs")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays Cases related to the Facility
#
# GET /dfr_rest_services.get_case_formal_actions
export def "dfr-rest-servicesget-case-formal-actions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CaseFormalActions: record<Action: list, ProgramDates: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_case_formal_actions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays Cases related to the Facility
#
# POST /dfr_rest_services.get_case_formal_actions
export def "dfr-rest-servicesget-case-formal-actions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CaseFormalActions: record<Action: list, ProgramDates: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_case_formal_actions")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report 5 Year Compliance Monitoring History Service
#
# GET /dfr_rest_services.get_compliance_history
export def "dfr-rest-servicesget-compliance-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<ComplianceHistory: record<Inspection: list, ProgramDates: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_compliance_history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report 5 Year Compliance Monitoring History Service
#
# POST /dfr_rest_services.get_compliance_history
export def "dfr-rest-servicesget-compliance-history post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<ComplianceHistory: record<Inspection: list, ProgramDates: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_compliance_history")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Compliance Summary Service
#
# GET /dfr_rest_services.get_compliance_summary
export def "dfr-rest-servicesget-compliance-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<ComplianceSummary: record<ProgramDates: list, Source: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_compliance_summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Compliance Summary Service
#
# POST /dfr_rest_services.get_compliance_summary
export def "dfr-rest-servicesget-compliance-summary post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<ComplianceSummary: record<ProgramDates: list, Source: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_compliance_summary")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads a spectific section  of the DFR in CSV Format
#
# GET /dfr_rest_services.get_csv
export def "dfr-rest-servicesget-csv get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_csv")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads a spectific section  of the DFR in CSV Format
#
# POST /dfr_rest_services.get_csv
export def "dfr-rest-servicesget-csv post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_csv")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report 3 Year CWA Facility-Level Status Service
#
# GET /dfr_rest_services.get_cwa_3yr_compliance
export def "dfr-rest-servicesget-cwa-3yr-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWA3YrCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_3yr_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report 3 Year CWA Facility-Level Status Service
#
# POST /dfr_rest_services.get_cwa_3yr_compliance
export def "dfr-rest-servicesget-cwa-3yr-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWA3YrCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_3yr_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays monlthly and quarterly counts of D80 and D90 Effluent Non Reporting Violations Related to the Facility
#
# GET /dfr_rest_services.get_cwa_3yr_d80d90_counts
export def "dfr-rest-servicesget-cwa-3yr-d80d90-counts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWA3YrD80D90Counts: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_3yr_d80d90_counts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays monlthly and quarterly counts of D80 and D90 Effluent Non Reporting Violations Related to the Facility
#
# POST /dfr_rest_services.get_cwa_3yr_d80d90_counts
export def "dfr-rest-servicesget-cwa-3yr-d80d90-counts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWA3YrD80D90Counts: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_3yr_d80d90_counts")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA CSV Compliance Service
#
# GET /dfr_rest_services.get_cwa_cs_compliance
export def "dfr-rest-servicesget-cwa-cs-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWACSCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_cs_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA CSV Compliance Service
#
# POST /dfr_rest_services.get_cwa_cs_compliance
export def "dfr-rest-servicesget-cwa-cs-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWACSCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_cs_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA Effluent ALR Service
#
# GET /dfr_rest_services.get_cwa_eff_alr
export def "dfr-rest-servicesget-cwa-eff-alr get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWAEffluentALRExceedences: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_eff_alr" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA Effluent ALR Service
#
# POST /dfr_rest_services.get_cwa_eff_alr
export def "dfr-rest-servicesget-cwa-eff-alr post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWAEffluentALRExceedences: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_eff_alr")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Placeholder
#
# GET /dfr_rest_services.get_cwa_eff_alr_exp
export def "dfr-rest-servicesget-cwa-eff-alr-exp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_eff_alr_exp" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Placeholder
#
# POST /dfr_rest_services.get_cwa_eff_alr_exp
export def "dfr-rest-servicesget-cwa-eff-alr-exp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_eff_alr_exp")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA Effluent Compliance Service
#
# GET /dfr_rest_services.get_cwa_eff_compliance
export def "dfr-rest-servicesget-cwa-eff-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWAEffluentCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_eff_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA Effluent Compliance Service
#
# POST /dfr_rest_services.get_cwa_eff_compliance
export def "dfr-rest-servicesget-cwa-eff-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWAEffluentCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_eff_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Placeholder
#
# GET /dfr_rest_services.get_cwa_eff_compliance_exp
export def "dfr-rest-servicesget-cwa-eff-compliance-exp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWAEffluentComplianceEXP: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_eff_compliance_exp" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Placeholder
#
# POST /dfr_rest_services.get_cwa_eff_compliance_exp
export def "dfr-rest-servicesget-cwa-eff-compliance-exp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWAEffluentComplianceEXP: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_eff_compliance_exp")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA PSV Compliance Service
#
# GET /dfr_rest_services.get_cwa_ps_compliance
export def "dfr-rest-servicesget-cwa-ps-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWAPSCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_ps_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA PSV Compliance Service
#
# POST /dfr_rest_services.get_cwa_ps_compliance
export def "dfr-rest-servicesget-cwa-ps-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWAPSCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_ps_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA RNC Compliance Service
#
# GET /dfr_rest_services.get_cwa_rnc_compliance
export def "dfr-rest-servicesget-cwa-rnc-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWARNCCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_rnc_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA RNC Compliance Service
#
# POST /dfr_rest_services.get_cwa_rnc_compliance
export def "dfr-rest-servicesget-cwa-rnc-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWARNCCompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_rnc_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA SEV Compliance Service
#
# GET /dfr_rest_services.get_cwa_se_compliance
export def "dfr-rest-servicesget-cwa-se-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWASECompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_se_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report CWA SEV Compliance Service
#
# POST /dfr_rest_services.get_cwa_se_compliance
export def "dfr-rest-servicesget-cwa-se-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<CWASECompliance: record<Header: record, Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_cwa_se_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Display detailed D80/D90 information for the facility for a given quarter or month
#
# GET /dfr_rest_services.get_d80d90s_details
export def "dfr-rest-servicesget-d80d90s-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-npdes-id: string # The NPDES_ID for the NPDES Permit to download DMR D80 and D90 Non-Receipt violations.
  --p-missinglate: string@p-missinglate-completer # For the D80.D90 download, identifies whether or not MISSINGviolations are downloaded or LATE violations are downloaded.  Valid values are:  MiISSING and LATE.
  --p-qmtype: string@p-qmtype-completer # Identifies the time frame type, month or quarter, for the D80/D90 download.
  --p-qmvalue: string # A number between 1 and 39 that identifies the specific month or quarter for the D80/D90 violation download.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<D80D90sDetails: record<Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_npdes_id" $p_npdes_id "scalar") (serialize-qp "p_missinglate" $p_missinglate "scalar") (serialize-qp "p_qmtype" $p_qmtype "scalar") (serialize-qp "p_qmvalue" $p_qmvalue "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_d80d90s_details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Display detailed D80/D90 information for the facility for a given quarter or month
#
# POST /dfr_rest_services.get_d80d90s_details
export def "dfr-rest-servicesget-d80d90s-details post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-npdes-id: string # The NPDES_ID for the NPDES Permit to download DMR D80 and D90 Non-Receipt violations.
  --p-missinglate: string@p-missinglate-completer # For the D80.D90 download, identifies whether or not MISSINGviolations are downloaded or LATE violations are downloaded.  Valid values are:  MiISSING and LATE.
  --p-qmtype: string@p-qmtype-completer # Identifies the time frame type, month or quarter, for the D80/D90 download.
  --p-qmvalue: string # A number between 1 and 39 that identifies the specific month or quarter for the D80/D90 violation download.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<D80D90sDetails: record<Sources: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_npdes_id" $p_npdes_id "scalar") (serialize-qp "p_missinglate" $p_missinglate "scalar") (serialize-qp "p_qmtype" $p_qmtype "scalar") (serialize-qp "p_qmvalue" $p_qmvalue "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_d80d90s_details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays 2010 Census and ACS demographics by Facility ID
#
# GET /dfr_rest_services.get_demographics_by_id
export def "dfr-rest-servicesget-demographics-by-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_demographics_by_id" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays 2010 Census and ACS demographics by Facility ID
#
# POST /dfr_rest_services.get_demographics_by_id
export def "dfr-rest-servicesget-demographics-by-id post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_demographics_by_id")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Service
#
# GET /dfr_rest_services.get_dfr
export def "dfr-rest-servicesget-dfr get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --p-system: string # System Acronym Filter.  Enter a single system acronym to filter results.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<AirCompliance: record<Header: record, Sources: list>, AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, CAEDDocuments: list<record>, CWA3YrCompliance: record<Header: record, Sources: list>, CWA3YrD80D90Counts: record<Header: record, Sources: list>, CWACSCompliance: record<Header: record, Sources: list>, CWAEffluentALRExceedences: record<Header: record, Sources: list>, CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, CWAEffluentCompliance: record<Header: record, Sources: list>, CWAEffluentComplianceEXP: record<Header: record, Sources: list>, CWAPSCompliance: record<Header: record, Sources: list>, CWARNCCompliance: record<Header: record, Sources: list>, CWASECompliance: record<Header: record, Sources: list>, CaseFormalActions: record<Action: list, ProgramDates: list>, ComplianceHistory: record<Inspection: list, ProgramDates: list>, ComplianceSummary: record<ProgramDates: list, Source: list>, Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, FormalActions: record<Action: list, ProgramDates: list>, ICISFormalActions: record<Action: list, ProgramDates: list>, InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string, MultipleFRSFacilities: record<RegistryIDs: list>, NAICS: record<Sources: list>, Notices: record<Notice: list, ProgramDates: list>, Permits: list<record>, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, Reports: record<HasPollRpt: string>, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, SIC: record<Sources: list>, SanitarySurveys: record<Sources: list>, SiteVisits: record<Sources: list>, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>, SystemExtractDates: record<Dates: list>, TRIHistory: record<Sources: list>, TRIReleases: record<Chemicals: list, Header: list>, Tribes: list<record>, ViolationsEnforcementActions: record<Sources: list>, WaterQuality: record<Sources: list>, WaterQualityDetails: record<Sources: list>, WebFireDocuments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "p_system" $p_system "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_dfr" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Service
#
# POST /dfr_rest_services.get_dfr
export def "dfr-rest-servicesget-dfr post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<AirCompliance: record<Header: record, Sources: list>, AirQuality: record<CarbonMonoxide1971Area: string, Lead1978Area: string, Lead2008Area: string, NitrogenDioxide1971Area: string, Ozone8hr1997Area: string, Ozone8hr2008Area: string, Ozone8hr2015Area: string, ParticulateMatter1987Area: string, ParticulateMatter1997Area: string, ParticulateMatter2006Area: string, ParticulateMatter2012Area: string, SulfurDioxide1971Area: string, SulfurDioxide2010Area: string>, CAEDDocuments: list<record>, CWA3YrCompliance: record<Header: record, Sources: list>, CWA3YrD80D90Counts: record<Header: record, Sources: list>, CWACSCompliance: record<Header: record, Sources: list>, CWAEffluentALRExceedences: record<Header: record, Sources: list>, CWAEffluentALRExceedencesEXP: record<Header: record, Sources: list>, CWAEffluentCompliance: record<Header: record, Sources: list>, CWAEffluentComplianceEXP: record<Header: record, Sources: list>, CWAPSCompliance: record<Header: record, Sources: list>, CWARNCCompliance: record<Header: record, Sources: list>, CWASECompliance: record<Header: record, Sources: list>, CaseFormalActions: record<Action: list, ProgramDates: list>, ComplianceHistory: record<Inspection: list, ProgramDates: list>, ComplianceSummary: record<ProgramDates: list, Source: list>, Demographics: record<Adults: string, AfricanAmerican: string, AmericanIndian: string, AsianPacificIslander: string, BSBA: string, CenterLatitude: string, CenterLongitude: string, Child: string, Grades9to12: string, HSDiploma: string, HispanicOrigin: string, Households: string, HouseholdsPublicAssistance: string, HousingUnits: string, Income15to25k: string, Income25to50k: string, Income50to75k: string, Income75kPlus: string, IncomeLess15k: string, LandArea: string, Less9thGrade: string, Minors: string, OtherMultiracial: string, PercentMinority: string, PersonsBelowPovertyLevel: string, PopulationDensity: string, Radius: string, Seniors: string, SomeCollege: string, TotalPersons: string, WaterArea: string, White: string>, EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, FormalActions: record<Action: list, ProgramDates: list>, ICISFormalActions: record<Action: list, ProgramDates: list>, InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string, MultipleFRSFacilities: record<RegistryIDs: list>, NAICS: record<Sources: list>, Notices: record<Notice: list, ProgramDates: list>, Permits: list<record>, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, Reports: record<HasPollRpt: string>, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>, SIC: record<Sources: list>, SanitarySurveys: record<Sources: list>, SiteVisits: record<Sources: list>, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>, SystemExtractDates: record<Dates: list>, TRIHistory: record<Sources: list>, TRIReleases: record<Chemicals: list, Header: list>, Tribes: list<record>, ViolationsEnforcementActions: record<Sources: list>, WaterQuality: record<Sources: list>, WaterQualityDetails: record<Sources: list>, WebFireDocuments: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_dfr")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report EJScreen Indexes Service
#
# GET /dfr_rest_services.get_ejscreen_indexes
export def "dfr-rest-servicesget-ejscreen-indexes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_ejscreen_indexes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report EJScreen Indexes Service
#
# POST /dfr_rest_services.get_ejscreen_indexes
export def "dfr-rest-servicesget-ejscreen-indexes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<EJScreenIndexes: record<HazardWasteProximity: string, LeadPaintIndicator: string, NATACancerRisk: string, NATADieselPM: string, NATARespiratoryHI: string, Over80Count: string, Ozone: string, PM25: string, RMPProximity: string, RegistryID: string, SuperfundProximity: string, TrafficProximity: string, WaterDischargeProximity: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_ejscreen_indexes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Enforcement Summary Service
#
# GET /dfr_rest_services.get_enforcement_summary
export def "dfr-rest-servicesget-enforcement-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_enforcement_summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Enforcement Summary Service
#
# POST /dfr_rest_services.get_enforcement_summary
export def "dfr-rest-servicesget-enforcement-summary post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<EnforcementComplianceSummaries: record<ProgramDates: list, Summaries: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_enforcement_summary")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays the dates that data was extracted from native EPA systems for the DFR.
#
# GET /dfr_rest_services.get_extract_dates
export def "dfr-rest-servicesget-extract-dates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, SystemExtractDates: record<Dates: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_extract_dates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays the dates that data was extracted from native EPA systems for the DFR.
#
# POST /dfr_rest_services.get_extract_dates
export def "dfr-rest-servicesget-extract-dates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, SystemExtractDates: record<Dates: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_extract_dates")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Formal Actions Service
#
# GET /dfr_rest_services.get_formal_actions
export def "dfr-rest-servicesget-formal-actions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<FormalActions: record<Action: list, ProgramDates: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_formal_actions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Formal Actions Service
#
# POST /dfr_rest_services.get_formal_actions
export def "dfr-rest-servicesget-formal-actions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<FormalActions: record<Action: list, ProgramDates: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_formal_actions")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report ICIS Formal Actions Service
#
# GET /dfr_rest_services.get_icis_formal_actions
export def "dfr-rest-servicesget-icis-formal-actions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<ICISFormalActions: record<Action: list, ProgramDates: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_icis_formal_actions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report ICIS Formal Actions Service
#
# POST /dfr_rest_services.get_icis_formal_actions
export def "dfr-rest-servicesget-icis-formal-actions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<ICISFormalActions: record<Action: list, ProgramDates: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_icis_formal_actions")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Inspections Summary Service
#
# GET /dfr_rest_services.get_inspections
export def "dfr-rest-servicesget-inspections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_inspections" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Inspections Summary Service
#
# POST /dfr_rest_services.get_inspections
export def "dfr-rest-servicesget-inspections post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<InspectionEnforcementSummary: record<ProgramDates: list, Source: list>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_inspections")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Map Service
#
# GET /dfr_rest_services.get_map
export def "dfr-rest-servicesget-map get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_map" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Map Service
#
# POST /dfr_rest_services.get_map
export def "dfr-rest-servicesget-map post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<MapOutput: record<CenterLatitude: string, CenterLongitude: string, IconBaseURL: string, MapData: list, PopUpBaseURL: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_map")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report NAICS Code Service
#
# GET /dfr_rest_services.get_naics
export def "dfr-rest-servicesget-naics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, NAICS: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_naics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report NAICS Code Service
#
# POST /dfr_rest_services.get_naics
export def "dfr-rest-servicesget-naics post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, NAICS: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_naics")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Notices Service
#
# GET /dfr_rest_services.get_notices
export def "dfr-rest-servicesget-notices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, Notices: record<Notice: list, ProgramDates: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_notices" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Notices Service
#
# POST /dfr_rest_services.get_notices
export def "dfr-rest-servicesget-notices post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, Notices: record<Notice: list, ProgramDates: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_notices")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Permits Service
#
# GET /dfr_rest_services.get_permits
export def "dfr-rest-servicesget-permits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, Permits: list<record>, Reports: record<HasPollRpt: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_permits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Permits Service
#
# POST /dfr_rest_services.get_permits
export def "dfr-rest-servicesget-permits post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, Permits: list<record>, Reports: record<HasPollRpt: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_permits")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report RCRA Compliance Service
#
# GET /dfr_rest_services.get_rcra_compliance
export def "dfr-rest-servicesget-rcra-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_rcra_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report RCRA Compliance Service
#
# POST /dfr_rest_services.get_rcra_compliance
export def "dfr-rest-servicesget-rcra-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, RCRACompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_rcra_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWA Lead and Copper Service
#
# GET /dfr_rest_services.get_sdwa_lead_and_copper
export def "dfr-rest-servicesget-sdwa-lead-and-copper get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_sdwa_lead_and_copper" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWA Lead and Copper Service
#
# POST /dfr_rest_services.get_sdwa_lead_and_copper
export def "dfr-rest-servicesget-sdwa-lead-and-copper post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<LeadAndCopperRule5Yr: record<CopperSamples: list, CuALE: string, CuALEUnits: string, CuALEValue: string, CuSampleDates: string, CuViol: string, LeadAndCopperViol: string, LeadCopperRuleHealthBasedViol: string, LeadSamples: list, PbALE: string, PbALEUnits: string, PbALEValue: string, PbSampleDates: string, PbViol: string, RuleCode350Viol: string, SourceID: string, iCU90: string, iPB90: string>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_sdwa_lead_and_copper")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWA Sanitary Surveys Service
#
# GET /dfr_rest_services.get_sdwa_sanitary_surveys
export def "dfr-rest-servicesget-sdwa-sanitary-surveys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, SanitarySurveys: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_sdwa_sanitary_surveys" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWA Sanitary Surveys Service
#
# POST /dfr_rest_services.get_sdwa_sanitary_surveys
export def "dfr-rest-servicesget-sdwa-sanitary-surveys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, SanitarySurveys: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_sdwa_sanitary_surveys")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWA Sanitary Site Visits Service
#
# GET /dfr_rest_services.get_sdwa_site_visits
export def "dfr-rest-servicesget-sdwa-site-visits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, SiteVisits: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_sdwa_site_visits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWA Sanitary Site Visits Service
#
# POST /dfr_rest_services.get_sdwa_site_visits
export def "dfr-rest-servicesget-sdwa-site-visits post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, SiteVisits: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_sdwa_site_visits")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWA Violations Service
#
# GET /dfr_rest_services.get_sdwa_violations
export def "dfr-rest-servicesget-sdwa-violations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, ViolationsEnforcementActions: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_sdwa_violations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWA Violations Service
#
# POST /dfr_rest_services.get_sdwa_violations
export def "dfr-rest-servicesget-sdwa-violations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, ViolationsEnforcementActions: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_sdwa_violations")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWIS Compliance Service
#
# GET /dfr_rest_services.get_sdwis_compliance
export def "dfr-rest-servicesget-sdwis-compliance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_sdwis_compliance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SDWIS Compliance Service
#
# POST /dfr_rest_services.get_sdwis_compliance
export def "dfr-rest-servicesget-sdwis-compliance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, SDWISCompliance: record<Mnth10End: string, Mnth10Start: string, Mnth11End: string, Mnth11Start: string, Mnth12End: string, Mnth12Start: string, Mnth13End: string, Mnth13Start: string, Mnth14End: string, Mnth14Start: string, Mnth15End: string, Mnth15Start: string, Mnth16End: string, Mnth16Start: string, Mnth17End: string, Mnth17Start: string, Mnth18End: string, Mnth18Start: string, Mnth19End: string, Mnth19Start: string, Mnth1End: string, Mnth1Start: string, Mnth20End: string, Mnth20Start: string, Mnth21End: string, Mnth21Start: string, Mnth22End: string, Mnth22Start: string, Mnth23End: string, Mnth23Start: string, Mnth24End: string, Mnth24Start: string, Mnth25End: string, Mnth25Start: string, Mnth26End: string, Mnth26Start: string, Mnth27End: string, Mnth27Start: string, Mnth28End: string, Mnth28Start: string, Mnth29End: string, Mnth29Start: string, Mnth2End: string, Mnth2Start: string, Mnth30End: string, Mnth30Start: string, Mnth31End: string, Mnth31Start: string, Mnth32End: string, Mnth32Start: string, Mnth33End: string, Mnth33Start: string, Mnth34End: string, Mnth34Start: string, Mnth35End: string, Mnth35Start: string, Mnth36End: string, Mnth36Start: string, Mnth37End: string, Mnth37Start: string, Mnth38End: string, Mnth38Start: string, Mnth39End: string, Mnth39Start: string, Mnth3End: string, Mnth3Start: string, Mnth4End: string, Mnth4Start: string, Mnth5End: string, Mnth5Start: string, Mnth6End: string, Mnth6Start: string, Mnth7End: string, Mnth7Start: string, Mnth8End: string, Mnth8Start: string, Mnth9End: string, Mnth9Start: string, Qtr10End: string, Qtr10Start: string, Qtr11End: string, Qtr11Start: string, Qtr12End: string, Qtr12Start: string, Qtr13End: string, Qtr13Start: string, Qtr1End: string, Qtr1Start: string, Qtr2End: string, Qtr2Start: string, Qtr3End: string, Qtr3Start: string, Qtr4End: string, Qtr4Start: string, Qtr5End: string, Qtr5Start: string, Qtr6End: string, Qtr6Start: string, Qtr7End: string, Qtr7Start: string, Qtr8End: string, Qtr8Start: string, Qtr9End: string, Qtr9Start: string, Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_sdwis_compliance")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SIC Code Service
#
# GET /dfr_rest_services.get_sic_codes
export def "dfr-rest-servicesget-sic-codes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, SIC: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_sic_codes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report SIC Code Service
#
# POST /dfr_rest_services.get_sic_codes
export def "dfr-rest-servicesget-sic-codes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, SIC: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_sic_codes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Spatial Metadata Service
#
# GET /dfr_rest_services.get_spatial_metadata
export def "dfr-rest-servicesget-spatial-metadata get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_spatial_metadata" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Spatial Metadata Service
#
# POST /dfr_rest_services.get_spatial_metadata
export def "dfr-rest-servicesget-spatial-metadata post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, SpatialMetadata: record<CalculatedAccuracy: string, CollectionMethod: string, CoordinateSourceSystem: string, CoordinateSourceSystemId: string, Latitude83: string, Longitude83: string, ReferencePoint: string, RegistryID: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_spatial_metadata")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report TRI History Service
#
# GET /dfr_rest_services.get_tri_history
export def "dfr-rest-servicesget-tri-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, TRIHistory: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_tri_history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report TRI History Service
#
# POST /dfr_rest_services.get_tri_history
export def "dfr-rest-servicesget-tri-history post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, TRIHistory: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_tri_history")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report TRI Releases Service
#
# GET /dfr_rest_services.get_tri_releases
export def "dfr-rest-servicesget-tri-releases get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, TRIReleases: record<Chemicals: list, Header: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_tri_releases" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report TRI Releases Service
#
# POST /dfr_rest_services.get_tri_releases
export def "dfr-rest-servicesget-tri-releases post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, TRIReleases: record<Chemicals: list, Header: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_tri_releases")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Tribes Service
#
# GET /dfr_rest_services.get_tribes
export def "dfr-rest-servicesget-tribes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, Tribes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_tribes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Tribes Service
#
# POST /dfr_rest_services.get_tribes
export def "dfr-rest-servicesget-tribes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, Tribes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_tribes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Water Quality Service
#
# GET /dfr_rest_services.get_water_quality
export def "dfr-rest-servicesget-water-quality get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, WaterQuality: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_water_quality" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detailed Facility Report Water Quality Service
#
# POST /dfr_rest_services.get_water_quality
export def "dfr-rest-servicesget-water-quality post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, WaterQuality: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_water_quality")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays detailed Water Quality information from EPA's Office of Water Systems
#
# GET /dfr_rest_services.get_water_quality_details
export def "dfr-rest-servicesget-water-quality-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --p-id: string # Either the EPA Facility Registry System's REGISTRY_ID for a facility or the facility identifier from the following EPA Systems: RCRAINFO (HANDLER_ID), AFS (SCSC), ICIS NPDES (NPDES_ID), or SDWIS (PWS_ID).
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, WaterQualityDetails: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_id" $p_id "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dfr_rest_services.get_water_quality_details" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Displays detailed Water Quality information from EPA's Office of Water Systems
#
# POST /dfr_rest_services.get_water_quality_details
export def "dfr-rest-servicesget-water-quality-details post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Results: record<Message: string, WaterQualityDetails: record<Sources: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.get_water_quality_details")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the complete RCRA Compliance History Section of the DFR
#
# GET /dfr_rest_services.rcra_3_yr_download
export def "dfr-rest-servicesrcra-3-yr-download get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.rcra_3_yr_download")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the complete RCRA Compliance History Section of the DFR
#
# POST /dfr_rest_services.rcra_3_yr_download
export def "dfr-rest-servicesrcra-3-yr-download post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dfr_rest_services.rcra_3_yr_download")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
