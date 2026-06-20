# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Effluent Charting and Reporting v2019.10.15
# Source: https://api.apis.guru/v2/specs/epa.gov/eff/2019.10.15/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_EFFLUENT_CHARTING_AND_REPORTING_TOKEN

const BASE_URL = "https://echodata.epa.gov/echo"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE_ECHO_EFFLUENT_CHARTING_AND_REPORTING_TOKEN | default "" }
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

def base-url-completer [] { ["https://echodata.epa.gov/echo"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def output-completer [] { ["JSON" "JSONP" "XML"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "eff-rest-services-download-effluent-chart get" } } | get name | first)
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

# Effluent Charts Download Service
#
# GET /eff_rest_services.download_effluent_chart
export def "eff-rest-services-download-effluent-chart get" [
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
  --p-id: string # Identifier for the service.
  --outfall: string # Three-character code that identifies the point of discharge (e.g., pipe or outfall) for a facility. A single NPDES ID may have multiple points of discharge.
  --parameter-code: string # Five-digit numeric code identifying the parameter. See Parameter Lookup documentation for a complete list of codes.
  --start-date: string # The start date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with end_date. If start_date and end_date are not specified, the service will return the last three years of data.
  --end-date: string # The end date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with start_date. If start_date and end_date are not specified, the service will return the last three years of data.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "outfall" $outfall "scalar") (serialize-qp "parameter_code" $parameter_code "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eff_rest_services.download_effluent_chart" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"p_id": $p_id, "outfall": $outfall, "parameter_code": $parameter_code, "start_date": $start_date, "end_date": $end_date} | compact), body: null}
}

# Effluent Charts Download Service
#
# POST /eff_rest_services.download_effluent_chart
export def "eff-rest-services-download-effluent-chart create" [
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
  p_id: string # Identifier for the service.
  --outfall: string # Three-character code that identifies the point of discharge (e.g., pipe or outfall) for a facility. A single NPDES ID may have multiple points of discharge.
  --parameter-code: string # Five-digit numeric code identifying the parameter. See Parameter Lookup documentation for a complete list of codes.
  --start-date: string # The start date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with end_date. If start_date and end_date are not specified, the service will return the last three years of data.
  --end-date: string # The end date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with start_date. If start_date and end_date are not specified, the service will return the last three years of data.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eff_rest_services.download_effluent_chart")
  let req_body = {"p_id": $p_id, "outfall": $outfall, "parameter_code": $parameter_code, "start_date": $start_date, "end_date": $end_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Detailed Effluent Chart Service
#
# GET /eff_rest_services.get_effluent_chart
export def "eff-rest-services-get-effluent-chart get" [
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
  --p-id: string # Identifier for the service.
  --outfall: string # Three-character code that identifies the point of discharge (e.g., pipe or outfall) for a facility. A single NPDES ID may have multiple points of discharge.
  --parameter-code: string # Five-digit numeric code identifying the parameter. See Parameter Lookup documentation for a complete list of codes.
  --start-date: string # The start date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with end_date. If start_date and end_date are not specified, the service will return the last three years of data.
  --end-date: string # The end date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with start_date. If start_date and end_date are not specified, the service will return the last three years of data.
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CWPCity: string, CWPCurrentSNCStatus: string, CWPMajorMinorStatusFlag: string, CWPName: string, CWPPermitStatusDesc: string, CWPPermitTypeDesc: string, CWPState: string, CWPStreet: string, CWPZip: string, EPASystem: string, EndDate: string, Message: string, PermFeatures: list<record>, RegistryId: string, SourceId: string, StartDate: string, Statute: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "outfall" $outfall "scalar") (serialize-qp "parameter_code" $parameter_code "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eff_rest_services.get_effluent_chart" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"p_id": $p_id, "outfall": $outfall, "parameter_code": $parameter_code, "start_date": $start_date, "end_date": $end_date, "output": $output, "callback": $callback} | compact), body: null}
}

# Detailed Effluent Chart Service
#
# POST /eff_rest_services.get_effluent_chart
export def "eff-rest-services-get-effluent-chart create" [
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
  p_id: string # Identifier for the service.
  --outfall: string # Three-character code that identifies the point of discharge (e.g., pipe or outfall) for a facility. A single NPDES ID may have multiple points of discharge.
  --parameter-code: string # Five-digit numeric code identifying the parameter. See Parameter Lookup documentation for a complete list of codes.
  --start-date: string # The start date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with end_date. If start_date and end_date are not specified, the service will return the last three years of data.
  --end-date: string # The end date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with start_date. If start_date and end_date are not specified, the service will return the last three years of data.
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
]: any -> record<Results: record<CWPCity: string, CWPCurrentSNCStatus: string, CWPMajorMinorStatusFlag: string, CWPName: string, CWPPermitStatusDesc: string, CWPPermitTypeDesc: string, CWPState: string, CWPStreet: string, CWPZip: string, EPASystem: string, EndDate: string, Message: string, PermFeatures: list<record>, RegistryId: string, SourceId: string, StartDate: string, Statute: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eff_rest_services.get_effluent_chart")
  let req_body = {"p_id": $p_id, "outfall": $outfall, "parameter_code": $parameter_code, "start_date": $start_date, "end_date": $end_date, "output": $output, "callback": $callback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Summary Effluent Chart Service
#
# GET /eff_rest_services.get_summary_chart
export def "eff-rest-services-get-summary-chart get" [
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
  --p-id: string # Identifier for the service.
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --start-date: string # The start date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with end_date. If start_date and end_date are not specified, the service will return the last three years of data.
  --end-date: string # The end date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with start_date. If start_date and end_date are not specified, the service will return the last three years of data.
]: nothing -> record<Results: record<CWPCity: string, CWPCurrentSNCStatus: string, CWPMajorMinorStatusFlag: string, CWPName: string, CWPPermitStatusDesc: string, CWPPermitTypeDesc: string, CWPState: string, CWPStreet: string, CWPZip: string, EPASystem: string, EndDate: string, LinkedPermits: list<record>, Message: string, PermFeatures: list<record>, RegistryId: string, SourceId: string, StartDate: string, Statute: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eff_rest_services.get_summary_chart" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"p_id": $p_id, "output": $output, "callback": $callback, "start_date": $start_date, "end_date": $end_date} | compact), body: null}
}

# Summary Effluent Chart Service
#
# POST /eff_rest_services.get_summary_chart
export def "eff-rest-services-get-summary-chart create" [
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
  p_id: string # Identifier for the service.
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --start-date: string # The start date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with end_date. If start_date and end_date are not specified, the service will return the last three years of data.
  --end-date: string # The end date (mm/dd/yyyy) for the date range of interest. Must be used in conjunction with start_date. If start_date and end_date are not specified, the service will return the last three years of data.
]: any -> record<Results: record<CWPCity: string, CWPCurrentSNCStatus: string, CWPMajorMinorStatusFlag: string, CWPName: string, CWPPermitStatusDesc: string, CWPPermitTypeDesc: string, CWPState: string, CWPStreet: string, CWPZip: string, EPASystem: string, EndDate: string, LinkedPermits: list<record>, Message: string, PermFeatures: list<record>, RegistryId: string, SourceId: string, StartDate: string, Statute: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/eff_rest_services.get_summary_chart")
  let req_body = {"p_id": $p_id, "output": $output, "callback": $callback, "start_date": $start_date, "end_date": $end_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO CWA Parameter Lookup Service
#
# GET /rest_lookups.cwa_parameters
export def "rest-lookups-cwa-parameters get" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: nothing -> record<Results: record<LuValues: list<record>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "search_term" $search_term "scalar") (serialize-qp "search_code" $search_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest_lookups.cwa_parameters" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact), body: null}
}

# ECHO CWA Parameter Lookup Service
#
# POST /rest_lookups.cwa_parameters
export def "rest-lookups-cwa-parameters create" [
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
  --output: string@output-completer # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
]: any -> record<Results: record<LuValues: list<record>, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest_lookups.cwa_parameters")
  let req_body = {"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
