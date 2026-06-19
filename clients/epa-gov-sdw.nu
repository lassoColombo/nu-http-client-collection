# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Safe Drinking Water Act v2019.10.15
# Source: https://api.apis.guru/v2/specs/epa.gov/sdw/2019.10.15/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____SAFE_DRINKING_WATER_ACT_TOKEN

const BASE_URL = "https://echodata.epa.gov/echo"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____SAFE_DRINKING_WATER_ACT_TOKEN | default "" }
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
def descending-completer [] { ["N" "Y"] }
def p-reg-completer [] { ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10"] }
def p-act-completer [] { ["A" "N" "Y"] }
def p-qiv-completer [] { ["0" "12" "GT1" "GT2" "GT4" "GT8"] }
def p-ico-completer [] { ["N" "Y"] }
def p-owop-completer [] { ["F" "L" "M" "N" "P" "S"] }
def p-systyp-completer [] { ["CWS" "NCWS" "NTCWS" "TNCWS"] }
def p-swtyp-completer [] { ["GU" "GUP" "GW" "GWP" "SW" "SWP"] }
def p-mr-completer [] { ["N" "Y"] }
def p-health-completer [] { ["N" "Y"] }
def p-other-completer [] { ["N" "Y"] }
def p-pn-completer [] { ["N" "Y"] }
def p-sv-completer [] { ["N" "Y"] }
def p-pswvio-completer [] { ["N" "Y"] }
def p-fea-completer [] { ["N" "W"] }
def p-feay-completer [] { ["1" "2" "3" "4" "5"] }
def p-feaa-completer [] { ["A" "E" "S"] }
def p-iea-completer [] { ["N" "W"] }
def p-ieay-completer [] { ["1" "2" "3" "4" "5"] }
def p-ieaa-completer [] { ["E" "S"] }
def p-qis-completer [] { ["12" "GE1" "GE12" "GE2" "GE4" "GE8" "GT1" "GT12" "GT2" "GT4" "GT8" "Z"] }
def p-ysl-completer [] { ["N" "NV" "W"] }
def p-ysly-completer [] { ["1" "2" "3" "4" "5"] }
def p-ysla-completer [] { ["A" "E" "S"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sdw-rest-services-get-download get" } } | get name | first)
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

# Safe Drinking Water Act (SDWA) Download Data Service
#
# GET /sdw_rest_services.get_download
export def "sdw-rest-services-get-download get" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default).
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "qcolumns" $qcolumns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sdw_rest_services.get_download" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "qid": $qid, "qcolumns": $qcolumns} | compact), body: null}
}

# Safe Drinking Water Act (SDWA) Download Data Service
#
# POST /sdw_rest_services.get_download
export def "sdw-rest-services-get-download create" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default).
  qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sdw_rest_services.get_download")
  let req_body = {"output": $output, "qid": $qid, "qcolumns": $qcolumns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Safe Drinking Water Act (SDWA) Paginated Results Service
#
# GET /sdw_rest_services.get_qid
export def "sdw-rest-services-get-qid get" [
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
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --pageno: float # Indicates the number of the page to display. It is used only when the results are paginated. (default: 1)
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column. Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag. Enter Y to column identified in the newsort parameter descending. Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> record<Results: record<Message: string, PageNo: string, QueryID: string, QueryRows: string, WaterSystems: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "pageno" $pageno "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "newsort" $newsort "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "qcolumns" $qcolumns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sdw_rest_services.get_qid" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "qid": $qid, "pageno": $pageno, "callback": $callback, "newsort": $newsort, "descending": $descending, "qcolumns": $qcolumns} | compact), body: null}
}

# Safe Drinking Water Act (SDWA) Paginated Results Service
#
# POST /sdw_rest_services.get_qid
export def "sdw-rest-services-get-qid create" [
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
  qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --pageno: float # Indicates the number of the page to display. It is used only when the results are paginated.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column. Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag. Enter Y to column identified in the newsort parameter descending. Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: any -> record<Results: record<Message: string, PageNo: string, QueryID: string, QueryRows: string, WaterSystems: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sdw_rest_services.get_qid")
  let req_body = {"output": $output, "qid": $qid, "pageno": $pageno, "callback": $callback, "newsort": $newsort, "descending": $descending, "qcolumns": $qcolumns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Safe Drinking Water Act (SDWA) Systems Search Service
#
# GET /sdw_rest_services.get_systems
export def "sdw-rest-services-get-systems get" [
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
  --p-fn: string # Facility Name Filter. Enter one or more case-insensitive facility names to filter results. Provide multiple values as a comma-delimited list. See p_fntype for additional modifiers.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-trb: string # Tribe name
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following codes to filter results: - F = Federal Government - S = State Government - L = Local Government - M = Public/Private - N = Native American - P = Private
  --p-systyp: string@p-systyp-completer # Type of public water system: - CWS=Community water system - NCWS=Non-community water system - NTCWS=Non-transient non-community water system - TNCWS=Transient non-community water system
  --p-swtyp: string@p-swtyp-completer # Source Water Type: - SW = Surface water - GW= Ground water - GU = Ground water under direct influence of (UDI) surface water - SWP = Purchased Surface water - GWP = Purchased Ground water - GUP = Purchased Ground water UDI surface water
  --p-popsv: string # Estimated average daily population served by a system: - LE500 = 500 or less - IN501_3K = 501-3,300 - IN3K_10K = 3,301-10,000 - IN10K_100K = 10,001-100,000 - IN100K_1M = 100,001-1,000,000 - GT1M = More than 1,000,000 May contain multiple comma-separated values.
  --p-cntysv: string
  --p-cs: string # Current violations: - M = Monitoring and Reporting Violations - H = Health-based Violations - O = Other Violations - P = Public Notice Violations - S = Serious Violator - N = No Violations May contain multiple comma-separated values.
  --p-mr: string@p-mr-completer # Monitoring and Reporting Violations (failure to conduct regular monitoring of drinking water quality or submit monitoring results in a timely fashion).
  --p-health: string@p-health-completer # Violations of health-based drinking water standards (maximum contaminant levels, maximum residual disinfectant levels, or treatment technique rules).
  --p-other: string@p-other-completer # Other violations, such as failing to issue annual consumer confidence reports or maintain required records.
  --p-pn: string@p-pn-completer # Public Notice Violations (failure to immediately alert consumers of serious problem with drinking water).
  --p-sv: string@p-sv-completer # Serious Violator (unresolved serious, multiple, and/or continuing violations). A value of Y will return only SDWIS systems that are Serious Violators, while a value of N will only return SDWIS Systems that are not Serious Violators.
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-pbale: string # Lead Action Level Exceedance. A "Y" value will select water systems with at least 1 Lead Action Level Exceedance.
  --p-cuale: string # Copper Action Level Exceedance. A "Y" value will select water systems with at least 1 Copper Action Level Exceedance.
  --p-rc350v: string # Rule code 350 violation. A "Y" value will select water systems with at least one rule code 350 violation.
  --p-pbv: string # Lead Violations. A "Y" value will select water systems with at least 1 Lead Violation.
  --p-cuv: string # Copper Violation. A "Y" value will select water systems with at least 1 Copper Violation.
  --p-lcrv: string # Lead or Copper rule violations. A "Y" value will select water systems with at least 1 Lead or Copper Rule Violation.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qis: string@p-qis-completer # Significant Quarters in Noncompliance Limiter. Enter one of the following codes to limit results to facilities having given quarters of noncompliance. - Z = Zero quarters in noncompliance. - GE1 = One or more quarters in noncompliance. - GT1 = More than one quarters in noncompliance. - GE2 = Two or more quarters in noncompliance. - GT2 = More than two quarters in noncompliance. - GE4 = Four or more quarters in noncompliance. - GT4 = More than four quarters in noncompliance. - GE8 = Eight or more quarters in noncompliance. - GT8 = More than eight quarters in noncompliance. - GE12 = Twelve or more quarters in noncompliance. - GT12 = Twelve or more quarters in noncompliance. - 12 = Exactly twelve quarters in noncompliance. Note the seemingly incongruous of GT12 is deliberate.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-ss5yr: string # Sanitary Surveys (in past 5 years) flag. Values of visit_reason_code are either "SNSV" or "SNSP" in the past 5 years indicate a Sanitary Survey. Enter "Y" to select facilities with Sanitary Surveys within the past 5 years. Enter "N" to select facilities without Sanitary Surveys in the past 5 years. Enter a number to search for greater for facilities with a quantity than or equal to that value.
  --p-sdc: string # Significant Deficiency Count (in past 5 years) flag. Enter "Y" to select facilities with Sanitary Surveys within the past 5 years. Enter "N" to select facilities without Sanitary Surveys in the past 5 years. Enter a number to search for facilities with a quantity greater than or equal to that value.
  --p-sdc-ils: string
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: string@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-cms-flag: string
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, INSPRows: string, IndianCountryRows: string, InfFEARows: string, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, V3Rows: string, Version: string, WaterSystems: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_fn" $p_fn "scalar") (serialize-qp "p_ct" $p_ct "scalar") (serialize-qp "p_co" $p_co "scalar") (serialize-qp "p_fips" $p_fips "scalar") (serialize-qp "p_st" $p_st "scalar") (serialize-qp "p_zip" $p_zip "scalar") (serialize-qp "p_reg" $p_reg "scalar") (serialize-qp "p_trb" $p_trb "scalar") (serialize-qp "p_act" $p_act "scalar") (serialize-qp "p_qiv" $p_qiv "scalar") (serialize-qp "p_ico" $p_ico "scalar") (serialize-qp "p_pid" $p_pid "scalar") (serialize-qp "p_owop" $p_owop "scalar") (serialize-qp "p_systyp" $p_systyp "scalar") (serialize-qp "p_swtyp" $p_swtyp "scalar") (serialize-qp "p_popsv" $p_popsv "scalar") (serialize-qp "p_cntysv" $p_cntysv "scalar") (serialize-qp "p_cs" $p_cs "scalar") (serialize-qp "p_mr" $p_mr "scalar") (serialize-qp "p_health" $p_health "scalar") (serialize-qp "p_other" $p_other "scalar") (serialize-qp "p_pn" $p_pn "scalar") (serialize-qp "p_sv" $p_sv "scalar") (serialize-qp "p_qs" $p_qs "scalar") (serialize-qp "p_sfs" $p_sfs "scalar") (serialize-qp "p_pswpol" $p_pswpol "scalar") (serialize-qp "p_pswvio" $p_pswvio "scalar") (serialize-qp "p_pbale" $p_pbale "scalar") (serialize-qp "p_cuale" $p_cuale "scalar") (serialize-qp "p_rc350v" $p_rc350v "scalar") (serialize-qp "p_pbv" $p_pbv "scalar") (serialize-qp "p_cuv" $p_cuv "scalar") (serialize-qp "p_lcrv" $p_lcrv "scalar") (serialize-qp "p_fea" $p_fea "scalar") (serialize-qp "p_feay" $p_feay "scalar") (serialize-qp "p_feaa" $p_feaa "scalar") (serialize-qp "p_iea" $p_iea "scalar") (serialize-qp "p_ieay" $p_ieay "scalar") (serialize-qp "p_ieaa" $p_ieaa "scalar") (serialize-qp "p_qis" $p_qis "scalar") (serialize-qp "p_pfead1" $p_pfead1 "scalar") (serialize-qp "p_pfead2" $p_pfead2 "scalar") (serialize-qp "p_pfeat" $p_pfeat "scalar") (serialize-qp "p_ss5yr" $p_ss5yr "scalar") (serialize-qp "p_sdc" $p_sdc "scalar") (serialize-qp "p_sdc_ils" $p_sdc_ils "scalar") (serialize-qp "p_ysl" $p_ysl "scalar") (serialize-qp "p_ysly" $p_ysly "scalar") (serialize-qp "p_ysla" $p_ysla "scalar") (serialize-qp "p_idt1" $p_idt1 "scalar") (serialize-qp "p_idt2" $p_idt2 "scalar") (serialize-qp "p_cms_flag" $p_cms_flag "scalar") (serialize-qp "queryset" $queryset "scalar") (serialize-qp "responseset" $responseset "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "qcolumns" $qcolumns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sdw_rest_services.get_systems" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "p_fn": $p_fn, "p_ct": $p_ct, "p_co": $p_co, "p_fips": $p_fips, "p_st": $p_st, "p_zip": $p_zip, "p_reg": $p_reg, "p_trb": $p_trb, "p_act": $p_act, "p_qiv": $p_qiv, "p_ico": $p_ico, "p_pid": $p_pid, "p_owop": $p_owop, "p_systyp": $p_systyp, "p_swtyp": $p_swtyp, "p_popsv": $p_popsv, "p_cntysv": $p_cntysv, "p_cs": $p_cs, "p_mr": $p_mr, "p_health": $p_health, "p_other": $p_other, "p_pn": $p_pn, "p_sv": $p_sv, "p_qs": $p_qs, "p_sfs": $p_sfs, "p_pswpol": $p_pswpol, "p_pswvio": $p_pswvio, "p_pbale": $p_pbale, "p_cuale": $p_cuale, "p_rc350v": $p_rc350v, "p_pbv": $p_pbv, "p_cuv": $p_cuv, "p_lcrv": $p_lcrv, "p_fea": $p_fea, "p_feay": $p_feay, "p_feaa": $p_feaa, "p_iea": $p_iea, "p_ieay": $p_ieay, "p_ieaa": $p_ieaa, "p_qis": $p_qis, "p_pfead1": $p_pfead1, "p_pfead2": $p_pfead2, "p_pfeat": $p_pfeat, "p_ss5yr": $p_ss5yr, "p_sdc": $p_sdc, "p_sdc_ils": $p_sdc_ils, "p_ysl": $p_ysl, "p_ysly": $p_ysly, "p_ysla": $p_ysla, "p_idt1": $p_idt1, "p_idt2": $p_idt2, "p_cms_flag": $p_cms_flag, "queryset": $queryset, "responseset": $responseset, "callback": $callback, "qcolumns": $qcolumns} | compact), body: null}
}

# Safe Drinking Water Act (SDWA) Systems Search Service
#
# POST /sdw_rest_services.get_systems
export def "sdw-rest-services-get-systems create" [
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
  --p-fn: string # Facility Name Filter. Enter one or more case-insensitive facility names to filter results. Provide multiple values as a comma-delimited list. See p_fntype for additional modifiers.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-trb: string # Tribe name
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following codes to filter results: - F = Federal Government - S = State Government - L = Local Government - M = Public/Private - N = Native American - P = Private
  --p-systyp: string@p-systyp-completer # Type of public water system: - CWS=Community water system - NCWS=Non-community water system - NTCWS=Non-transient non-community water system - TNCWS=Transient non-community water system
  --p-swtyp: string@p-swtyp-completer # Source Water Type: - SW = Surface water - GW= Ground water - GU = Ground water under direct influence of (UDI) surface water - SWP = Purchased Surface water - GWP = Purchased Ground water - GUP = Purchased Ground water UDI surface water
  --p-popsv: string # Estimated average daily population served by a system: - LE500 = 500 or less - IN501_3K = 501-3,300 - IN3K_10K = 3,301-10,000 - IN10K_100K = 10,001-100,000 - IN100K_1M = 100,001-1,000,000 - GT1M = More than 1,000,000 May contain multiple comma-separated values.
  --p-cntysv: string
  --p-cs: string # Current violations: - M = Monitoring and Reporting Violations - H = Health-based Violations - O = Other Violations - P = Public Notice Violations - S = Serious Violator - N = No Violations May contain multiple comma-separated values.
  --p-mr: string@p-mr-completer # Monitoring and Reporting Violations (failure to conduct regular monitoring of drinking water quality or submit monitoring results in a timely fashion).
  --p-health: string@p-health-completer # Violations of health-based drinking water standards (maximum contaminant levels, maximum residual disinfectant levels, or treatment technique rules).
  --p-other: string@p-other-completer # Other violations, such as failing to issue annual consumer confidence reports or maintain required records.
  --p-pn: string@p-pn-completer # Public Notice Violations (failure to immediately alert consumers of serious problem with drinking water).
  --p-sv: string@p-sv-completer # Serious Violator (unresolved serious, multiple, and/or continuing violations). A value of Y will return only SDWIS systems that are Serious Violators, while a value of N will only return SDWIS Systems that are not Serious Violators.
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-pbale: string # Lead Action Level Exceedance. A "Y" value will select water systems with at least 1 Lead Action Level Exceedance.
  --p-cuale: string # Copper Action Level Exceedance. A "Y" value will select water systems with at least 1 Copper Action Level Exceedance.
  --p-rc350v: string # Rule code 350 violation. A "Y" value will select water systems with at least one rule code 350 violation.
  --p-pbv: string # Lead Violations. A "Y" value will select water systems with at least 1 Lead Violation.
  --p-cuv: string # Copper Violation. A "Y" value will select water systems with at least 1 Copper Violation.
  --p-lcrv: string # Lead or Copper rule violations. A "Y" value will select water systems with at least 1 Lead or Copper Rule Violation.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qis: string@p-qis-completer # Significant Quarters in Noncompliance Limiter. Enter one of the following codes to limit results to facilities having given quarters of noncompliance. - Z = Zero quarters in noncompliance. - GE1 = One or more quarters in noncompliance. - GT1 = More than one quarters in noncompliance. - GE2 = Two or more quarters in noncompliance. - GT2 = More than two quarters in noncompliance. - GE4 = Four or more quarters in noncompliance. - GT4 = More than four quarters in noncompliance. - GE8 = Eight or more quarters in noncompliance. - GT8 = More than eight quarters in noncompliance. - GE12 = Twelve or more quarters in noncompliance. - GT12 = Twelve or more quarters in noncompliance. - 12 = Exactly twelve quarters in noncompliance. Note the seemingly incongruous of GT12 is deliberate.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-ss5yr: string # Sanitary Surveys (in past 5 years) flag. Values of visit_reason_code are either "SNSV" or "SNSP" in the past 5 years indicate a Sanitary Survey. Enter "Y" to select facilities with Sanitary Surveys within the past 5 years. Enter "N" to select facilities without Sanitary Surveys in the past 5 years. Enter a number to search for greater for facilities with a quantity than or equal to that value.
  --p-sdc: string # Significant Deficiency Count (in past 5 years) flag. Enter "Y" to select facilities with Sanitary Surveys within the past 5 years. Enter "N" to select facilities without Sanitary Surveys in the past 5 years. Enter a number to search for facilities with a quantity greater than or equal to that value.
  --p-sdc-ils: string
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: string@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-cms-flag: string
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: any -> record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, INSPRows: string, IndianCountryRows: string, InfFEARows: string, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, V3Rows: string, Version: string, WaterSystems: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sdw_rest_services.get_systems")
  let req_body = {"output": $output, "p_fn": $p_fn, "p_ct": $p_ct, "p_co": $p_co, "p_fips": $p_fips, "p_st": $p_st, "p_zip": $p_zip, "p_reg": $p_reg, "p_trb": $p_trb, "p_act": $p_act, "p_qiv": $p_qiv, "p_ico": $p_ico, "p_pid": $p_pid, "p_owop": $p_owop, "p_systyp": $p_systyp, "p_swtyp": $p_swtyp, "p_popsv": $p_popsv, "p_cntysv": $p_cntysv, "p_cs": $p_cs, "p_mr": $p_mr, "p_health": $p_health, "p_other": $p_other, "p_pn": $p_pn, "p_sv": $p_sv, "p_qs": $p_qs, "p_sfs": $p_sfs, "p_pswpol": $p_pswpol, "p_pswvio": $p_pswvio, "p_pbale": $p_pbale, "p_cuale": $p_cuale, "p_rc350v": $p_rc350v, "p_pbv": $p_pbv, "p_cuv": $p_cuv, "p_lcrv": $p_lcrv, "p_fea": $p_fea, "p_feay": $p_feay, "p_feaa": $p_feaa, "p_iea": $p_iea, "p_ieay": $p_ieay, "p_ieaa": $p_ieaa, "p_qis": $p_qis, "p_pfead1": $p_pfead1, "p_pfead2": $p_pfead2, "p_pfeat": $p_pfeat, "p_ss5yr": $p_ss5yr, "p_sdc": $p_sdc, "p_sdc_ils": $p_sdc_ils, "p_ysl": $p_ysl, "p_ysly": $p_ysly, "p_ysla": $p_ysla, "p_idt1": $p_idt1, "p_idt2": $p_idt2, "p_cms_flag": $p_cms_flag, "queryset": $queryset, "responseset": $responseset, "callback": $callback, "qcolumns": $qcolumns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Safe Drinking Water Act (SDWA) Metadata Service
#
# GET /sdw_rest_services.metadata
export def "sdw-rest-services-metadata get" [
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
]: nothing -> record<Results: record<Message: string, ResultColumns: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sdw_rest_services.metadata" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback} | compact), body: null}
}

# Safe Drinking Water Act (SDWA) Metadata Service
#
# POST /sdw_rest_services.metadata
export def "sdw-rest-services-metadata create" [
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
]: any -> record<Results: record<Message: string, ResultColumns: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sdw_rest_services.metadata")
  let req_body = {"output": $output, "callback": $callback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
