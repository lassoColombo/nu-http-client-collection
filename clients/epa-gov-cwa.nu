# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Clean Water Act (CWA) Rest Services v2019.10.15
# Source: https://api.apis.guru/v2/specs/epa.gov/cwa/2019.10.15/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____CLEAN_WATER_ACT__CWA__REST_SERVICES_TOKEN

const BASE_URL = "https://echodata.epa.gov/echo"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____CLEAN_WATER_ACT__CWA__REST_SERVICES_TOKEN | default "" }
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
def p-reg-completer [] { ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10"] }
def p-usmex-completer [] { ["N" "Y"] }
def p-ff-completer [] { ["Y"] }
def p-maj-completer [] { ["N" "Y"] }
def p-fea-completer [] { ["N" "W"] }
def p-feay-completer [] { ["1" "2" "3" "4" "5"] }
def p-feaa-completer [] { ["A" "E" "S"] }
def p-iea-completer [] { ["N" "W"] }
def p-ieay-completer [] { ["1" "2" "3" "4" "5"] }
def p-ieaa-completer [] { ["E" "S"] }
def p-qiv-completer [] { ["0" "12" "GT1" "GT2" "GT4" "GT8"] }
def p-impw-completer [] { ["N" "Y"] }
def p-imp-cau-grp-completer [] { ["ALGAL GROWTH" "AMMONIA" "BIOTOXINS" "CAUSE UNKNOWN" "CAUSE UNKNOWN - FISH KILLS" "CAUSE UNKNOWN - IMPAIRED BIOTA" "CHLORINE" "DIOXINS" "FISH CONSUMPTION ADVISORY" "FLOW ALTERATION(S)" "HABITAT ALTERATIONS" "MERCURY" "METALS (OTHER THAN MERCURY)" "NOXIOUS AQUATIC PLANTS" "NUISANCE EXOTIC SPECIES" "NUISANCE NATIVE SPECIES" "NUTRIENTS" "OIL AND GREASE" "ORGANIC ENRICHMENT/OXYGEN DEPLETION" "OTHER CAUSE" "PATHOGENS" "PESTICIDES" "PH/ACIDITY/CAUSTIC CONDITIONS" "POLYCHLORINATED BIPHENYLS (PCBS)" "RADIATION" "SALINITY/TOTAL DISSOLVED SOLIDS/CHLORIDES/SULFATES" "SEDIMENT" "TASTE, COLOR AND ODOR" "TEMPERATURE" "TOTAL TOXICS" "TOXIC INORGANICS" "TOXIC ORGANICS" "TRASH" "TURBIDITY"] }
def p-imp-pol-completer [] { ["N" "Y"] }
def p-trep-completer [] { ["CURR" "NOTCURR"] }
def p-pm-completer [] { ["GT10" "GT25" "GT5" "GT50" "GT75" "NONE"] }
def p-pd-completer [] { ["GT100" "GT1000" "GT10000" "GT20000" "GT500" "GT5000" "NONE"] }
def p-ico-completer [] { ["N" "Y"] }
def p-med-completer [] { ["A" "ALL" "M" "R" "S"] }
def p-ysl-completer [] { ["N" "NV" "W"] }
def p-ysly-completer [] { ["1" "2" "3" "4" "5"] }
def p-ysla-completer [] { ["A" "E" "S"] }
def p-plimits-completer [] { ["N" "Y"] }
def p-pcss-completer [] { ["ALL" "GE1" "GE10" "GE50"] }
def p-pexp-completer [] { ["EXP" "EXPGT1YR" "EXPLE1YR"] }
def p-owop-completer [] { ["FEDERAL" "NON-POTW" "POTW"] }
def p-agoo-completer [] { ["AND" "OR"] }
def p-pexcd-completer [] { ["0" "GE0" "GE10" "GE100" "GE50"] }
def p-psncq-completer [] { ["GE1" "GE12" "GE2" "GE4" "GE8" "GT1" "GT12" "GT2" "GT4" "GT8"] }
def p-pctrack-completer [] { ["Off" "On" "Partial"] }
def p-dwd-completer [] { ["0" "GT0" "GT1000" "GT10000" "GT20000" "GT5000" "GT50000"] }
def p-pt-completer [] { ["0" "GT0" "GT1000" "GT10000" "GT20000" "GT5000" "GT50000"] }
def p-pdwdist-completer [] { ["LT1" "LT10" "LT15" "LT2" "LT5" "N"] }
def p-pswdmp-completer [] { ["1" "2" "3" "4" "5"] }
def p-pswvio-completer [] { ["N" "Y"] }
def p-fntype-completer [] { ["ALL" "BEGINS" "CONTAINS" "EXACT"] }
def p-pidall-completer [] { ["N" "Y"] }
def p-last-dmr-within-completer [] { ["N" "W"] }
def p-indsw-completer [] { ["N" "Y"] }
def p-msgp-ptype-completer [] { ["NOE" "NOI"] }
def p-mon-type-completer [] { ["BENCH" "BENCHG2" "ELG"] }
def p-ms4-completer [] { ["N" "Y"] }
def p-oo-f-ntype-completer [] { ["ALL" "BEGINS" "CONTAINS" "EXACT"] }
def p-fac-ico-completer [] { ["N" "Y"] }
def p-limit-addr-completer [] { ["N" "Y"] }
def p-ejscreen-over80cnt-completer [] { ["1" "10" "11" "2" "3" "4" "5" "6" "7" "8" "9"] }
def p-bio-current-vio-completer [] { ["N" "Y"] }
def p-bio-vio-last-year-completer [] { ["N" "Y"] }
def p-vio-last-year-completer [] { ["N" "Y"] }
def tablelist-completer [] { ["N" "Y"] }
def maplist-completer [] { ["N" "Y"] }
def summarylist-completer [] { ["N" "Y"] }
def descending-completer [] { ["N" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cwa-rest-services-get-download get" } } | get name | first)
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

# Clean Water Act (CWA) Download Data Service
#
# GET /cwa_rest_services.get_download
export def "cwa-rest-services-get-download get" [
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
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "qcolumns" $qcolumns "scalar") (serialize-qp "p_pretty_print" $p_pretty_print "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cwa_rest_services.get_download" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "qid": $qid, "qcolumns": $qcolumns, "p_pretty_print": $p_pretty_print} | compact), body: null}
}

# Clean Water Act (CWA) Download Data Service
#
# POST /cwa_rest_services.get_download
export def "cwa-rest-services-get-download create" [
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
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cwa_rest_services.get_download")
  let req_body = {"output": $output, "qid": $qid, "qcolumns": $qcolumns, "p_pretty_print": $p_pretty_print} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Clean Water Act (CWA) Facility Search Service
#
# GET /cwa_rest_services.get_facilities
export def "cwa-rest-services-get-facilities get" [
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
  --p-sa: string # Facility street address. Enter a complete or partial street address.
  --p-sa1: string # Facility street address. Enter a complete or partial street address. Note that p_sa1 is culmulative with p_sa.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-ff: string@p-ff-completer # Federal Facility Indicator Flag. Enter Y to restrict searches to federal facilities.
  --p-act: string # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits. A Y will select ICIS NPDES permits with a status of effective, continued, or expired.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-iv: string # Facility has a violation status of 'In Viol' during any of the selected quarters. Range: Fiscal Year 2020 Quarter 2 to Fiscal Year 2017 Quarter 2 Multiple values are comma delimited. |||||| Fiscal Years |||||| - FY2020 or FY20 or 2020 or 20 - FY2019 or FY19 or 2019 or 19 - FY2018 or FY18 or 2018 or 18 - FY2017 or FY17 or 2017 or 17 ||||| Fiscal Quarters ||||| - FY2020Q2 or FY20Q2 or 20202 or 202 or 13 - FY2020Q1 or FY20Q1 or 20201 or 201 or 12 - FY2019Q4 or FY19Q4 or 20194 or 194 or 11 - FY2019Q3 or FY19Q3 or 20193 or 193 or 10 - FY2019Q2 or FY19Q2 or 20192 or 192 or 9 - FY2019Q1 or FY19Q1 or 20191 or 191 or 8 - FY2018Q4 or FY18Q4 or 20184 or 184 or 7 - FY2018Q3 or FY18Q3 or 20183 or 183 or 6 - FY2018Q2 or FY18Q2 or 20182 or 182 or 5 - FY2018Q1 or FY18Q1 or 20181 or 181 or 4 - FY2017Q4 or FY17Q4 or 20174 or 174 or 3 - FY2017Q3 or FY17Q3 or 20173 or 173 or 2 - FY2017Q2 or FY17Q2 or 20172 or 172 or 1
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-imp-cau-grp: string@p-imp-cau-grp-completer # Facility is discharging a pollutant group causing a waterbody to be impaired. Enter 1 through 34 (the internal number of the pollutant group); or enter a partial name such as Dioxin,Temp,tUrBidity.
  --p-imp-pol: string@p-imp-pol-completer # Facility is discharging pollutants that are potentially contributing to the impairment of local waterbodies according to the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - ALL = Air and RCRA and Water
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-pstat: string # Permit Status Filter. Enter one or more of the following codes. Provide multiple values as a comma-delimited list. - EFF = Effective - EXP = Expired - PND = Pending - TRM = Terminated - RET = Retired - NON = Not Needed - ADC = Admin Continued
  --p-ptype: string # Permit Type Filter. Enter one or more code values to filter results. Provide multiple values as a comma-delimited list. - NPD = NPDES Individual Permit - NGP = NPDES Master General Permit - GPC = General Permit Covered Facility - SNN = State Issued Master General Permit (Non-NPDES) - IIU = Individual IU Permit (Non-NPDES) - SIN = Individual State Issued Permit (Non-NPDES) - APR = Associated Permit Record - UFT = Unpermitted Facility
  --p-pcomp: string # Permit Component Code Filter. Enter one or more codes to filter results. Provide multiple values as a comma-delimited list. - PRE = Pretreatment - CAF = CAFO - CSO = CSO - POT = POTW - BIO = Biosolids - SWS = Storm Water Small MS4s - SWM = Storm Water Medium/Large MS4s - SWI = Storm Water Industrial - SWC = Storm Water Construction
  --p-plimits: string@p-plimits-completer # Permit Limits Present Flag. Enter Y to limit results to facilities have present permit limits.
  --p-pcss: string@p-pcss-completer # Combined Sewer Systems Outflows Limiter. Enter one of the following to limit results to facilities having the given count of CSS outflows. - ALL = returns all facilities, regardless of the number of outflows. - GE1 = returns facilities with one or more outflows. - GE10 = returns facilities with ten or more outflows. - GE50 = returns facilities with fifty or more outflows.
  --p-pexp: string@p-pexp-completer # Permit Expired or Administratively Continued Limiter. Enter one of the following values to filter results. - EXP = limit results to facilities with permits expired or administratively continued. - EXPLE1YR = limit resuls to facilities with permits expired administratively continued within the past year. - EXPGT1YR = limit resuls to facilities with permits expired administratively continued more than a year ago.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following values to restrict results. - Federal = Federal facilities regulated under the NPDES program. - POTW = Publicly owned treatment works. Treatment works that are owned by a State, Tribe, or municipality. - Non-POTW = Non-publicly owned treatment works. Often referred to as "non-municipals" or "industrials".
  --p-ipfti: string
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type Code. See ICIS Compliance Monitor Types lookup serivce for a list of available codes and descriptions.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-pccs: string # Current Compliance Status: ||||||||||||||||||||||||||| Significant Noncompliance (SNC) ||||||||||||||||||||||||||| - SNC = E, S, X, T, D - E�= E(EffViol) - S�= S(CSchVio) - X = X(EffNMth) - T = T(CSchRpt) - D�= D(DMR NR) ||||||||||||||||||||||||||| Noncompliance (NC) ||||||||||||||||||||||||||| - NC = N, V - N�= N(RptViol) - V�= V(NonRNCV) ||||||||||||||||||||||||||| New Violations (PQV) ||||||||||||||||||||||||||| - PQV = New Violations (13th Quarter) ||||||||||||||||||||||||||| No Violations (NV) ||||||||||||||||||||||||||| - NV = R, P, M, U, W , Blank, and No New Violations (no PQV) - R�= R(Resolvd) - P�= P(ResPend) - M�= C(Manual) - U = U(N/A) - W = W(N/A) - Blank = (null) May contain multiple comma-separated values.
  --p-pexcd: string@p-pexcd-completer # 3-Year Effluent Exceedances Limiter. Enter a value to restrict results to facilities with the given amount of exceedances in the past 3 years. - 0 = facilities with no exceedances - GE0 = facilities with one or more exceedances - GE10 = facilities with ten or more exceedances - GE50 = facilities with fifty or more exceedances - GE100 = facilities with one hundred or more exceedances
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-pt: string@p-pt-completer # POTW Transfers. Pounds of toxic chemicals transferred to a Publicly Operated Treatment Works (POTW) as reported to the Toxics Release Inventory.
  --p-pdwdist: string@p-pdwdist-completer # Distance (in miles) to downstream drinking water intake.
  --p-pswdpc: string # Pollutant Category Code: Values: WTR for Water, AIR for Air
  --p-pswdmp: string@p-pswdmp-completer # Used to determine limit begin and end dates for surface water discharges. Number represents years from current date.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswcas: string # CAS numbers for surface water discharges. May contain multiple comma-separated values.
  --p-pswparam: string # Parameter codes for surface water discharges. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-radwbd: string # 2-, 4-, 6-, 8-, 10-, or 12 character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Will search against WBD values otained by "reach indexing" NPDES permits against the medium resolution National Hydrography Dataset.
  --p-frswbd: string # Works exactly the same as the p_wbd parameter. 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-months-last-dmr: float # The number of months since the last Discharge Monitoring Report has been submitted.
  --p-last-dmr-within: string@p-last-dmr-within-completer # W value returns facilities that have submitted DMRs within the number of months specified by p_months_last_dmr. An N value returns facilities that have not submitted a DMR within the specified number of months.
  --p-indsw: string@p-indsw-completer # Industrial Stormwater Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-msgp-ptype: string@p-msgp-ptype-completer # Multi-Sector General Purpose Permit Type. Enter a value to filter results by MSGP Permit Type. - NOI = Notice of Intent - NOE = No Exposure Certification
  --p-mon-type: string@p-mon-type-completer # For use with the Industrial Stormwater search only. Valid values are BENCHGS fro Benchmark (Alert Limit) G2 Ore, BENCH for Benchmark (Alert Limit), and ELG fro Effluent Limitation Guidelines(ELG)(Effluent Limit).
  --p-iagency: string # Issuing Agency Limiter. Enter a single value to filter results by the issuing agency, e.g. "State" or "EPA".
  --p-permitting-agency: string
  --p-isws: string # Multi-Sector General Purpose Permit Subsector Individual Identifier. Enter a value to filter results.
  --p-iswss: string # Multi-Sector General Purpose Permit Subsector Group Code. Enter a value to filter results.
  --p-iswss-id: string # Multi-Sector General Purpose Permit Sector Code. Enter a value to filter results.
  --p-ds1: string # Submitted Date Filter Start. To filter by the date of submission, enter a start date here and an end date in the p_ds2 parameter. Both dates are required for filtering.
  --p-ds2: string # Submitted Date Filter End. To filter by the date of submission, enter an end date here and a start date in the p_ds1 parameter. Both dates are required for filtering.
  --p-da1: string # Active Date Filter Start. To filter by the active date, enter a start date here and an end date in the p_da2 parameter. Both dates are required for filtering.
  --p-da2: string # Active Date Filter End. To filter by the active date, enter an end date here and a start date in the p_da1 parameter. Both dates are required for filtering.
  --p-ms4: string@p-ms4-completer # Municipal Separate Storm Water Sewer (MS4) Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-oo-fn: string # Owner/Operator Name. Enter the owner/operator name of the facility.
  --p-oo-f-ntype: string@p-oo-f-ntype-completer # Owner/Operator Name Multiple Selection Evaluator.
  --p-oo-sa: string # Owner/Operator Address. Enter the address of the owner/operator of the facility.
  --p-oo-sa1: string # Owner/Operator Address Line 2. Enter the line 2 address of the owner/operator of the facility.
  --p-oo-ct: string # Owner/Operator City. Enter the city where the owner/operator of the facility is located.
  --p-oo-st: string # Owner/Operator State. Enter the standardized postal state code where the owner/operator of the facility is located.
  --p-oo-zip: string # Owner/Operator Zip Code. Enter the postal zip code where the owner/operator of the facility is located.
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-alrexceed: float # Alert Limits Exceedences Limiter. Enter a numeric value to restrict results to facilities having the given amount or more of alert limits exceedances.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --p-bio-flag: string # A Y value will select all biosolid-related permits.
  --p-bio-fac-type: string # The code indicating the reporting obligation reason: - POT = A POTW with a design flow rate equal to or greater than one million gallons per day - CLI = A Class I Sludge Management Facility as defined in 40 CFR 503.9 - PPL = A POTW that serves 10,000 people or more - OTH = Otherwise required to report (e.g., permit condition, enforcement action) - NOA = None of the above
  --p-bio-trtmnt-procs: string # The biosolids or sewage sludge treatment process or processes at the facility: - AER = Aerobic Digestion - AIR = Air Drying (or Sludge Drying Beds) - ANA = Anaerobic Digestion - COD = Beta Ray Irradiation - COM = Lower Temperature Composting - DEW = Pasteurization - DIS = Gamma Ray Irradiation - HEA = Heat Drying (e.g., Flash Dryer, Spray Dryer, Rotary Dryer) - HET = Heat Treatment (Liquid Sewage Sludge Heated to 356 Deg. F/180 Deg. C or Higher for 30 min.) - HTC = Higher Temperature Composting - MET = Methane or Biogas Capture and Recovery - OTH = Other Treatment Process - PRE = Preliminary Operations (e.g., Sludge Grinding, Degritting, Blending) - SLU = Sludge Lagoon - STA = Lime Stabilization - THE = Temporary Sludge Storage (Sewage Sludge Stored on Land 2 Years or Less, Not in Sewage Sludge Unit) - THI = Thickening (Gravity and/or Flotation Thickening, Centrifugation, Belt Filter Press, Vacuum Filter) - THM = Thermophilic Aerobic Digestion - UND = Long-Term Sludge Storage (Sewage Sludge Stored on Land 2 Years or More, not in Sewage Sludge Unit)"
  --p-bio-analy-method-catgry: string # The unique code for the category of the analytic methods used by the facility to analyze regulated parameters (including enteric viruses, fecal coliforms, helminth ova, and Salmonella sp.) at the facility: - PAT = Pathogens - MET = Metals - NIT = Nitrogen Compounds - OTH = Other Analytes
  --p-bio-total-volume-amt: string # Total annual amount (in dry metric tons) of biosolids or sewage sludge generated at the facility. - EQ0 = 0 - IN0_1 = GT 0 but LT 1 - IN0_289 = GT 0 but LT 290 MT/year - IN290_1499 = GE 290 but LT 1500 MT/year - IN1500_14999 = GE 1500 but LT 15,000 - GE15000 = GE 15,000
  --p-bio-mgmt-prctce-type: string # The unique code that identifies the type of biosolids or sewage sludge management practice (e.g., land application, surface disposal, incineration) used by the facility. The facility will separately report the management practice for each biosolids or sewage sludge form and pathogen class. This data element will also identify the management practices used by surface disposal site owners/operators (see 40 CFR 503.24): - BIN = Incineration - BLN = Land Application - BOT = Other Management Practice - BSD = Surface Disposal
  --p-bio-mgmt-prctce-stype: string # This is the code indicating additional detail about the type of Management Practice used for a volume of Biosolids or Sewage Sludge: - ADV = Advanced Alkaline Stabilized Biosolids Distribution & Marketing - AGR = Agricultural Land Application - COM = Distribution and Marketing - Compost - DEE = Deep-well Injection Disposal - DIS = Disposal in a Municipal Landfill (under 40 CFR 258) - DMO = Distribution and Marketing - Other - HEA = Heat Dried Biosolids Distribution & Marketing - OTL = Other Land Application Management Practice Detail - OTO = Other Management Practice Detail - RSA = Reclamation Site Application - SEN = Sent to Cement Kiln for Use as Alternative Energy - STO = Storage - UIC = Use in Construction - UPS = Used in Production of Syngas - USE = Use as Daily Cover for Municipal Landfill (under 40 CFR 258)
  --p-bio-mgmt-prctce-handler: string # This is the code indicating the type of Biosolids or Sewage Sludge handlers/preparers. - OWN = Owner or Operator - OFF = Off-Site Third-Party Handler or Preparer
  --p-bio-mgmt-container: string # The code that identifies the nature of each biosolids and sewage sludge material generated by the facility in terms of whether the material is a biosolid or sewage sludge and whether the material is ultimately conveyed off-site in bulk or in bags. The facility separately reports the form for each biosolids or sewage sludge management practice or practices used by the facility and pathogen class: - BUL = Bulk - BAG = Bag or Container
  --p-bio-mgmt-pathogen: string # This code identifies the pathogen class [e.g., Class A, Class B, Not Applicable (Incineration)] for biosolids or sewage sludge generated by the facility. The facility will separately report the pathogen class for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form. It also is used to filter applicable Pathogen Reduction and Vector Attraction Reduction Options as well as Land Application Management Practice Deficiencies. Only reqired for some of the mgmt. practice types: - AAA = Class A - AEQ = Class A EQ (sale/give away) - BBB = Class B - NAP = Not Applicable (Incineration)
  --p-bio-mgmt-pathred: string # This is the description of the option used by the facility to control pathogen for a Biosolids Management Practice: - A1 = Class A - Alternative 1: Time/Temperature - A2 = Class A - Alternative 2: pH/Temperature/Percent Solids - A3 = Class A - Alternative 3: Test Enteric Viruses and Helminth ova; Operating Parameters - A4 = Class A - Alternative 4: Test Enteric Viruses and Helminth ova; No New Solids - A51 = Class A - Alternative 5: PFRP 1: Composting - A52 = Class A - Alternative 5: PFRP 2: Heat Drying - A53 = Class A - Alternative 5: PFRP 3: Liquid heat treatment - A54 = Class A - Alternative 5: PFRP 4: Thermophilic Aerobic Digestion (ATAD) - A55 = Class A - Alternative 5 PFPR 5: Beta Ray Irradiation - A56 = Class A - Alternative 5 PFPR 6: Gamma Ray Irradiation - A57 = Class A - Alternative 5: PFRP 7: Pasteurization - A6 = Class A - Alternative 6: PFRP Equivalency - B1 = Class B - Alternative 1: Fecal Coliform Geometric Mean - B21 = Class B - Alternative 2 PSRP 1: Aerobic Digestion - B22 = Class B - Alternative 2 PSRP 2: Air Drying - B23 = Class B - Alternative 2 PSRP 3: Anaerobic Digestion - B24 = Class B - Alternative 2 PSRP 4: Composting - B25 = Class B - Alternative 2 PSRP 5: Lime Stabilization - B3 = Class B - Alternative 3: PSRP Equivalency - PH = pH Adjustment (Domestic Septage)
  --p-bio-mgmt-vector: string # The unique code that identifies the option used by the facility for vector attraction reduction. See a listing of these vector attraction reduction options at 40 CFR 503.33(b)(1) through (11). The facility will separately report the vector attraction reduction options for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form as well as by each biosolids or sewage sludge pathogen class: - VR1 = Option 1 - Volatile Solids Reduction - VR2 = Option 2 - Bench-Scale Volatile Solids Reduction (Anaerobic Bench Test) - VR3 = Option 3 - Bench-Scale Volatile Solids Reduction (Aerobic Bench Test w/ Percent Solids - 2% or Less) - VR4 = Option 4 - Specific Oxygen Uptake Rate - VR5 = Option 5 - Aerobic Processing (Thermophilic Aerobic Digestion/Composting) - VR6 = Option 6 - Alkaline Treatment - VR7 = Option 7 - Drying (Equal to or Greater than 75 Percent) - VR8 = Option 8 - Drying (Equal to or Greater than 90 Percent) - VR9 = Option 9 - Sewage Sludge Injection - V10 = Option 10 - Sewage Sludge Timely Incorporation into Land - V11 = Option 11 - Sewage Sludge Covered at the End of Each Operating Day
  --p-bio-mgmt-def-category: string # This is the code indicating the type of NPDES special regulatory program deficiency: - INC = Biosolids Incineration - LNA = Biosolids Land Application - LNB = Biosolids Land Application - Pathogen Class B - OTB = Biosolids Other Management Practice - SFD = Biosolids Surface Disposal
  --p-bio-mgmt-deficiencies: float # The number of times noncompliance was reported by the facility in the last 3 years. The results returned will include facilities whose number of reported noncompliance events is greater than or equal to the number entered.
  --p-bio-vio-code: string # The Biosolids Single Event Violation Code. Enter one or mode codes.
  --p-bio-current-vio: string@p-bio-current-vio-completer # Indicator of whether the facility is currently in violation for biosolids under the Clean Water Act, in the 12th or 13th quarter: - Y = Yes - N = No
  --p-bio-qtrs-in-vio: float # The number of quarters, in the last three years, where the facility was in violation for a biosolids violation type. The results returned will include facilities whose number of quarters with violations is greater than or equal to the number entered.
  --p-bio-rpt-year: string # The last year that the permittee submitted an annual Biosolids report. Valid values are NONE and any year greater or equal to 2016.
  --p-bio-vio-last-year: string@p-bio-vio-last-year-completer # Identifies if a biosolids violation has occured in the last year. Valid values are Y and N.
  --p-msgp-rpt-year: string # The last year that a MSGP report was submitted for the permit. Valid values are "NONE" and any year Greater or Eqal to 2015.
  --p-vio-last-year: string@p-vio-last-year-completer # Identifies if a permit violation has occured in the last year. Valid values are Y and N.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-e90-count: float # Number of E90 Exceedances. Identifies water permits with a number of E90 (Effluient Exceedances) >= the value provided for the last number of years provided by the p_e90_years value.
  --p-e90-years: float # Number of years for the p_e90_count search. Identified the past number of years to be used for the p_e90_count search.
  --p-psc: string # Point Source Category.
]: nothing -> record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string, Version: string, VioLast4QRows: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_fn" $p_fn "scalar") (serialize-qp "p_sa" $p_sa "scalar") (serialize-qp "p_sa1" $p_sa1 "scalar") (serialize-qp "p_ct" $p_ct "scalar") (serialize-qp "p_co" $p_co "scalar") (serialize-qp "p_fips" $p_fips "scalar") (serialize-qp "p_st" $p_st "scalar") (serialize-qp "p_zip" $p_zip "scalar") (serialize-qp "p_frs" $p_frs "scalar") (serialize-qp "p_reg" $p_reg "scalar") (serialize-qp "p_sic" $p_sic "scalar") (serialize-qp "p_ncs" $p_ncs "scalar") (serialize-qp "p_pen" $p_pen "scalar") (serialize-qp "p_c1lat" $p_c1lat "scalar") (serialize-qp "p_c1lon" $p_c1lon "scalar") (serialize-qp "p_c2lat" $p_c2lat "scalar") (serialize-qp "p_c2lon" $p_c2lon "scalar") (serialize-qp "p_usmex" $p_usmex "scalar") (serialize-qp "p_sic2" $p_sic2 "scalar") (serialize-qp "p_sic4" $p_sic4 "scalar") (serialize-qp "p_fa" $p_fa "scalar") (serialize-qp "p_ff" $p_ff "scalar") (serialize-qp "p_act" $p_act "scalar") (serialize-qp "p_maj" $p_maj "scalar") (serialize-qp "p_mact" $p_mact "scalar") (serialize-qp "p_fea" $p_fea "scalar") (serialize-qp "p_feay" $p_feay "scalar") (serialize-qp "p_feaa" $p_feaa "scalar") (serialize-qp "p_iea" $p_iea "scalar") (serialize-qp "p_ieay" $p_ieay "scalar") (serialize-qp "p_ieaa" $p_ieaa "scalar") (serialize-qp "p_qiv" $p_qiv "scalar") (serialize-qp "p_iv" $p_iv "scalar") (serialize-qp "p_impw" $p_impw "scalar") (serialize-qp "p_imp_cau_grp" $p_imp_cau_grp "scalar") (serialize-qp "p_imp_pol" $p_imp_pol "scalar") (serialize-qp "p_trep" $p_trep "scalar") (serialize-qp "p_pm" $p_pm "scalar") (serialize-qp "p_pd" $p_pd "scalar") (serialize-qp "p_ico" $p_ico "scalar") (serialize-qp "p_huc" $p_huc "scalar") (serialize-qp "p_pid" $p_pid "scalar") (serialize-qp "p_med" $p_med "scalar") (serialize-qp "p_ysl" $p_ysl "scalar") (serialize-qp "p_ysly" $p_ysly "scalar") (serialize-qp "p_ysla" $p_ysla "scalar") (serialize-qp "p_qs" $p_qs "scalar") (serialize-qp "p_sfs" $p_sfs "scalar") (serialize-qp "p_tribeid" $p_tribeid "scalar") (serialize-qp "p_tribename" $p_tribename "scalar") (serialize-qp "p_tribedist" $p_tribedist "scalar") (serialize-qp "p_pstat" $p_pstat "scalar") (serialize-qp "p_ptype" $p_ptype "scalar") (serialize-qp "p_pcomp" $p_pcomp "scalar") (serialize-qp "p_plimits" $p_plimits "scalar") (serialize-qp "p_pcss" $p_pcss "scalar") (serialize-qp "p_pexp" $p_pexp "scalar") (serialize-qp "p_owop" $p_owop "scalar") (serialize-qp "p_ipfti" $p_ipfti "scalar") (serialize-qp "p_agoo" $p_agoo "scalar") (serialize-qp "p_idt1" $p_idt1 "scalar") (serialize-qp "p_idt2" $p_idt2 "scalar") (serialize-qp "p_pityp" $p_pityp "scalar") (serialize-qp "p_pfead1" $p_pfead1 "scalar") (serialize-qp "p_pfead2" $p_pfead2 "scalar") (serialize-qp "p_pfeat" $p_pfeat "scalar") (serialize-qp "p_pccs" $p_pccs "scalar") (serialize-qp "p_pexcd" $p_pexcd "scalar") (serialize-qp "p_psncq" $p_psncq "scalar") (serialize-qp "p_pctrack" $p_pctrack "scalar") (serialize-qp "p_dwd" $p_dwd "scalar") (serialize-qp "p_pt" $p_pt "scalar") (serialize-qp "p_pdwdist" $p_pdwdist "scalar") (serialize-qp "p_pswdpc" $p_pswdpc "scalar") (serialize-qp "p_pswdmp" $p_pswdmp "scalar") (serialize-qp "p_pswpol" $p_pswpol "scalar") (serialize-qp "p_pswcas" $p_pswcas "scalar") (serialize-qp "p_pswparam" $p_pswparam "scalar") (serialize-qp "p_pswvio" $p_pswvio "scalar") (serialize-qp "p_wbd" $p_wbd "scalar") (serialize-qp "p_radwbd" $p_radwbd "scalar") (serialize-qp "p_frswbd" $p_frswbd "scalar") (serialize-qp "p_fntype" $p_fntype "scalar") (serialize-qp "p_pidall" $p_pidall "scalar") (serialize-qp "p_months_last_dmr" $p_months_last_dmr "scalar") (serialize-qp "p_last_dmr_within" $p_last_dmr_within "scalar") (serialize-qp "p_indsw" $p_indsw "scalar") (serialize-qp "p_msgp_ptype" $p_msgp_ptype "scalar") (serialize-qp "p_mon_type" $p_mon_type "scalar") (serialize-qp "p_iagency" $p_iagency "scalar") (serialize-qp "p_permitting_agency" $p_permitting_agency "scalar") (serialize-qp "p_isws" $p_isws "scalar") (serialize-qp "p_iswss" $p_iswss "scalar") (serialize-qp "p_iswssID" $p_iswss_id "scalar") (serialize-qp "p_ds1" $p_ds1 "scalar") (serialize-qp "p_ds2" $p_ds2 "scalar") (serialize-qp "p_da1" $p_da1 "scalar") (serialize-qp "p_da2" $p_da2 "scalar") (serialize-qp "p_MS4" $p_ms4 "scalar") (serialize-qp "p_ooFN" $p_oo_fn "scalar") (serialize-qp "p_ooFNtype" $p_oo_f_ntype "scalar") (serialize-qp "p_ooSA" $p_oo_sa "scalar") (serialize-qp "p_ooSA1" $p_oo_sa1 "scalar") (serialize-qp "p_ooCt" $p_oo_ct "scalar") (serialize-qp "p_ooSt" $p_oo_st "scalar") (serialize-qp "p_ooZip" $p_oo_zip "scalar") (serialize-qp "p_fac_ico" $p_fac_ico "scalar") (serialize-qp "p_icoo" $p_icoo "scalar") (serialize-qp "p_fac_icos" $p_fac_icos "scalar") (serialize-qp "p_ejscreen" $p_ejscreen "scalar") (serialize-qp "p_alrexceed" $p_alrexceed "scalar") (serialize-qp "p_limit_addr" $p_limit_addr "scalar") (serialize-qp "p_lat" $p_lat "scalar") (serialize-qp "p_long" $p_long "scalar") (serialize-qp "p_radius" $p_radius "scalar") (serialize-qp "p_ejscreen_over80cnt" $p_ejscreen_over80cnt "scalar") (serialize-qp "p_bio_flag" $p_bio_flag "scalar") (serialize-qp "p_bio_fac_type" $p_bio_fac_type "scalar") (serialize-qp "p_bio_trtmnt_procs" $p_bio_trtmnt_procs "scalar") (serialize-qp "p_bio_analy_method_catgry" $p_bio_analy_method_catgry "scalar") (serialize-qp "p_bio_total_volume_amt" $p_bio_total_volume_amt "scalar") (serialize-qp "p_bio_mgmt_prctce_type" $p_bio_mgmt_prctce_type "scalar") (serialize-qp "p_bio_mgmt_prctce_stype" $p_bio_mgmt_prctce_stype "scalar") (serialize-qp "p_bio_mgmt_prctce_handler" $p_bio_mgmt_prctce_handler "scalar") (serialize-qp "p_bio_mgmt_container" $p_bio_mgmt_container "scalar") (serialize-qp "p_bio_mgmt_pathogen" $p_bio_mgmt_pathogen "scalar") (serialize-qp "p_bio_mgmt_pathred" $p_bio_mgmt_pathred "scalar") (serialize-qp "p_bio_mgmt_vector" $p_bio_mgmt_vector "scalar") (serialize-qp "p_bio_mgmt_def_category" $p_bio_mgmt_def_category "scalar") (serialize-qp "p_bio_mgmt_deficiencies" $p_bio_mgmt_deficiencies "scalar") (serialize-qp "p_bio_vio_code" $p_bio_vio_code "scalar") (serialize-qp "p_bio_current_vio" $p_bio_current_vio "scalar") (serialize-qp "p_bio_qtrs_in_vio" $p_bio_qtrs_in_vio "scalar") (serialize-qp "p_bio_rpt_year" $p_bio_rpt_year "scalar") (serialize-qp "p_bio_vio_last_year" $p_bio_vio_last_year "scalar") (serialize-qp "p_msgp_rpt_year" $p_msgp_rpt_year "scalar") (serialize-qp "p_vio_last_year" $p_vio_last_year "scalar") (serialize-qp "queryset" $queryset "scalar") (serialize-qp "responseset" $responseset "scalar") (serialize-qp "tablelist" $tablelist "scalar") (serialize-qp "maplist" $maplist "scalar") (serialize-qp "summarylist" $summarylist "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "qcolumns" $qcolumns "scalar") (serialize-qp "p_e90_count" $p_e90_count "scalar") (serialize-qp "p_e90_years" $p_e90_years "scalar") (serialize-qp "p_psc" $p_psc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cwa_rest_services.get_facilities" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "p_fn": $p_fn, "p_sa": $p_sa, "p_sa1": $p_sa1, "p_ct": $p_ct, "p_co": $p_co, "p_fips": $p_fips, "p_st": $p_st, "p_zip": $p_zip, "p_frs": $p_frs, "p_reg": $p_reg, "p_sic": $p_sic, "p_ncs": $p_ncs, "p_pen": $p_pen, "p_c1lat": $p_c1lat, "p_c1lon": $p_c1lon, "p_c2lat": $p_c2lat, "p_c2lon": $p_c2lon, "p_usmex": $p_usmex, "p_sic2": $p_sic2, "p_sic4": $p_sic4, "p_fa": $p_fa, "p_ff": $p_ff, "p_act": $p_act, "p_maj": $p_maj, "p_mact": $p_mact, "p_fea": $p_fea, "p_feay": $p_feay, "p_feaa": $p_feaa, "p_iea": $p_iea, "p_ieay": $p_ieay, "p_ieaa": $p_ieaa, "p_qiv": $p_qiv, "p_iv": $p_iv, "p_impw": $p_impw, "p_imp_cau_grp": $p_imp_cau_grp, "p_imp_pol": $p_imp_pol, "p_trep": $p_trep, "p_pm": $p_pm, "p_pd": $p_pd, "p_ico": $p_ico, "p_huc": $p_huc, "p_pid": $p_pid, "p_med": $p_med, "p_ysl": $p_ysl, "p_ysly": $p_ysly, "p_ysla": $p_ysla, "p_qs": $p_qs, "p_sfs": $p_sfs, "p_tribeid": $p_tribeid, "p_tribename": $p_tribename, "p_tribedist": $p_tribedist, "p_pstat": $p_pstat, "p_ptype": $p_ptype, "p_pcomp": $p_pcomp, "p_plimits": $p_plimits, "p_pcss": $p_pcss, "p_pexp": $p_pexp, "p_owop": $p_owop, "p_ipfti": $p_ipfti, "p_agoo": $p_agoo, "p_idt1": $p_idt1, "p_idt2": $p_idt2, "p_pityp": $p_pityp, "p_pfead1": $p_pfead1, "p_pfead2": $p_pfead2, "p_pfeat": $p_pfeat, "p_pccs": $p_pccs, "p_pexcd": $p_pexcd, "p_psncq": $p_psncq, "p_pctrack": $p_pctrack, "p_dwd": $p_dwd, "p_pt": $p_pt, "p_pdwdist": $p_pdwdist, "p_pswdpc": $p_pswdpc, "p_pswdmp": $p_pswdmp, "p_pswpol": $p_pswpol, "p_pswcas": $p_pswcas, "p_pswparam": $p_pswparam, "p_pswvio": $p_pswvio, "p_wbd": $p_wbd, "p_radwbd": $p_radwbd, "p_frswbd": $p_frswbd, "p_fntype": $p_fntype, "p_pidall": $p_pidall, "p_months_last_dmr": $p_months_last_dmr, "p_last_dmr_within": $p_last_dmr_within, "p_indsw": $p_indsw, "p_msgp_ptype": $p_msgp_ptype, "p_mon_type": $p_mon_type, "p_iagency": $p_iagency, "p_permitting_agency": $p_permitting_agency, "p_isws": $p_isws, "p_iswss": $p_iswss, "p_iswssID": $p_iswss_id, "p_ds1": $p_ds1, "p_ds2": $p_ds2, "p_da1": $p_da1, "p_da2": $p_da2, "p_MS4": $p_ms4, "p_ooFN": $p_oo_fn, "p_ooFNtype": $p_oo_f_ntype, "p_ooSA": $p_oo_sa, "p_ooSA1": $p_oo_sa1, "p_ooCt": $p_oo_ct, "p_ooSt": $p_oo_st, "p_ooZip": $p_oo_zip, "p_fac_ico": $p_fac_ico, "p_icoo": $p_icoo, "p_fac_icos": $p_fac_icos, "p_ejscreen": $p_ejscreen, "p_alrexceed": $p_alrexceed, "p_limit_addr": $p_limit_addr, "p_lat": $p_lat, "p_long": $p_long, "p_radius": $p_radius, "p_ejscreen_over80cnt": $p_ejscreen_over80cnt, "p_bio_flag": $p_bio_flag, "p_bio_fac_type": $p_bio_fac_type, "p_bio_trtmnt_procs": $p_bio_trtmnt_procs, "p_bio_analy_method_catgry": $p_bio_analy_method_catgry, "p_bio_total_volume_amt": $p_bio_total_volume_amt, "p_bio_mgmt_prctce_type": $p_bio_mgmt_prctce_type, "p_bio_mgmt_prctce_stype": $p_bio_mgmt_prctce_stype, "p_bio_mgmt_prctce_handler": $p_bio_mgmt_prctce_handler, "p_bio_mgmt_container": $p_bio_mgmt_container, "p_bio_mgmt_pathogen": $p_bio_mgmt_pathogen, "p_bio_mgmt_pathred": $p_bio_mgmt_pathred, "p_bio_mgmt_vector": $p_bio_mgmt_vector, "p_bio_mgmt_def_category": $p_bio_mgmt_def_category, "p_bio_mgmt_deficiencies": $p_bio_mgmt_deficiencies, "p_bio_vio_code": $p_bio_vio_code, "p_bio_current_vio": $p_bio_current_vio, "p_bio_qtrs_in_vio": $p_bio_qtrs_in_vio, "p_bio_rpt_year": $p_bio_rpt_year, "p_bio_vio_last_year": $p_bio_vio_last_year, "p_msgp_rpt_year": $p_msgp_rpt_year, "p_vio_last_year": $p_vio_last_year, "queryset": $queryset, "responseset": $responseset, "tablelist": $tablelist, "maplist": $maplist, "summarylist": $summarylist, "callback": $callback, "qcolumns": $qcolumns, "p_e90_count": $p_e90_count, "p_e90_years": $p_e90_years, "p_psc": $p_psc} | compact), body: null}
}

# Clean Water Act (CWA) Facility Search Service
#
# POST /cwa_rest_services.get_facilities
export def "cwa-rest-services-get-facilities create" [
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
  --p-sa: string # Facility street address. Enter a complete or partial street address.
  --p-sa1: string # Facility street address. Enter a complete or partial street address. Note that p_sa1 is culmulative with p_sa.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --p-c1lat: float # In decimal degrees. Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees. Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees. Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees. Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-ff: string@p-ff-completer # Federal Facility Indicator Flag. Enter Y to restrict searches to federal facilities.
  --p-act: string # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits. A Y will select ICIS NPDES permits with a status of effective, continued, or expired.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-iv: string # Facility has a violation status of 'In Viol' during any of the selected quarters. Range: Fiscal Year 2020 Quarter 2 to Fiscal Year 2017 Quarter 2 Multiple values are comma delimited. |||||| Fiscal Years |||||| - FY2020 or FY20 or 2020 or 20 - FY2019 or FY19 or 2019 or 19 - FY2018 or FY18 or 2018 or 18 - FY2017 or FY17 or 2017 or 17 ||||| Fiscal Quarters ||||| - FY2020Q2 or FY20Q2 or 20202 or 202 or 13 - FY2020Q1 or FY20Q1 or 20201 or 201 or 12 - FY2019Q4 or FY19Q4 or 20194 or 194 or 11 - FY2019Q3 or FY19Q3 or 20193 or 193 or 10 - FY2019Q2 or FY19Q2 or 20192 or 192 or 9 - FY2019Q1 or FY19Q1 or 20191 or 191 or 8 - FY2018Q4 or FY18Q4 or 20184 or 184 or 7 - FY2018Q3 or FY18Q3 or 20183 or 183 or 6 - FY2018Q2 or FY18Q2 or 20182 or 182 or 5 - FY2018Q1 or FY18Q1 or 20181 or 181 or 4 - FY2017Q4 or FY17Q4 or 20174 or 174 or 3 - FY2017Q3 or FY17Q3 or 20173 or 173 or 2 - FY2017Q2 or FY17Q2 or 20172 or 172 or 1
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-imp-cau-grp: string@p-imp-cau-grp-completer # Facility is discharging a pollutant group causing a waterbody to be impaired. Enter 1 through 34 (the internal number of the pollutant group); or enter a partial name such as Dioxin,Temp,tUrBidity.
  --p-imp-pol: string@p-imp-pol-completer # Facility is discharging pollutants that are potentially contributing to the impairment of local waterbodies according to the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - ALL = Air and RCRA and Water
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-pstat: string # Permit Status Filter. Enter one or more of the following codes. Provide multiple values as a comma-delimited list. - EFF = Effective - EXP = Expired - PND = Pending - TRM = Terminated - RET = Retired - NON = Not Needed - ADC = Admin Continued
  --p-ptype: string # Permit Type Filter. Enter one or more code values to filter results. Provide multiple values as a comma-delimited list. - NPD = NPDES Individual Permit - NGP = NPDES Master General Permit - GPC = General Permit Covered Facility - SNN = State Issued Master General Permit (Non-NPDES) - IIU = Individual IU Permit (Non-NPDES) - SIN = Individual State Issued Permit (Non-NPDES) - APR = Associated Permit Record - UFT = Unpermitted Facility
  --p-pcomp: string # Permit Component Code Filter. Enter one or more codes to filter results. Provide multiple values as a comma-delimited list. - PRE = Pretreatment - CAF = CAFO - CSO = CSO - POT = POTW - BIO = Biosolids - SWS = Storm Water Small MS4s - SWM = Storm Water Medium/Large MS4s - SWI = Storm Water Industrial - SWC = Storm Water Construction
  --p-plimits: string@p-plimits-completer # Permit Limits Present Flag. Enter Y to limit results to facilities have present permit limits.
  --p-pcss: string@p-pcss-completer # Combined Sewer Systems Outflows Limiter. Enter one of the following to limit results to facilities having the given count of CSS outflows. - ALL = returns all facilities, regardless of the number of outflows. - GE1 = returns facilities with one or more outflows. - GE10 = returns facilities with ten or more outflows. - GE50 = returns facilities with fifty or more outflows.
  --p-pexp: string@p-pexp-completer # Permit Expired or Administratively Continued Limiter. Enter one of the following values to filter results. - EXP = limit results to facilities with permits expired or administratively continued. - EXPLE1YR = limit resuls to facilities with permits expired administratively continued within the past year. - EXPGT1YR = limit resuls to facilities with permits expired administratively continued more than a year ago.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following values to restrict results. - Federal = Federal facilities regulated under the NPDES program. - POTW = Publicly owned treatment works. Treatment works that are owned by a State, Tribe, or municipality. - Non-POTW = Non-publicly owned treatment works. Often referred to as "non-municipals" or "industrials".
  --p-ipfti: string
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type Code. See ICIS Compliance Monitor Types lookup serivce for a list of available codes and descriptions.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-pccs: string # Current Compliance Status: ||||||||||||||||||||||||||| Significant Noncompliance (SNC) ||||||||||||||||||||||||||| - SNC = E, S, X, T, D - E�= E(EffViol) - S�= S(CSchVio) - X = X(EffNMth) - T = T(CSchRpt) - D�= D(DMR NR) ||||||||||||||||||||||||||| Noncompliance (NC) ||||||||||||||||||||||||||| - NC = N, V - N�= N(RptViol) - V�= V(NonRNCV) ||||||||||||||||||||||||||| New Violations (PQV) ||||||||||||||||||||||||||| - PQV = New Violations (13th Quarter) ||||||||||||||||||||||||||| No Violations (NV) ||||||||||||||||||||||||||| - NV = R, P, M, U, W , Blank, and No New Violations (no PQV) - R�= R(Resolvd) - P�= P(ResPend) - M�= C(Manual) - U = U(N/A) - W = W(N/A) - Blank = (null) May contain multiple comma-separated values.
  --p-pexcd: string@p-pexcd-completer # 3-Year Effluent Exceedances Limiter. Enter a value to restrict results to facilities with the given amount of exceedances in the past 3 years. - 0 = facilities with no exceedances - GE0 = facilities with one or more exceedances - GE10 = facilities with ten or more exceedances - GE50 = facilities with fifty or more exceedances - GE100 = facilities with one hundred or more exceedances
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-pt: string@p-pt-completer # POTW Transfers. Pounds of toxic chemicals transferred to a Publicly Operated Treatment Works (POTW) as reported to the Toxics Release Inventory.
  --p-pdwdist: string@p-pdwdist-completer # Distance (in miles) to downstream drinking water intake.
  --p-pswdpc: string # Pollutant Category Code: Values: WTR for Water, AIR for Air
  --p-pswdmp: string@p-pswdmp-completer # Used to determine limit begin and end dates for surface water discharges. Number represents years from current date.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswcas: string # CAS numbers for surface water discharges. May contain multiple comma-separated values.
  --p-pswparam: string # Parameter codes for surface water discharges. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-radwbd: string # 2-, 4-, 6-, 8-, 10-, or 12 character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Will search against WBD values otained by "reach indexing" NPDES permits against the medium resolution National Hydrography Dataset.
  --p-frswbd: string # Works exactly the same as the p_wbd parameter. 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-months-last-dmr: float # The number of months since the last Discharge Monitoring Report has been submitted.
  --p-last-dmr-within: string@p-last-dmr-within-completer # W value returns facilities that have submitted DMRs within the number of months specified by p_months_last_dmr. An N value returns facilities that have not submitted a DMR within the specified number of months.
  --p-indsw: string@p-indsw-completer # Industrial Stormwater Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-msgp-ptype: string@p-msgp-ptype-completer # Multi-Sector General Purpose Permit Type. Enter a value to filter results by MSGP Permit Type. - NOI = Notice of Intent - NOE = No Exposure Certification
  --p-mon-type: string@p-mon-type-completer # For use with the Industrial Stormwater search only. Valid values are BENCHGS fro Benchmark (Alert Limit) G2 Ore, BENCH for Benchmark (Alert Limit), and ELG fro Effluent Limitation Guidelines(ELG)(Effluent Limit).
  --p-iagency: string # Issuing Agency Limiter. Enter a single value to filter results by the issuing agency, e.g. "State" or "EPA".
  --p-permitting-agency: string
  --p-isws: string # Multi-Sector General Purpose Permit Subsector Individual Identifier. Enter a value to filter results.
  --p-iswss: string # Multi-Sector General Purpose Permit Subsector Group Code. Enter a value to filter results.
  --p-iswss-id: string # Multi-Sector General Purpose Permit Sector Code. Enter a value to filter results.
  --p-ds1: string # Submitted Date Filter Start. To filter by the date of submission, enter a start date here and an end date in the p_ds2 parameter. Both dates are required for filtering.
  --p-ds2: string # Submitted Date Filter End. To filter by the date of submission, enter an end date here and a start date in the p_ds1 parameter. Both dates are required for filtering.
  --p-da1: string # Active Date Filter Start. To filter by the active date, enter a start date here and an end date in the p_da2 parameter. Both dates are required for filtering.
  --p-da2: string # Active Date Filter End. To filter by the active date, enter an end date here and a start date in the p_da1 parameter. Both dates are required for filtering.
  --p-ms4: string@p-ms4-completer # Municipal Separate Storm Water Sewer (MS4) Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-oo-fn: string # Owner/Operator Name. Enter the owner/operator name of the facility.
  --p-oo-f-ntype: string@p-oo-f-ntype-completer # Owner/Operator Name Multiple Selection Evaluator.
  --p-oo-sa: string # Owner/Operator Address. Enter the address of the owner/operator of the facility.
  --p-oo-sa1: string # Owner/Operator Address Line 2. Enter the line 2 address of the owner/operator of the facility.
  --p-oo-ct: string # Owner/Operator City. Enter the city where the owner/operator of the facility is located.
  --p-oo-st: string # Owner/Operator State. Enter the standardized postal state code where the owner/operator of the facility is located.
  --p-oo-zip: string # Owner/Operator Zip Code. Enter the postal zip code where the owner/operator of the facility is located.
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-alrexceed: float # Alert Limits Exceedences Limiter. Enter a numeric value to restrict results to facilities having the given amount or more of alert limits exceedances.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --p-bio-flag: string # A Y value will select all biosolid-related permits.
  --p-bio-fac-type: string # The code indicating the reporting obligation reason: - POT = A POTW with a design flow rate equal to or greater than one million gallons per day - CLI = A Class I Sludge Management Facility as defined in 40 CFR 503.9 - PPL = A POTW that serves 10,000 people or more - OTH = Otherwise required to report (e.g., permit condition, enforcement action) - NOA = None of the above
  --p-bio-trtmnt-procs: string # The biosolids or sewage sludge treatment process or processes at the facility: - AER = Aerobic Digestion - AIR = Air Drying (or Sludge Drying Beds) - ANA = Anaerobic Digestion - COD = Beta Ray Irradiation - COM = Lower Temperature Composting - DEW = Pasteurization - DIS = Gamma Ray Irradiation - HEA = Heat Drying (e.g., Flash Dryer, Spray Dryer, Rotary Dryer) - HET = Heat Treatment (Liquid Sewage Sludge Heated to 356 Deg. F/180 Deg. C or Higher for 30 min.) - HTC = Higher Temperature Composting - MET = Methane or Biogas Capture and Recovery - OTH = Other Treatment Process - PRE = Preliminary Operations (e.g., Sludge Grinding, Degritting, Blending) - SLU = Sludge Lagoon - STA = Lime Stabilization - THE = Temporary Sludge Storage (Sewage Sludge Stored on Land 2 Years or Less, Not in Sewage Sludge Unit) - THI = Thickening (Gravity and/or Flotation Thickening, Centrifugation, Belt Filter Press, Vacuum Filter) - THM = Thermophilic Aerobic Digestion - UND = Long-Term Sludge Storage (Sewage Sludge Stored on Land 2 Years or More, not in Sewage Sludge Unit)"
  --p-bio-analy-method-catgry: string # The unique code for the category of the analytic methods used by the facility to analyze regulated parameters (including enteric viruses, fecal coliforms, helminth ova, and Salmonella sp.) at the facility: - PAT = Pathogens - MET = Metals - NIT = Nitrogen Compounds - OTH = Other Analytes
  --p-bio-total-volume-amt: string # Total annual amount (in dry metric tons) of biosolids or sewage sludge generated at the facility. - EQ0 = 0 - IN0_1 = GT 0 but LT 1 - IN0_289 = GT 0 but LT 290 MT/year - IN290_1499 = GE 290 but LT 1500 MT/year - IN1500_14999 = GE 1500 but LT 15,000 - GE15000 = GE 15,000
  --p-bio-mgmt-prctce-type: string # The unique code that identifies the type of biosolids or sewage sludge management practice (e.g., land application, surface disposal, incineration) used by the facility. The facility will separately report the management practice for each biosolids or sewage sludge form and pathogen class. This data element will also identify the management practices used by surface disposal site owners/operators (see 40 CFR 503.24): - BIN = Incineration - BLN = Land Application - BOT = Other Management Practice - BSD = Surface Disposal
  --p-bio-mgmt-prctce-stype: string # This is the code indicating additional detail about the type of Management Practice used for a volume of Biosolids or Sewage Sludge: - ADV = Advanced Alkaline Stabilized Biosolids Distribution & Marketing - AGR = Agricultural Land Application - COM = Distribution and Marketing - Compost - DEE = Deep-well Injection Disposal - DIS = Disposal in a Municipal Landfill (under 40 CFR 258) - DMO = Distribution and Marketing - Other - HEA = Heat Dried Biosolids Distribution & Marketing - OTL = Other Land Application Management Practice Detail - OTO = Other Management Practice Detail - RSA = Reclamation Site Application - SEN = Sent to Cement Kiln for Use as Alternative Energy - STO = Storage - UIC = Use in Construction - UPS = Used in Production of Syngas - USE = Use as Daily Cover for Municipal Landfill (under 40 CFR 258)
  --p-bio-mgmt-prctce-handler: string # This is the code indicating the type of Biosolids or Sewage Sludge handlers/preparers. - OWN = Owner or Operator - OFF = Off-Site Third-Party Handler or Preparer
  --p-bio-mgmt-container: string # The code that identifies the nature of each biosolids and sewage sludge material generated by the facility in terms of whether the material is a biosolid or sewage sludge and whether the material is ultimately conveyed off-site in bulk or in bags. The facility separately reports the form for each biosolids or sewage sludge management practice or practices used by the facility and pathogen class: - BUL = Bulk - BAG = Bag or Container
  --p-bio-mgmt-pathogen: string # This code identifies the pathogen class [e.g., Class A, Class B, Not Applicable (Incineration)] for biosolids or sewage sludge generated by the facility. The facility will separately report the pathogen class for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form. It also is used to filter applicable Pathogen Reduction and Vector Attraction Reduction Options as well as Land Application Management Practice Deficiencies. Only reqired for some of the mgmt. practice types: - AAA = Class A - AEQ = Class A EQ (sale/give away) - BBB = Class B - NAP = Not Applicable (Incineration)
  --p-bio-mgmt-pathred: string # This is the description of the option used by the facility to control pathogen for a Biosolids Management Practice: - A1 = Class A - Alternative 1: Time/Temperature - A2 = Class A - Alternative 2: pH/Temperature/Percent Solids - A3 = Class A - Alternative 3: Test Enteric Viruses and Helminth ova; Operating Parameters - A4 = Class A - Alternative 4: Test Enteric Viruses and Helminth ova; No New Solids - A51 = Class A - Alternative 5: PFRP 1: Composting - A52 = Class A - Alternative 5: PFRP 2: Heat Drying - A53 = Class A - Alternative 5: PFRP 3: Liquid heat treatment - A54 = Class A - Alternative 5: PFRP 4: Thermophilic Aerobic Digestion (ATAD) - A55 = Class A - Alternative 5 PFPR 5: Beta Ray Irradiation - A56 = Class A - Alternative 5 PFPR 6: Gamma Ray Irradiation - A57 = Class A - Alternative 5: PFRP 7: Pasteurization - A6 = Class A - Alternative 6: PFRP Equivalency - B1 = Class B - Alternative 1: Fecal Coliform Geometric Mean - B21 = Class B - Alternative 2 PSRP 1: Aerobic Digestion - B22 = Class B - Alternative 2 PSRP 2: Air Drying - B23 = Class B - Alternative 2 PSRP 3: Anaerobic Digestion - B24 = Class B - Alternative 2 PSRP 4: Composting - B25 = Class B - Alternative 2 PSRP 5: Lime Stabilization - B3 = Class B - Alternative 3: PSRP Equivalency - PH = pH Adjustment (Domestic Septage)
  --p-bio-mgmt-vector: string # The unique code that identifies the option used by the facility for vector attraction reduction. See a listing of these vector attraction reduction options at 40 CFR 503.33(b)(1) through (11). The facility will separately report the vector attraction reduction options for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form as well as by each biosolids or sewage sludge pathogen class: - VR1 = Option 1 - Volatile Solids Reduction - VR2 = Option 2 - Bench-Scale Volatile Solids Reduction (Anaerobic Bench Test) - VR3 = Option 3 - Bench-Scale Volatile Solids Reduction (Aerobic Bench Test w/ Percent Solids - 2% or Less) - VR4 = Option 4 - Specific Oxygen Uptake Rate - VR5 = Option 5 - Aerobic Processing (Thermophilic Aerobic Digestion/Composting) - VR6 = Option 6 - Alkaline Treatment - VR7 = Option 7 - Drying (Equal to or Greater than 75 Percent) - VR8 = Option 8 - Drying (Equal to or Greater than 90 Percent) - VR9 = Option 9 - Sewage Sludge Injection - V10 = Option 10 - Sewage Sludge Timely Incorporation into Land - V11 = Option 11 - Sewage Sludge Covered at the End of Each Operating Day
  --p-bio-mgmt-def-category: string # This is the code indicating the type of NPDES special regulatory program deficiency: - INC = Biosolids Incineration - LNA = Biosolids Land Application - LNB = Biosolids Land Application - Pathogen Class B - OTB = Biosolids Other Management Practice - SFD = Biosolids Surface Disposal
  --p-bio-mgmt-deficiencies: float # The number of times noncompliance was reported by the facility in the last 3 years. The results returned will include facilities whose number of reported noncompliance events is greater than or equal to the number entered.
  --p-bio-vio-code: string # The Biosolids Single Event Violation Code. Enter one or mode codes.
  --p-bio-current-vio: string@p-bio-current-vio-completer # Indicator of whether the facility is currently in violation for biosolids under the Clean Water Act, in the 12th or 13th quarter: - Y = Yes - N = No
  --p-bio-qtrs-in-vio: float # The number of quarters, in the last three years, where the facility was in violation for a biosolids violation type. The results returned will include facilities whose number of quarters with violations is greater than or equal to the number entered.
  --p-bio-rpt-year: string # The last year that the permittee submitted an annual Biosolids report. Valid values are NONE and any year greater or equal to 2016.
  --p-bio-vio-last-year: string@p-bio-vio-last-year-completer # Identifies if a biosolids violation has occured in the last year. Valid values are Y and N.
  --p-msgp-rpt-year: string # The last year that a MSGP report was submitted for the permit. Valid values are "NONE" and any year Greater or Eqal to 2015.
  --p-vio-last-year: string@p-vio-last-year-completer # Identifies if a permit violation has occured in the last year. Valid values are Y and N.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-e90-count: float # Number of E90 Exceedances. Identifies water permits with a number of E90 (Effluient Exceedances) >= the value provided for the last number of years provided by the p_e90_years value.
  --p-e90-years: float # Number of years for the p_e90_count search. Identified the past number of years to be used for the p_e90_count search.
  --p-psc: string # Point Source Category.
]: any -> record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string, Version: string, VioLast4QRows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cwa_rest_services.get_facilities")
  let req_body = {"output": $output, "p_fn": $p_fn, "p_sa": $p_sa, "p_sa1": $p_sa1, "p_ct": $p_ct, "p_co": $p_co, "p_fips": $p_fips, "p_st": $p_st, "p_zip": $p_zip, "p_frs": $p_frs, "p_reg": $p_reg, "p_sic": $p_sic, "p_ncs": $p_ncs, "p_pen": $p_pen, "p_c1lat": $p_c1lat, "p_c1lon": $p_c1lon, "p_c2lat": $p_c2lat, "p_c2lon": $p_c2lon, "p_usmex": $p_usmex, "p_sic2": $p_sic2, "p_sic4": $p_sic4, "p_fa": $p_fa, "p_ff": $p_ff, "p_act": $p_act, "p_maj": $p_maj, "p_mact": $p_mact, "p_fea": $p_fea, "p_feay": $p_feay, "p_feaa": $p_feaa, "p_iea": $p_iea, "p_ieay": $p_ieay, "p_ieaa": $p_ieaa, "p_qiv": $p_qiv, "p_iv": $p_iv, "p_impw": $p_impw, "p_imp_cau_grp": $p_imp_cau_grp, "p_imp_pol": $p_imp_pol, "p_trep": $p_trep, "p_pm": $p_pm, "p_pd": $p_pd, "p_ico": $p_ico, "p_huc": $p_huc, "p_pid": $p_pid, "p_med": $p_med, "p_ysl": $p_ysl, "p_ysly": $p_ysly, "p_ysla": $p_ysla, "p_qs": $p_qs, "p_sfs": $p_sfs, "p_tribeid": $p_tribeid, "p_tribename": $p_tribename, "p_tribedist": $p_tribedist, "p_pstat": $p_pstat, "p_ptype": $p_ptype, "p_pcomp": $p_pcomp, "p_plimits": $p_plimits, "p_pcss": $p_pcss, "p_pexp": $p_pexp, "p_owop": $p_owop, "p_ipfti": $p_ipfti, "p_agoo": $p_agoo, "p_idt1": $p_idt1, "p_idt2": $p_idt2, "p_pityp": $p_pityp, "p_pfead1": $p_pfead1, "p_pfead2": $p_pfead2, "p_pfeat": $p_pfeat, "p_pccs": $p_pccs, "p_pexcd": $p_pexcd, "p_psncq": $p_psncq, "p_pctrack": $p_pctrack, "p_dwd": $p_dwd, "p_pt": $p_pt, "p_pdwdist": $p_pdwdist, "p_pswdpc": $p_pswdpc, "p_pswdmp": $p_pswdmp, "p_pswpol": $p_pswpol, "p_pswcas": $p_pswcas, "p_pswparam": $p_pswparam, "p_pswvio": $p_pswvio, "p_wbd": $p_wbd, "p_radwbd": $p_radwbd, "p_frswbd": $p_frswbd, "p_fntype": $p_fntype, "p_pidall": $p_pidall, "p_months_last_dmr": $p_months_last_dmr, "p_last_dmr_within": $p_last_dmr_within, "p_indsw": $p_indsw, "p_msgp_ptype": $p_msgp_ptype, "p_mon_type": $p_mon_type, "p_iagency": $p_iagency, "p_permitting_agency": $p_permitting_agency, "p_isws": $p_isws, "p_iswss": $p_iswss, "p_iswssID": $p_iswss_id, "p_ds1": $p_ds1, "p_ds2": $p_ds2, "p_da1": $p_da1, "p_da2": $p_da2, "p_MS4": $p_ms4, "p_ooFN": $p_oo_fn, "p_ooFNtype": $p_oo_f_ntype, "p_ooSA": $p_oo_sa, "p_ooSA1": $p_oo_sa1, "p_ooCt": $p_oo_ct, "p_ooSt": $p_oo_st, "p_ooZip": $p_oo_zip, "p_fac_ico": $p_fac_ico, "p_icoo": $p_icoo, "p_fac_icos": $p_fac_icos, "p_ejscreen": $p_ejscreen, "p_alrexceed": $p_alrexceed, "p_limit_addr": $p_limit_addr, "p_lat": $p_lat, "p_long": $p_long, "p_radius": $p_radius, "p_ejscreen_over80cnt": $p_ejscreen_over80cnt, "p_bio_flag": $p_bio_flag, "p_bio_fac_type": $p_bio_fac_type, "p_bio_trtmnt_procs": $p_bio_trtmnt_procs, "p_bio_analy_method_catgry": $p_bio_analy_method_catgry, "p_bio_total_volume_amt": $p_bio_total_volume_amt, "p_bio_mgmt_prctce_type": $p_bio_mgmt_prctce_type, "p_bio_mgmt_prctce_stype": $p_bio_mgmt_prctce_stype, "p_bio_mgmt_prctce_handler": $p_bio_mgmt_prctce_handler, "p_bio_mgmt_container": $p_bio_mgmt_container, "p_bio_mgmt_pathogen": $p_bio_mgmt_pathogen, "p_bio_mgmt_pathred": $p_bio_mgmt_pathred, "p_bio_mgmt_vector": $p_bio_mgmt_vector, "p_bio_mgmt_def_category": $p_bio_mgmt_def_category, "p_bio_mgmt_deficiencies": $p_bio_mgmt_deficiencies, "p_bio_vio_code": $p_bio_vio_code, "p_bio_current_vio": $p_bio_current_vio, "p_bio_qtrs_in_vio": $p_bio_qtrs_in_vio, "p_bio_rpt_year": $p_bio_rpt_year, "p_bio_vio_last_year": $p_bio_vio_last_year, "p_msgp_rpt_year": $p_msgp_rpt_year, "p_vio_last_year": $p_vio_last_year, "queryset": $queryset, "responseset": $responseset, "tablelist": $tablelist, "maplist": $maplist, "summarylist": $summarylist, "callback": $callback, "qcolumns": $qcolumns, "p_e90_count": $p_e90_count, "p_e90_years": $p_e90_years, "p_psc": $p_psc} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Clean Water Act (CWA) Facility Enhanced Search Service
#
# GET /cwa_rest_services.get_facility_info
export def "cwa-rest-services-get-facility-info get" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language. - CSV = Facility results formatted as comma delimited file download. - GEOJSON = Facility results formatted as GeoJSON feature collection. - GEOJSONP = Facility results formatted as GeoJSON feature collection with Padding. - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  --p-fn: string # Facility Name Filter. Enter one or more case-insensitive facility names to filter results. Provide multiple values as a comma-delimited list. See p_fntype for additional modifiers.
  --p-sa: string # Facility street address. Enter a complete or partial street address.
  --p-sa1: string # Facility street address. Enter a complete or partial street address. Note that p_sa1 is culmulative with p_sa.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --xmin: float # Minimum longitude value in decimal degrees.
  --ymin: float # Minimum latitude value in decimal degrees.
  --xmax: float # Maximum longitude value in decimal degrees.
  --ymax: float # Maximum latitude value in decimal degrees.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-ff: string@p-ff-completer # Federal Facility Indicator Flag. Enter Y to restrict searches to federal facilities.
  --p-act: string # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits. A Y will select ICIS NPDES permits with a status of effective, continued, or expired.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-iv: string # Facility has a violation status of 'In Viol' during any of the selected quarters. Range: Fiscal Year 2020 Quarter 2 to Fiscal Year 2017 Quarter 2 Multiple values are comma delimited. |||||| Fiscal Years |||||| - FY2020 or FY20 or 2020 or 20 - FY2019 or FY19 or 2019 or 19 - FY2018 or FY18 or 2018 or 18 - FY2017 or FY17 or 2017 or 17 ||||| Fiscal Quarters ||||| - FY2020Q2 or FY20Q2 or 20202 or 202 or 13 - FY2020Q1 or FY20Q1 or 20201 or 201 or 12 - FY2019Q4 or FY19Q4 or 20194 or 194 or 11 - FY2019Q3 or FY19Q3 or 20193 or 193 or 10 - FY2019Q2 or FY19Q2 or 20192 or 192 or 9 - FY2019Q1 or FY19Q1 or 20191 or 191 or 8 - FY2018Q4 or FY18Q4 or 20184 or 184 or 7 - FY2018Q3 or FY18Q3 or 20183 or 183 or 6 - FY2018Q2 or FY18Q2 or 20182 or 182 or 5 - FY2018Q1 or FY18Q1 or 20181 or 181 or 4 - FY2017Q4 or FY17Q4 or 20174 or 174 or 3 - FY2017Q3 or FY17Q3 or 20173 or 173 or 2 - FY2017Q2 or FY17Q2 or 20172 or 172 or 1
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-imp-pol: string@p-imp-pol-completer # Facility is discharging pollutants that are potentially contributing to the impairment of local waterbodies according to the ATTAINS database.
  --p-imp-cau-grp: string@p-imp-cau-grp-completer # Facility is discharging a pollutant group causing a waterbody to be impaired. Enter 1 through 34 (the internal number of the pollutant group); or enter a partial name such as Dioxin,Temp,tUrBidity.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - ALL = Air and RCRA and Water
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-pstat: string # Permit Status Filter. Enter one or more of the following codes. Provide multiple values as a comma-delimited list. - EFF = Effective - EXP = Expired - PND = Pending - TRM = Terminated - RET = Retired - NON = Not Needed - ADC = Admin Continued
  --p-ptype: string # Permit Type Filter. Enter one or more code values to filter results. Provide multiple values as a comma-delimited list. - NPD = NPDES Individual Permit - NGP = NPDES Master General Permit - GPC = General Permit Covered Facility - SNN = State Issued Master General Permit (Non-NPDES) - IIU = Individual IU Permit (Non-NPDES) - SIN = Individual State Issued Permit (Non-NPDES) - APR = Associated Permit Record - UFT = Unpermitted Facility
  --p-pcomp: string # Permit Component Code Filter. Enter one or more codes to filter results. Provide multiple values as a comma-delimited list. - PRE = Pretreatment - CAF = CAFO - CSO = CSO - POT = POTW - BIO = Biosolids - SWS = Storm Water Small MS4s - SWM = Storm Water Medium/Large MS4s - SWI = Storm Water Industrial - SWC = Storm Water Construction
  --p-plimits: string@p-plimits-completer # Permit Limits Present Flag. Enter Y to limit results to facilities have present permit limits.
  --p-pcss: string@p-pcss-completer # Combined Sewer Systems Outflows Limiter. Enter one of the following to limit results to facilities having the given count of CSS outflows. - ALL = returns all facilities, regardless of the number of outflows. - GE1 = returns facilities with one or more outflows. - GE10 = returns facilities with ten or more outflows. - GE50 = returns facilities with fifty or more outflows.
  --p-pexp: string@p-pexp-completer # Permit Expired or Administratively Continued Limiter. Enter one of the following values to filter results. - EXP = limit results to facilities with permits expired or administratively continued. - EXPLE1YR = limit resuls to facilities with permits expired administratively continued within the past year. - EXPGT1YR = limit resuls to facilities with permits expired administratively continued more than a year ago.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following values to restrict results. - Federal = Federal facilities regulated under the NPDES program. - POTW = Publicly owned treatment works. Treatment works that are owned by a State, Tribe, or municipality. - Non-POTW = Non-publicly owned treatment works. Often referred to as "non-municipals" or "industrials".
  --p-ipfti: string
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type Code. See ICIS Compliance Monitor Types lookup serivce for a list of available codes and descriptions.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-pccs: string # Current Compliance Status: ||||||||||||||||||||||||||| Significant Noncompliance (SNC) ||||||||||||||||||||||||||| - SNC = E, S, X, T, D - E�= E(EffViol) - S�= S(CSchVio) - X = X(EffNMth) - T = T(CSchRpt) - D�= D(DMR NR) ||||||||||||||||||||||||||| Noncompliance (NC) ||||||||||||||||||||||||||| - NC = N, V - N�= N(RptViol) - V�= V(NonRNCV) ||||||||||||||||||||||||||| New Violations (PQV) ||||||||||||||||||||||||||| - PQV = New Violations (13th Quarter) ||||||||||||||||||||||||||| No Violations (NV) ||||||||||||||||||||||||||| - NV = R, P, M, U, W , Blank, and No New Violations (no PQV) - R�= R(Resolvd) - P�= P(ResPend) - M�= C(Manual) - U = U(N/A) - W = W(N/A) - Blank = (null) May contain multiple comma-separated values.
  --p-pexcd: string@p-pexcd-completer # 3-Year Effluent Exceedances Limiter. Enter a value to restrict results to facilities with the given amount of exceedances in the past 3 years. - 0 = facilities with no exceedances - GE0 = facilities with one or more exceedances - GE10 = facilities with ten or more exceedances - GE50 = facilities with fifty or more exceedances - GE100 = facilities with one hundred or more exceedances
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-pt: string@p-pt-completer # POTW Transfers. Pounds of toxic chemicals transferred to a Publicly Operated Treatment Works (POTW) as reported to the Toxics Release Inventory.
  --p-pdwdist: string@p-pdwdist-completer # Distance (in miles) to downstream drinking water intake.
  --p-pswdpc: string # Pollutant Category Code: Values: WTR for Water, AIR for Air
  --p-pswdmp: string@p-pswdmp-completer # Used to determine limit begin and end dates for surface water discharges. Number represents years from current date.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswcas: string # CAS numbers for surface water discharges. May contain multiple comma-separated values.
  --p-pswparam: string # Parameter codes for surface water discharges. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-radwbd: string # 2-, 4-, 6-, 8-, 10-, or 12 character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Will search against WBD values otained by "reach indexing" NPDES permits against the medium resolution National Hydrography Dataset.
  --p-frswbd: string # Works exactly the same as the p_wbd parameter. 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-months-last-dmr: float # The number of months since the last Discharge Monitoring Report has been submitted.
  --p-last-dmr-within: string@p-last-dmr-within-completer # W value returns facilities that have submitted DMRs within the number of months specified by p_months_last_dmr. An N value returns facilities that have not submitted a DMR within the specified number of months.
  --p-indsw: string@p-indsw-completer # Industrial Stormwater Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-msgp-ptype: string@p-msgp-ptype-completer # Multi-Sector General Purpose Permit Type. Enter a value to filter results by MSGP Permit Type. - NOI = Notice of Intent - NOE = No Exposure Certification
  --p-mon-type: string@p-mon-type-completer # For use with the Industrial Stormwater search only. Valid values are BENCHGS fro Benchmark (Alert Limit) G2 Ore, BENCH for Benchmark (Alert Limit), and ELG fro Effluent Limitation Guidelines(ELG)(Effluent Limit).
  --p-iagency: string # Issuing Agency Limiter. Enter a single value to filter results by the issuing agency, e.g. "State" or "EPA".
  --p-permitting-agency: string
  --p-isws: string # Multi-Sector General Purpose Permit Subsector Individual Identifier. Enter a value to filter results.
  --p-iswss: string # Multi-Sector General Purpose Permit Subsector Group Code. Enter a value to filter results.
  --p-iswss-id: string # Multi-Sector General Purpose Permit Sector Code. Enter a value to filter results.
  --p-ds1: string # Submitted Date Filter Start. To filter by the date of submission, enter a start date here and an end date in the p_ds2 parameter. Both dates are required for filtering.
  --p-ds2: string # Submitted Date Filter End. To filter by the date of submission, enter an end date here and a start date in the p_ds1 parameter. Both dates are required for filtering.
  --p-da1: string # Active Date Filter Start. To filter by the active date, enter a start date here and an end date in the p_da2 parameter. Both dates are required for filtering.
  --p-da2: string # Active Date Filter End. To filter by the active date, enter an end date here and a start date in the p_da1 parameter. Both dates are required for filtering.
  --p-ms4: string@p-ms4-completer # Municipal Separate Storm Water Sewer (MS4) Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-oo-fn: string # Owner/Operator Name. Enter the owner/operator name of the facility.
  --p-oo-f-ntype: string@p-oo-f-ntype-completer # Owner/Operator Name Multiple Selection Evaluator.
  --p-oo-sa: string # Owner/Operator Address. Enter the address of the owner/operator of the facility.
  --p-oo-sa1: string # Owner/Operator Address Line 2. Enter the line 2 address of the owner/operator of the facility.
  --p-oo-ct: string # Owner/Operator City. Enter the city where the owner/operator of the facility is located.
  --p-oo-st: string # Owner/Operator State. Enter the standardized postal state code where the owner/operator of the facility is located.
  --p-oo-zip: string # Owner/Operator Zip Code. Enter the postal zip code where the owner/operator of the facility is located.
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-alrexceed: float # Alert Limits Exceedences Limiter. Enter a numeric value to restrict results to facilities having the given amount or more of alert limits exceedances.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --p-bio-flag: string # A Y value will select all biosolid-related permits.
  --p-bio-fac-type: string # The code indicating the reporting obligation reason: - POT = A POTW with a design flow rate equal to or greater than one million gallons per day - CLI = A Class I Sludge Management Facility as defined in 40 CFR 503.9 - PPL = A POTW that serves 10,000 people or more - OTH = Otherwise required to report (e.g., permit condition, enforcement action) - NOA = None of the above
  --p-bio-trtmnt-procs: string # The biosolids or sewage sludge treatment process or processes at the facility: - AER = Aerobic Digestion - AIR = Air Drying (or Sludge Drying Beds) - ANA = Anaerobic Digestion - COD = Beta Ray Irradiation - COM = Lower Temperature Composting - DEW = Pasteurization - DIS = Gamma Ray Irradiation - HEA = Heat Drying (e.g., Flash Dryer, Spray Dryer, Rotary Dryer) - HET = Heat Treatment (Liquid Sewage Sludge Heated to 356 Deg. F/180 Deg. C or Higher for 30 min.) - HTC = Higher Temperature Composting - MET = Methane or Biogas Capture and Recovery - OTH = Other Treatment Process - PRE = Preliminary Operations (e.g., Sludge Grinding, Degritting, Blending) - SLU = Sludge Lagoon - STA = Lime Stabilization - THE = Temporary Sludge Storage (Sewage Sludge Stored on Land 2 Years or Less, Not in Sewage Sludge Unit) - THI = Thickening (Gravity and/or Flotation Thickening, Centrifugation, Belt Filter Press, Vacuum Filter) - THM = Thermophilic Aerobic Digestion - UND = Long-Term Sludge Storage (Sewage Sludge Stored on Land 2 Years or More, not in Sewage Sludge Unit)"
  --p-bio-analy-method-catgry: string # The unique code for the category of the analytic methods used by the facility to analyze regulated parameters (including enteric viruses, fecal coliforms, helminth ova, and Salmonella sp.) at the facility: - PAT = Pathogens - MET = Metals - NIT = Nitrogen Compounds - OTH = Other Analytes
  --p-bio-total-volume-amt: string # Total annual amount (in dry metric tons) of biosolids or sewage sludge generated at the facility. - EQ0 = 0 - IN0_1 = GT 0 but LT 1 - IN0_289 = GT 0 but LT 290 MT/year - IN290_1499 = GE 290 but LT 1500 MT/year - IN1500_14999 = GE 1500 but LT 15,000 - GE15000 = GE 15,000
  --p-bio-mgmt-prctce-type: string # The unique code that identifies the type of biosolids or sewage sludge management practice (e.g., land application, surface disposal, incineration) used by the facility. The facility will separately report the management practice for each biosolids or sewage sludge form and pathogen class. This data element will also identify the management practices used by surface disposal site owners/operators (see 40 CFR 503.24): - BIN = Incineration - BLN = Land Application - BOT = Other Management Practice - BSD = Surface Disposal
  --p-bio-mgmt-prctce-stype: string # This is the code indicating additional detail about the type of Management Practice used for a volume of Biosolids or Sewage Sludge: - ADV = Advanced Alkaline Stabilized Biosolids Distribution & Marketing - AGR = Agricultural Land Application - COM = Distribution and Marketing - Compost - DEE = Deep-well Injection Disposal - DIS = Disposal in a Municipal Landfill (under 40 CFR 258) - DMO = Distribution and Marketing - Other - HEA = Heat Dried Biosolids Distribution & Marketing - OTL = Other Land Application Management Practice Detail - OTO = Other Management Practice Detail - RSA = Reclamation Site Application - SEN = Sent to Cement Kiln for Use as Alternative Energy - STO = Storage - UIC = Use in Construction - UPS = Used in Production of Syngas - USE = Use as Daily Cover for Municipal Landfill (under 40 CFR 258)
  --p-bio-mgmt-prctce-handler: string # This is the code indicating the type of Biosolids or Sewage Sludge handlers/preparers. - OWN = Owner or Operator - OFF = Off-Site Third-Party Handler or Preparer
  --p-bio-mgmt-container: string # The code that identifies the nature of each biosolids and sewage sludge material generated by the facility in terms of whether the material is a biosolid or sewage sludge and whether the material is ultimately conveyed off-site in bulk or in bags. The facility separately reports the form for each biosolids or sewage sludge management practice or practices used by the facility and pathogen class: - BUL = Bulk - BAG = Bag or Container
  --p-bio-mgmt-pathogen: string # This code identifies the pathogen class [e.g., Class A, Class B, Not Applicable (Incineration)] for biosolids or sewage sludge generated by the facility. The facility will separately report the pathogen class for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form. It also is used to filter applicable Pathogen Reduction and Vector Attraction Reduction Options as well as Land Application Management Practice Deficiencies. Only reqired for some of the mgmt. practice types: - AAA = Class A - AEQ = Class A EQ (sale/give away) - BBB = Class B - NAP = Not Applicable (Incineration)
  --p-bio-mgmt-pathred: string # This is the description of the option used by the facility to control pathogen for a Biosolids Management Practice: - A1 = Class A - Alternative 1: Time/Temperature - A2 = Class A - Alternative 2: pH/Temperature/Percent Solids - A3 = Class A - Alternative 3: Test Enteric Viruses and Helminth ova; Operating Parameters - A4 = Class A - Alternative 4: Test Enteric Viruses and Helminth ova; No New Solids - A51 = Class A - Alternative 5: PFRP 1: Composting - A52 = Class A - Alternative 5: PFRP 2: Heat Drying - A53 = Class A - Alternative 5: PFRP 3: Liquid heat treatment - A54 = Class A - Alternative 5: PFRP 4: Thermophilic Aerobic Digestion (ATAD) - A55 = Class A - Alternative 5 PFPR 5: Beta Ray Irradiation - A56 = Class A - Alternative 5 PFPR 6: Gamma Ray Irradiation - A57 = Class A - Alternative 5: PFRP 7: Pasteurization - A6 = Class A - Alternative 6: PFRP Equivalency - B1 = Class B - Alternative 1: Fecal Coliform Geometric Mean - B21 = Class B - Alternative 2 PSRP 1: Aerobic Digestion - B22 = Class B - Alternative 2 PSRP 2: Air Drying - B23 = Class B - Alternative 2 PSRP 3: Anaerobic Digestion - B24 = Class B - Alternative 2 PSRP 4: Composting - B25 = Class B - Alternative 2 PSRP 5: Lime Stabilization - B3 = Class B - Alternative 3: PSRP Equivalency - PH = pH Adjustment (Domestic Septage)
  --p-bio-mgmt-vector: string # The unique code that identifies the option used by the facility for vector attraction reduction. See a listing of these vector attraction reduction options at 40 CFR 503.33(b)(1) through (11). The facility will separately report the vector attraction reduction options for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form as well as by each biosolids or sewage sludge pathogen class: - VR1 = Option 1 - Volatile Solids Reduction - VR2 = Option 2 - Bench-Scale Volatile Solids Reduction (Anaerobic Bench Test) - VR3 = Option 3 - Bench-Scale Volatile Solids Reduction (Aerobic Bench Test w/ Percent Solids - 2% or Less) - VR4 = Option 4 - Specific Oxygen Uptake Rate - VR5 = Option 5 - Aerobic Processing (Thermophilic Aerobic Digestion/Composting) - VR6 = Option 6 - Alkaline Treatment - VR7 = Option 7 - Drying (Equal to or Greater than 75 Percent) - VR8 = Option 8 - Drying (Equal to or Greater than 90 Percent) - VR9 = Option 9 - Sewage Sludge Injection - V10 = Option 10 - Sewage Sludge Timely Incorporation into Land - V11 = Option 11 - Sewage Sludge Covered at the End of Each Operating Day
  --p-bio-mgmt-def-category: string # This is the code indicating the type of NPDES special regulatory program deficiency: - INC = Biosolids Incineration - LNA = Biosolids Land Application - LNB = Biosolids Land Application - Pathogen Class B - OTB = Biosolids Other Management Practice - SFD = Biosolids Surface Disposal
  --p-bio-mgmt-deficiencies: float # The number of times noncompliance was reported by the facility in the last 3 years. The results returned will include facilities whose number of reported noncompliance events is greater than or equal to the number entered.
  --p-bio-vio-code: string # The Biosolids Single Event Violation Code. Enter one or mode codes.
  --p-bio-current-vio: string@p-bio-current-vio-completer # Indicator of whether the facility is currently in violation for biosolids under the Clean Water Act, in the 12th or 13th quarter: - Y = Yes - N = No
  --p-bio-qtrs-in-vio: float # The number of quarters, in the last three years, where the facility was in violation for a biosolids violation type. The results returned will include facilities whose number of quarters with violations is greater than or equal to the number entered.
  --p-bio-rpt-year: string # The last year that the permittee submitted an annual Biosolids report. Valid values are NONE and any year greater or equal to 2016.
  --p-bio-vio-last-year: string@p-bio-vio-last-year-completer # Identifies if a biosolids violation has occured in the last year. Valid values are Y and N.
  --p-msgp-rpt-year: string # The last year that a MSGP report was submitted for the permit. Valid values are "NONE" and any year Greater or Eqal to 2015.
  --p-vio-last-year: string@p-vio-last-year-completer # Identifies if a permit violation has occured in the last year. Valid values are Y and N.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
  --p-e90-count: float # Number of E90 Exceedances. Identifies water permits with a number of E90 (Effluient Exceedances) >= the value provided for the last number of years provided by the p_e90_years value.
  --p-e90-years: float # Number of years for the p_e90_count search. Identified the past number of years to be used for the p_e90_count search.
  --p-psc: string # Point Source Category.
]: nothing -> record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string, VioLast4QRows: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_fn" $p_fn "scalar") (serialize-qp "p_sa" $p_sa "scalar") (serialize-qp "p_sa1" $p_sa1 "scalar") (serialize-qp "p_ct" $p_ct "scalar") (serialize-qp "p_co" $p_co "scalar") (serialize-qp "p_fips" $p_fips "scalar") (serialize-qp "p_st" $p_st "scalar") (serialize-qp "p_zip" $p_zip "scalar") (serialize-qp "p_frs" $p_frs "scalar") (serialize-qp "p_reg" $p_reg "scalar") (serialize-qp "p_sic" $p_sic "scalar") (serialize-qp "p_ncs" $p_ncs "scalar") (serialize-qp "p_pen" $p_pen "scalar") (serialize-qp "xmin" $xmin "scalar") (serialize-qp "ymin" $ymin "scalar") (serialize-qp "xmax" $xmax "scalar") (serialize-qp "ymax" $ymax "scalar") (serialize-qp "p_usmex" $p_usmex "scalar") (serialize-qp "p_sic2" $p_sic2 "scalar") (serialize-qp "p_sic4" $p_sic4 "scalar") (serialize-qp "p_fa" $p_fa "scalar") (serialize-qp "p_ff" $p_ff "scalar") (serialize-qp "p_act" $p_act "scalar") (serialize-qp "p_maj" $p_maj "scalar") (serialize-qp "p_mact" $p_mact "scalar") (serialize-qp "p_fea" $p_fea "scalar") (serialize-qp "p_feay" $p_feay "scalar") (serialize-qp "p_feaa" $p_feaa "scalar") (serialize-qp "p_iea" $p_iea "scalar") (serialize-qp "p_ieay" $p_ieay "scalar") (serialize-qp "p_ieaa" $p_ieaa "scalar") (serialize-qp "p_qiv" $p_qiv "scalar") (serialize-qp "p_iv" $p_iv "scalar") (serialize-qp "p_impw" $p_impw "scalar") (serialize-qp "p_imp_pol" $p_imp_pol "scalar") (serialize-qp "p_imp_cau_grp" $p_imp_cau_grp "scalar") (serialize-qp "p_trep" $p_trep "scalar") (serialize-qp "p_pm" $p_pm "scalar") (serialize-qp "p_pd" $p_pd "scalar") (serialize-qp "p_ico" $p_ico "scalar") (serialize-qp "p_huc" $p_huc "scalar") (serialize-qp "p_pid" $p_pid "scalar") (serialize-qp "p_med" $p_med "scalar") (serialize-qp "p_ysl" $p_ysl "scalar") (serialize-qp "p_ysly" $p_ysly "scalar") (serialize-qp "p_ysla" $p_ysla "scalar") (serialize-qp "p_qs" $p_qs "scalar") (serialize-qp "p_sfs" $p_sfs "scalar") (serialize-qp "p_tribeid" $p_tribeid "scalar") (serialize-qp "p_tribename" $p_tribename "scalar") (serialize-qp "p_tribedist" $p_tribedist "scalar") (serialize-qp "p_pstat" $p_pstat "scalar") (serialize-qp "p_ptype" $p_ptype "scalar") (serialize-qp "p_pcomp" $p_pcomp "scalar") (serialize-qp "p_plimits" $p_plimits "scalar") (serialize-qp "p_pcss" $p_pcss "scalar") (serialize-qp "p_pexp" $p_pexp "scalar") (serialize-qp "p_owop" $p_owop "scalar") (serialize-qp "p_ipfti" $p_ipfti "scalar") (serialize-qp "p_agoo" $p_agoo "scalar") (serialize-qp "p_idt1" $p_idt1 "scalar") (serialize-qp "p_idt2" $p_idt2 "scalar") (serialize-qp "p_pityp" $p_pityp "scalar") (serialize-qp "p_pfead1" $p_pfead1 "scalar") (serialize-qp "p_pfead2" $p_pfead2 "scalar") (serialize-qp "p_pfeat" $p_pfeat "scalar") (serialize-qp "p_pccs" $p_pccs "scalar") (serialize-qp "p_pexcd" $p_pexcd "scalar") (serialize-qp "p_psncq" $p_psncq "scalar") (serialize-qp "p_pctrack" $p_pctrack "scalar") (serialize-qp "p_dwd" $p_dwd "scalar") (serialize-qp "p_pt" $p_pt "scalar") (serialize-qp "p_pdwdist" $p_pdwdist "scalar") (serialize-qp "p_pswdpc" $p_pswdpc "scalar") (serialize-qp "p_pswdmp" $p_pswdmp "scalar") (serialize-qp "p_pswpol" $p_pswpol "scalar") (serialize-qp "p_pswcas" $p_pswcas "scalar") (serialize-qp "p_pswparam" $p_pswparam "scalar") (serialize-qp "p_pswvio" $p_pswvio "scalar") (serialize-qp "p_wbd" $p_wbd "scalar") (serialize-qp "p_radwbd" $p_radwbd "scalar") (serialize-qp "p_frswbd" $p_frswbd "scalar") (serialize-qp "p_fntype" $p_fntype "scalar") (serialize-qp "p_pidall" $p_pidall "scalar") (serialize-qp "p_months_last_dmr" $p_months_last_dmr "scalar") (serialize-qp "p_last_dmr_within" $p_last_dmr_within "scalar") (serialize-qp "p_indsw" $p_indsw "scalar") (serialize-qp "p_msgp_ptype" $p_msgp_ptype "scalar") (serialize-qp "p_mon_type" $p_mon_type "scalar") (serialize-qp "p_iagency" $p_iagency "scalar") (serialize-qp "p_permitting_agency" $p_permitting_agency "scalar") (serialize-qp "p_isws" $p_isws "scalar") (serialize-qp "p_iswss" $p_iswss "scalar") (serialize-qp "p_iswssID" $p_iswss_id "scalar") (serialize-qp "p_ds1" $p_ds1 "scalar") (serialize-qp "p_ds2" $p_ds2 "scalar") (serialize-qp "p_da1" $p_da1 "scalar") (serialize-qp "p_da2" $p_da2 "scalar") (serialize-qp "p_MS4" $p_ms4 "scalar") (serialize-qp "p_ooFN" $p_oo_fn "scalar") (serialize-qp "p_ooFNtype" $p_oo_f_ntype "scalar") (serialize-qp "p_ooSA" $p_oo_sa "scalar") (serialize-qp "p_ooSA1" $p_oo_sa1 "scalar") (serialize-qp "p_ooCt" $p_oo_ct "scalar") (serialize-qp "p_ooSt" $p_oo_st "scalar") (serialize-qp "p_ooZip" $p_oo_zip "scalar") (serialize-qp "p_fac_ico" $p_fac_ico "scalar") (serialize-qp "p_icoo" $p_icoo "scalar") (serialize-qp "p_fac_icos" $p_fac_icos "scalar") (serialize-qp "p_ejscreen" $p_ejscreen "scalar") (serialize-qp "p_alrexceed" $p_alrexceed "scalar") (serialize-qp "p_limit_addr" $p_limit_addr "scalar") (serialize-qp "p_lat" $p_lat "scalar") (serialize-qp "p_long" $p_long "scalar") (serialize-qp "p_radius" $p_radius "scalar") (serialize-qp "p_ejscreen_over80cnt" $p_ejscreen_over80cnt "scalar") (serialize-qp "p_bio_flag" $p_bio_flag "scalar") (serialize-qp "p_bio_fac_type" $p_bio_fac_type "scalar") (serialize-qp "p_bio_trtmnt_procs" $p_bio_trtmnt_procs "scalar") (serialize-qp "p_bio_analy_method_catgry" $p_bio_analy_method_catgry "scalar") (serialize-qp "p_bio_total_volume_amt" $p_bio_total_volume_amt "scalar") (serialize-qp "p_bio_mgmt_prctce_type" $p_bio_mgmt_prctce_type "scalar") (serialize-qp "p_bio_mgmt_prctce_stype" $p_bio_mgmt_prctce_stype "scalar") (serialize-qp "p_bio_mgmt_prctce_handler" $p_bio_mgmt_prctce_handler "scalar") (serialize-qp "p_bio_mgmt_container" $p_bio_mgmt_container "scalar") (serialize-qp "p_bio_mgmt_pathogen" $p_bio_mgmt_pathogen "scalar") (serialize-qp "p_bio_mgmt_pathred" $p_bio_mgmt_pathred "scalar") (serialize-qp "p_bio_mgmt_vector" $p_bio_mgmt_vector "scalar") (serialize-qp "p_bio_mgmt_def_category" $p_bio_mgmt_def_category "scalar") (serialize-qp "p_bio_mgmt_deficiencies" $p_bio_mgmt_deficiencies "scalar") (serialize-qp "p_bio_vio_code" $p_bio_vio_code "scalar") (serialize-qp "p_bio_current_vio" $p_bio_current_vio "scalar") (serialize-qp "p_bio_qtrs_in_vio" $p_bio_qtrs_in_vio "scalar") (serialize-qp "p_bio_rpt_year" $p_bio_rpt_year "scalar") (serialize-qp "p_bio_vio_last_year" $p_bio_vio_last_year "scalar") (serialize-qp "p_msgp_rpt_year" $p_msgp_rpt_year "scalar") (serialize-qp "p_vio_last_year" $p_vio_last_year "scalar") (serialize-qp "responseset" $responseset "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "qcolumns" $qcolumns "scalar") (serialize-qp "p_pretty_print" $p_pretty_print "scalar") (serialize-qp "p_e90_count" $p_e90_count "scalar") (serialize-qp "p_e90_years" $p_e90_years "scalar") (serialize-qp "p_psc" $p_psc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cwa_rest_services.get_facility_info" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "p_fn": $p_fn, "p_sa": $p_sa, "p_sa1": $p_sa1, "p_ct": $p_ct, "p_co": $p_co, "p_fips": $p_fips, "p_st": $p_st, "p_zip": $p_zip, "p_frs": $p_frs, "p_reg": $p_reg, "p_sic": $p_sic, "p_ncs": $p_ncs, "p_pen": $p_pen, "xmin": $xmin, "ymin": $ymin, "xmax": $xmax, "ymax": $ymax, "p_usmex": $p_usmex, "p_sic2": $p_sic2, "p_sic4": $p_sic4, "p_fa": $p_fa, "p_ff": $p_ff, "p_act": $p_act, "p_maj": $p_maj, "p_mact": $p_mact, "p_fea": $p_fea, "p_feay": $p_feay, "p_feaa": $p_feaa, "p_iea": $p_iea, "p_ieay": $p_ieay, "p_ieaa": $p_ieaa, "p_qiv": $p_qiv, "p_iv": $p_iv, "p_impw": $p_impw, "p_imp_pol": $p_imp_pol, "p_imp_cau_grp": $p_imp_cau_grp, "p_trep": $p_trep, "p_pm": $p_pm, "p_pd": $p_pd, "p_ico": $p_ico, "p_huc": $p_huc, "p_pid": $p_pid, "p_med": $p_med, "p_ysl": $p_ysl, "p_ysly": $p_ysly, "p_ysla": $p_ysla, "p_qs": $p_qs, "p_sfs": $p_sfs, "p_tribeid": $p_tribeid, "p_tribename": $p_tribename, "p_tribedist": $p_tribedist, "p_pstat": $p_pstat, "p_ptype": $p_ptype, "p_pcomp": $p_pcomp, "p_plimits": $p_plimits, "p_pcss": $p_pcss, "p_pexp": $p_pexp, "p_owop": $p_owop, "p_ipfti": $p_ipfti, "p_agoo": $p_agoo, "p_idt1": $p_idt1, "p_idt2": $p_idt2, "p_pityp": $p_pityp, "p_pfead1": $p_pfead1, "p_pfead2": $p_pfead2, "p_pfeat": $p_pfeat, "p_pccs": $p_pccs, "p_pexcd": $p_pexcd, "p_psncq": $p_psncq, "p_pctrack": $p_pctrack, "p_dwd": $p_dwd, "p_pt": $p_pt, "p_pdwdist": $p_pdwdist, "p_pswdpc": $p_pswdpc, "p_pswdmp": $p_pswdmp, "p_pswpol": $p_pswpol, "p_pswcas": $p_pswcas, "p_pswparam": $p_pswparam, "p_pswvio": $p_pswvio, "p_wbd": $p_wbd, "p_radwbd": $p_radwbd, "p_frswbd": $p_frswbd, "p_fntype": $p_fntype, "p_pidall": $p_pidall, "p_months_last_dmr": $p_months_last_dmr, "p_last_dmr_within": $p_last_dmr_within, "p_indsw": $p_indsw, "p_msgp_ptype": $p_msgp_ptype, "p_mon_type": $p_mon_type, "p_iagency": $p_iagency, "p_permitting_agency": $p_permitting_agency, "p_isws": $p_isws, "p_iswss": $p_iswss, "p_iswssID": $p_iswss_id, "p_ds1": $p_ds1, "p_ds2": $p_ds2, "p_da1": $p_da1, "p_da2": $p_da2, "p_MS4": $p_ms4, "p_ooFN": $p_oo_fn, "p_ooFNtype": $p_oo_f_ntype, "p_ooSA": $p_oo_sa, "p_ooSA1": $p_oo_sa1, "p_ooCt": $p_oo_ct, "p_ooSt": $p_oo_st, "p_ooZip": $p_oo_zip, "p_fac_ico": $p_fac_ico, "p_icoo": $p_icoo, "p_fac_icos": $p_fac_icos, "p_ejscreen": $p_ejscreen, "p_alrexceed": $p_alrexceed, "p_limit_addr": $p_limit_addr, "p_lat": $p_lat, "p_long": $p_long, "p_radius": $p_radius, "p_ejscreen_over80cnt": $p_ejscreen_over80cnt, "p_bio_flag": $p_bio_flag, "p_bio_fac_type": $p_bio_fac_type, "p_bio_trtmnt_procs": $p_bio_trtmnt_procs, "p_bio_analy_method_catgry": $p_bio_analy_method_catgry, "p_bio_total_volume_amt": $p_bio_total_volume_amt, "p_bio_mgmt_prctce_type": $p_bio_mgmt_prctce_type, "p_bio_mgmt_prctce_stype": $p_bio_mgmt_prctce_stype, "p_bio_mgmt_prctce_handler": $p_bio_mgmt_prctce_handler, "p_bio_mgmt_container": $p_bio_mgmt_container, "p_bio_mgmt_pathogen": $p_bio_mgmt_pathogen, "p_bio_mgmt_pathred": $p_bio_mgmt_pathred, "p_bio_mgmt_vector": $p_bio_mgmt_vector, "p_bio_mgmt_def_category": $p_bio_mgmt_def_category, "p_bio_mgmt_deficiencies": $p_bio_mgmt_deficiencies, "p_bio_vio_code": $p_bio_vio_code, "p_bio_current_vio": $p_bio_current_vio, "p_bio_qtrs_in_vio": $p_bio_qtrs_in_vio, "p_bio_rpt_year": $p_bio_rpt_year, "p_bio_vio_last_year": $p_bio_vio_last_year, "p_msgp_rpt_year": $p_msgp_rpt_year, "p_vio_last_year": $p_vio_last_year, "responseset": $responseset, "callback": $callback, "qcolumns": $qcolumns, "p_pretty_print": $p_pretty_print, "p_e90_count": $p_e90_count, "p_e90_years": $p_e90_years, "p_psc": $p_psc} | compact), body: null}
}

# Clean Water Act (CWA) Facility Enhanced Search Service
#
# POST /cwa_rest_services.get_facility_info
export def "cwa-rest-services-get-facility-info create" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding. - XML = Data model formatted as Extensible Markup Language. - CSV = Facility results formatted as comma delimited file download. - GEOJSON = Facility results formatted as GeoJSON feature collection. - GEOJSONP = Facility results formatted as GeoJSON feature collection with Padding. - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  --p-fn: string # Facility Name Filter. Enter one or more case-insensitive facility names to filter results. Provide multiple values as a comma-delimited list. See p_fntype for additional modifiers.
  --p-sa: string # Facility street address. Enter a complete or partial street address.
  --p-sa1: string # Facility street address. Enter a complete or partial street address. Note that p_sa1 is culmulative with p_sa.
  --p-ct: string # Facility City Filter. Enter a single case-insensitive city name to filter results.
  --p-co: string # Facility County Filter. Provide a single county name in combination with a state value provided via p_st.
  --p-fips: string # FIPS Code Filter. Enter a single 5-character Federal Information Processing Standards (FIPS) state + county value to restrict results. E.g. to limit results to Kenosha County, Wisconsin, use 55059.
  --p-st: string # Facility State and State-Equivalent Filter. Provide one or more USPS postal abbreviations for states and state-equivalents to filter results. Provide multiple values as a comma-delimited list.
  --p-zip: string # 5-Digit ZIP Code Filter. Provide one or more 5-digit postal zip codes to filter results. May contain multiple comma-separated values.
  --p-frs: string # Facility Registry Service ID Filter. Enter a single 12-digit FRS identifier to filter results.
  --p-reg: string@p-reg-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter. Enter a single 4-digit SIC Code to filter results. If more complex filtering is required, use p_sic2 and p_sic4.
  --p-ncs: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes. Digits less than six will match to all codes beginning with the provided values.
  --p-pen: string # Last Penality Date Qualifier Filter. Enter one of the following: - NEVER = No Penalties - ANY = Any Penalty - LEXX = Less than or equal to XX months. Provide a number in place of XX, e.g. "LE5" for a facility with a penalty within previous 5 months. - GTXX = Greater than XX months. Provide a number in place of XX, eg. GT12, for a facility with the last penalty greater than 12 months ago.
  --xmin: float # Minimum longitude value in decimal degrees.
  --ymin: float # Minimum latitude value in decimal degrees.
  --xmax: float # Maximum longitude value in decimal degrees.
  --ymax: float # Maximum latitude value in decimal degrees.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag. Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-sic2: string # Standard Industrial Classification (SIC) Code Filter Alternate 2. Enter a wild-card search against SIC codes. A final wild-card is always present allowing "22" to match all SIC codes beginning with 22. Use the "%" character within strings to match any SIC values with the pattern. For example, "2%21" matches 2021, 2121, 2221, etc.
  --p-sic4: string # Standard Industrial Classification (SIC) Code Filter Alternate 3. Enter the first 2, 3 or 4 SIC code digits to filter results to facilities having those code prefixes. As this alternative does not utilize an index, p_sic2 will generally be quicker.
  --p-fa: string # Federal Agency. 1 character or 5-character values; may contain multiple comma-separated values. ALL will retrieve all facilities where the federal agency code is not null. Use the Federal Agencies lookup service to obtain a list of values.
  --p-ff: string@p-ff-completer # Federal Facility Indicator Flag. Enter Y to restrict searches to federal facilities.
  --p-act: string # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits. A Y will select ICIS NPDES permits with a status of effective, continued, or expired.
  --p-maj: string@p-maj-completer # Major Facility Flag. Enter Y to restrict results to Major facilities only.
  --p-mact: string # CAA Maximum Achievable Control Technology (MACT) Subpart codes (alpha ID between 1 and 7 characters) applicable to the facility.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-iv: string # Facility has a violation status of 'In Viol' during any of the selected quarters. Range: Fiscal Year 2020 Quarter 2 to Fiscal Year 2017 Quarter 2 Multiple values are comma delimited. |||||| Fiscal Years |||||| - FY2020 or FY20 or 2020 or 20 - FY2019 or FY19 or 2019 or 19 - FY2018 or FY18 or 2018 or 18 - FY2017 or FY17 or 2017 or 17 ||||| Fiscal Quarters ||||| - FY2020Q2 or FY20Q2 or 20202 or 202 or 13 - FY2020Q1 or FY20Q1 or 20201 or 201 or 12 - FY2019Q4 or FY19Q4 or 20194 or 194 or 11 - FY2019Q3 or FY19Q3 or 20193 or 193 or 10 - FY2019Q2 or FY19Q2 or 20192 or 192 or 9 - FY2019Q1 or FY19Q1 or 20191 or 191 or 8 - FY2018Q4 or FY18Q4 or 20184 or 184 or 7 - FY2018Q3 or FY18Q3 or 20183 or 183 or 6 - FY2018Q2 or FY18Q2 or 20182 or 182 or 5 - FY2018Q1 or FY18Q1 or 20181 or 181 or 4 - FY2017Q4 or FY17Q4 or 20174 or 174 or 3 - FY2017Q3 or FY17Q3 or 20173 or 173 or 2 - FY2017Q2 or FY17Q2 or 20172 or 172 or 1
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-imp-pol: string@p-imp-pol-completer # Facility is discharging pollutants that are potentially contributing to the impairment of local waterbodies according to the ATTAINS database.
  --p-imp-cau-grp: string@p-imp-cau-grp-completer # Facility is discharging a pollutant group causing a waterbody to be impaired. Enter 1 through 34 (the internal number of the pollutant group); or enter a partial name such as Dioxin,Temp,tUrBidity.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - ALL = Air and RCRA and Water
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-pstat: string # Permit Status Filter. Enter one or more of the following codes. Provide multiple values as a comma-delimited list. - EFF = Effective - EXP = Expired - PND = Pending - TRM = Terminated - RET = Retired - NON = Not Needed - ADC = Admin Continued
  --p-ptype: string # Permit Type Filter. Enter one or more code values to filter results. Provide multiple values as a comma-delimited list. - NPD = NPDES Individual Permit - NGP = NPDES Master General Permit - GPC = General Permit Covered Facility - SNN = State Issued Master General Permit (Non-NPDES) - IIU = Individual IU Permit (Non-NPDES) - SIN = Individual State Issued Permit (Non-NPDES) - APR = Associated Permit Record - UFT = Unpermitted Facility
  --p-pcomp: string # Permit Component Code Filter. Enter one or more codes to filter results. Provide multiple values as a comma-delimited list. - PRE = Pretreatment - CAF = CAFO - CSO = CSO - POT = POTW - BIO = Biosolids - SWS = Storm Water Small MS4s - SWM = Storm Water Medium/Large MS4s - SWI = Storm Water Industrial - SWC = Storm Water Construction
  --p-plimits: string@p-plimits-completer # Permit Limits Present Flag. Enter Y to limit results to facilities have present permit limits.
  --p-pcss: string@p-pcss-completer # Combined Sewer Systems Outflows Limiter. Enter one of the following to limit results to facilities having the given count of CSS outflows. - ALL = returns all facilities, regardless of the number of outflows. - GE1 = returns facilities with one or more outflows. - GE10 = returns facilities with ten or more outflows. - GE50 = returns facilities with fifty or more outflows.
  --p-pexp: string@p-pexp-completer # Permit Expired or Administratively Continued Limiter. Enter one of the following values to filter results. - EXP = limit results to facilities with permits expired or administratively continued. - EXPLE1YR = limit resuls to facilities with permits expired administratively continued within the past year. - EXPGT1YR = limit resuls to facilities with permits expired administratively continued more than a year ago.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following values to restrict results. - Federal = Federal facilities regulated under the NPDES program. - POTW = Publicly owned treatment works. Treatment works that are owned by a State, Tribe, or municipality. - Non-POTW = Non-publicly owned treatment works. Often referred to as "non-municipals" or "industrials".
  --p-ipfti: string
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type Code. See ICIS Compliance Monitor Types lookup serivce for a list of available codes and descriptions.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-pccs: string # Current Compliance Status: ||||||||||||||||||||||||||| Significant Noncompliance (SNC) ||||||||||||||||||||||||||| - SNC = E, S, X, T, D - E�= E(EffViol) - S�= S(CSchVio) - X = X(EffNMth) - T = T(CSchRpt) - D�= D(DMR NR) ||||||||||||||||||||||||||| Noncompliance (NC) ||||||||||||||||||||||||||| - NC = N, V - N�= N(RptViol) - V�= V(NonRNCV) ||||||||||||||||||||||||||| New Violations (PQV) ||||||||||||||||||||||||||| - PQV = New Violations (13th Quarter) ||||||||||||||||||||||||||| No Violations (NV) ||||||||||||||||||||||||||| - NV = R, P, M, U, W , Blank, and No New Violations (no PQV) - R�= R(Resolvd) - P�= P(ResPend) - M�= C(Manual) - U = U(N/A) - W = W(N/A) - Blank = (null) May contain multiple comma-separated values.
  --p-pexcd: string@p-pexcd-completer # 3-Year Effluent Exceedances Limiter. Enter a value to restrict results to facilities with the given amount of exceedances in the past 3 years. - 0 = facilities with no exceedances - GE0 = facilities with one or more exceedances - GE10 = facilities with ten or more exceedances - GE50 = facilities with fifty or more exceedances - GE100 = facilities with one hundred or more exceedances
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-pctrack: string@p-pctrack-completer # Compliance Tracking Limiter. Provide a keyword to indicate the extent to which data is being entered and effluent exceedances are being identified. - Off - Partial - On
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-pt: string@p-pt-completer # POTW Transfers. Pounds of toxic chemicals transferred to a Publicly Operated Treatment Works (POTW) as reported to the Toxics Release Inventory.
  --p-pdwdist: string@p-pdwdist-completer # Distance (in miles) to downstream drinking water intake.
  --p-pswdpc: string # Pollutant Category Code: Values: WTR for Water, AIR for Air
  --p-pswdmp: string@p-pswdmp-completer # Used to determine limit begin and end dates for surface water discharges. Number represents years from current date.
  --p-pswpol: string # For CWA, pollutant names for surface water discharges. for Drinking Water, SDWIS Violation contaminant codes for unaddressed violations that have occurred in the last 3 years. May contain multiple comma-separated values.
  --p-pswcas: string # CAS numbers for surface water discharges. May contain multiple comma-separated values.
  --p-pswparam: string # Parameter codes for surface water discharges. May contain multiple comma-separated values.
  --p-pswvio: string@p-pswvio-completer # Used in conjuction with parameters p_pswpol and p_pswparam, indicates whether search should only include pollutants with violations.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-radwbd: string # 2-, 4-, 6-, 8-, 10-, or 12 character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Will search against WBD values otained by "reach indexing" NPDES permits against the medium resolution National Hydrography Dataset.
  --p-frswbd: string # Works exactly the same as the p_wbd parameter. 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-months-last-dmr: float # The number of months since the last Discharge Monitoring Report has been submitted.
  --p-last-dmr-within: string@p-last-dmr-within-completer # W value returns facilities that have submitted DMRs within the number of months specified by p_months_last_dmr. An N value returns facilities that have not submitted a DMR within the specified number of months.
  --p-indsw: string@p-indsw-completer # Industrial Stormwater Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-msgp-ptype: string@p-msgp-ptype-completer # Multi-Sector General Purpose Permit Type. Enter a value to filter results by MSGP Permit Type. - NOI = Notice of Intent - NOE = No Exposure Certification
  --p-mon-type: string@p-mon-type-completer # For use with the Industrial Stormwater search only. Valid values are BENCHGS fro Benchmark (Alert Limit) G2 Ore, BENCH for Benchmark (Alert Limit), and ELG fro Effluent Limitation Guidelines(ELG)(Effluent Limit).
  --p-iagency: string # Issuing Agency Limiter. Enter a single value to filter results by the issuing agency, e.g. "State" or "EPA".
  --p-permitting-agency: string
  --p-isws: string # Multi-Sector General Purpose Permit Subsector Individual Identifier. Enter a value to filter results.
  --p-iswss: string # Multi-Sector General Purpose Permit Subsector Group Code. Enter a value to filter results.
  --p-iswss-id: string # Multi-Sector General Purpose Permit Sector Code. Enter a value to filter results.
  --p-ds1: string # Submitted Date Filter Start. To filter by the date of submission, enter a start date here and an end date in the p_ds2 parameter. Both dates are required for filtering.
  --p-ds2: string # Submitted Date Filter End. To filter by the date of submission, enter an end date here and a start date in the p_ds1 parameter. Both dates are required for filtering.
  --p-da1: string # Active Date Filter Start. To filter by the active date, enter a start date here and an end date in the p_da2 parameter. Both dates are required for filtering.
  --p-da2: string # Active Date Filter End. To filter by the active date, enter an end date here and a start date in the p_da1 parameter. Both dates are required for filtering.
  --p-ms4: string@p-ms4-completer # Municipal Separate Storm Water Sewer (MS4) Permit Flag. Enter a Y or N to filter results by this type of permit.
  --p-oo-fn: string # Owner/Operator Name. Enter the owner/operator name of the facility.
  --p-oo-f-ntype: string@p-oo-f-ntype-completer # Owner/Operator Name Multiple Selection Evaluator.
  --p-oo-sa: string # Owner/Operator Address. Enter the address of the owner/operator of the facility.
  --p-oo-sa1: string # Owner/Operator Address Line 2. Enter the line 2 address of the owner/operator of the facility.
  --p-oo-ct: string # Owner/Operator City. Enter the city where the owner/operator of the facility is located.
  --p-oo-st: string # Owner/Operator State. Enter the standardized postal state code where the owner/operator of the facility is located.
  --p-oo-zip: string # Owner/Operator Zip Code. Enter the postal zip code where the owner/operator of the facility is located.
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-alrexceed: float # Alert Limits Exceedences Limiter. Enter a numeric value to restrict results to facilities having the given amount or more of alert limits exceedances.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --p-bio-flag: string # A Y value will select all biosolid-related permits.
  --p-bio-fac-type: string # The code indicating the reporting obligation reason: - POT = A POTW with a design flow rate equal to or greater than one million gallons per day - CLI = A Class I Sludge Management Facility as defined in 40 CFR 503.9 - PPL = A POTW that serves 10,000 people or more - OTH = Otherwise required to report (e.g., permit condition, enforcement action) - NOA = None of the above
  --p-bio-trtmnt-procs: string # The biosolids or sewage sludge treatment process or processes at the facility: - AER = Aerobic Digestion - AIR = Air Drying (or Sludge Drying Beds) - ANA = Anaerobic Digestion - COD = Beta Ray Irradiation - COM = Lower Temperature Composting - DEW = Pasteurization - DIS = Gamma Ray Irradiation - HEA = Heat Drying (e.g., Flash Dryer, Spray Dryer, Rotary Dryer) - HET = Heat Treatment (Liquid Sewage Sludge Heated to 356 Deg. F/180 Deg. C or Higher for 30 min.) - HTC = Higher Temperature Composting - MET = Methane or Biogas Capture and Recovery - OTH = Other Treatment Process - PRE = Preliminary Operations (e.g., Sludge Grinding, Degritting, Blending) - SLU = Sludge Lagoon - STA = Lime Stabilization - THE = Temporary Sludge Storage (Sewage Sludge Stored on Land 2 Years or Less, Not in Sewage Sludge Unit) - THI = Thickening (Gravity and/or Flotation Thickening, Centrifugation, Belt Filter Press, Vacuum Filter) - THM = Thermophilic Aerobic Digestion - UND = Long-Term Sludge Storage (Sewage Sludge Stored on Land 2 Years or More, not in Sewage Sludge Unit)"
  --p-bio-analy-method-catgry: string # The unique code for the category of the analytic methods used by the facility to analyze regulated parameters (including enteric viruses, fecal coliforms, helminth ova, and Salmonella sp.) at the facility: - PAT = Pathogens - MET = Metals - NIT = Nitrogen Compounds - OTH = Other Analytes
  --p-bio-total-volume-amt: string # Total annual amount (in dry metric tons) of biosolids or sewage sludge generated at the facility. - EQ0 = 0 - IN0_1 = GT 0 but LT 1 - IN0_289 = GT 0 but LT 290 MT/year - IN290_1499 = GE 290 but LT 1500 MT/year - IN1500_14999 = GE 1500 but LT 15,000 - GE15000 = GE 15,000
  --p-bio-mgmt-prctce-type: string # The unique code that identifies the type of biosolids or sewage sludge management practice (e.g., land application, surface disposal, incineration) used by the facility. The facility will separately report the management practice for each biosolids or sewage sludge form and pathogen class. This data element will also identify the management practices used by surface disposal site owners/operators (see 40 CFR 503.24): - BIN = Incineration - BLN = Land Application - BOT = Other Management Practice - BSD = Surface Disposal
  --p-bio-mgmt-prctce-stype: string # This is the code indicating additional detail about the type of Management Practice used for a volume of Biosolids or Sewage Sludge: - ADV = Advanced Alkaline Stabilized Biosolids Distribution & Marketing - AGR = Agricultural Land Application - COM = Distribution and Marketing - Compost - DEE = Deep-well Injection Disposal - DIS = Disposal in a Municipal Landfill (under 40 CFR 258) - DMO = Distribution and Marketing - Other - HEA = Heat Dried Biosolids Distribution & Marketing - OTL = Other Land Application Management Practice Detail - OTO = Other Management Practice Detail - RSA = Reclamation Site Application - SEN = Sent to Cement Kiln for Use as Alternative Energy - STO = Storage - UIC = Use in Construction - UPS = Used in Production of Syngas - USE = Use as Daily Cover for Municipal Landfill (under 40 CFR 258)
  --p-bio-mgmt-prctce-handler: string # This is the code indicating the type of Biosolids or Sewage Sludge handlers/preparers. - OWN = Owner or Operator - OFF = Off-Site Third-Party Handler or Preparer
  --p-bio-mgmt-container: string # The code that identifies the nature of each biosolids and sewage sludge material generated by the facility in terms of whether the material is a biosolid or sewage sludge and whether the material is ultimately conveyed off-site in bulk or in bags. The facility separately reports the form for each biosolids or sewage sludge management practice or practices used by the facility and pathogen class: - BUL = Bulk - BAG = Bag or Container
  --p-bio-mgmt-pathogen: string # This code identifies the pathogen class [e.g., Class A, Class B, Not Applicable (Incineration)] for biosolids or sewage sludge generated by the facility. The facility will separately report the pathogen class for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form. It also is used to filter applicable Pathogen Reduction and Vector Attraction Reduction Options as well as Land Application Management Practice Deficiencies. Only reqired for some of the mgmt. practice types: - AAA = Class A - AEQ = Class A EQ (sale/give away) - BBB = Class B - NAP = Not Applicable (Incineration)
  --p-bio-mgmt-pathred: string # This is the description of the option used by the facility to control pathogen for a Biosolids Management Practice: - A1 = Class A - Alternative 1: Time/Temperature - A2 = Class A - Alternative 2: pH/Temperature/Percent Solids - A3 = Class A - Alternative 3: Test Enteric Viruses and Helminth ova; Operating Parameters - A4 = Class A - Alternative 4: Test Enteric Viruses and Helminth ova; No New Solids - A51 = Class A - Alternative 5: PFRP 1: Composting - A52 = Class A - Alternative 5: PFRP 2: Heat Drying - A53 = Class A - Alternative 5: PFRP 3: Liquid heat treatment - A54 = Class A - Alternative 5: PFRP 4: Thermophilic Aerobic Digestion (ATAD) - A55 = Class A - Alternative 5 PFPR 5: Beta Ray Irradiation - A56 = Class A - Alternative 5 PFPR 6: Gamma Ray Irradiation - A57 = Class A - Alternative 5: PFRP 7: Pasteurization - A6 = Class A - Alternative 6: PFRP Equivalency - B1 = Class B - Alternative 1: Fecal Coliform Geometric Mean - B21 = Class B - Alternative 2 PSRP 1: Aerobic Digestion - B22 = Class B - Alternative 2 PSRP 2: Air Drying - B23 = Class B - Alternative 2 PSRP 3: Anaerobic Digestion - B24 = Class B - Alternative 2 PSRP 4: Composting - B25 = Class B - Alternative 2 PSRP 5: Lime Stabilization - B3 = Class B - Alternative 3: PSRP Equivalency - PH = pH Adjustment (Domestic Septage)
  --p-bio-mgmt-vector: string # The unique code that identifies the option used by the facility for vector attraction reduction. See a listing of these vector attraction reduction options at 40 CFR 503.33(b)(1) through (11). The facility will separately report the vector attraction reduction options for each biosolids or sewage sludge management practice used by the facility and by each biosolids or sewage sludge form as well as by each biosolids or sewage sludge pathogen class: - VR1 = Option 1 - Volatile Solids Reduction - VR2 = Option 2 - Bench-Scale Volatile Solids Reduction (Anaerobic Bench Test) - VR3 = Option 3 - Bench-Scale Volatile Solids Reduction (Aerobic Bench Test w/ Percent Solids - 2% or Less) - VR4 = Option 4 - Specific Oxygen Uptake Rate - VR5 = Option 5 - Aerobic Processing (Thermophilic Aerobic Digestion/Composting) - VR6 = Option 6 - Alkaline Treatment - VR7 = Option 7 - Drying (Equal to or Greater than 75 Percent) - VR8 = Option 8 - Drying (Equal to or Greater than 90 Percent) - VR9 = Option 9 - Sewage Sludge Injection - V10 = Option 10 - Sewage Sludge Timely Incorporation into Land - V11 = Option 11 - Sewage Sludge Covered at the End of Each Operating Day
  --p-bio-mgmt-def-category: string # This is the code indicating the type of NPDES special regulatory program deficiency: - INC = Biosolids Incineration - LNA = Biosolids Land Application - LNB = Biosolids Land Application - Pathogen Class B - OTB = Biosolids Other Management Practice - SFD = Biosolids Surface Disposal
  --p-bio-mgmt-deficiencies: float # The number of times noncompliance was reported by the facility in the last 3 years. The results returned will include facilities whose number of reported noncompliance events is greater than or equal to the number entered.
  --p-bio-vio-code: string # The Biosolids Single Event Violation Code. Enter one or mode codes.
  --p-bio-current-vio: string@p-bio-current-vio-completer # Indicator of whether the facility is currently in violation for biosolids under the Clean Water Act, in the 12th or 13th quarter: - Y = Yes - N = No
  --p-bio-qtrs-in-vio: float # The number of quarters, in the last three years, where the facility was in violation for a biosolids violation type. The results returned will include facilities whose number of quarters with violations is greater than or equal to the number entered.
  --p-bio-rpt-year: string # The last year that the permittee submitted an annual Biosolids report. Valid values are NONE and any year greater or equal to 2016.
  --p-bio-vio-last-year: string@p-bio-vio-last-year-completer # Identifies if a biosolids violation has occured in the last year. Valid values are Y and N.
  --p-msgp-rpt-year: string # The last year that a MSGP report was submitted for the permit. Valid values are "NONE" and any year Greater or Eqal to 2015.
  --p-vio-last-year: string@p-vio-last-year-completer # Identifies if a permit violation has occured in the last year. Valid values are Y and N.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
  --p-e90-count: float # Number of E90 Exceedances. Identifies water permits with a number of E90 (Effluient Exceedances) >= the value provided for the last number of years provided by the p_e90_years value.
  --p-e90-years: float # Number of years for the p_e90_count search. Identified the past number of years to be used for the p_e90_count search.
  --p-psc: string # Point Source Category.
]: any -> record<Results: record<BadSystemIDs: string, BioCVRows: string, BioV3Rows: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string, VioLast4QRows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cwa_rest_services.get_facility_info")
  let req_body = {"output": $output, "p_fn": $p_fn, "p_sa": $p_sa, "p_sa1": $p_sa1, "p_ct": $p_ct, "p_co": $p_co, "p_fips": $p_fips, "p_st": $p_st, "p_zip": $p_zip, "p_frs": $p_frs, "p_reg": $p_reg, "p_sic": $p_sic, "p_ncs": $p_ncs, "p_pen": $p_pen, "xmin": $xmin, "ymin": $ymin, "xmax": $xmax, "ymax": $ymax, "p_usmex": $p_usmex, "p_sic2": $p_sic2, "p_sic4": $p_sic4, "p_fa": $p_fa, "p_ff": $p_ff, "p_act": $p_act, "p_maj": $p_maj, "p_mact": $p_mact, "p_fea": $p_fea, "p_feay": $p_feay, "p_feaa": $p_feaa, "p_iea": $p_iea, "p_ieay": $p_ieay, "p_ieaa": $p_ieaa, "p_qiv": $p_qiv, "p_iv": $p_iv, "p_impw": $p_impw, "p_imp_pol": $p_imp_pol, "p_imp_cau_grp": $p_imp_cau_grp, "p_trep": $p_trep, "p_pm": $p_pm, "p_pd": $p_pd, "p_ico": $p_ico, "p_huc": $p_huc, "p_pid": $p_pid, "p_med": $p_med, "p_ysl": $p_ysl, "p_ysly": $p_ysly, "p_ysla": $p_ysla, "p_qs": $p_qs, "p_sfs": $p_sfs, "p_tribeid": $p_tribeid, "p_tribename": $p_tribename, "p_tribedist": $p_tribedist, "p_pstat": $p_pstat, "p_ptype": $p_ptype, "p_pcomp": $p_pcomp, "p_plimits": $p_plimits, "p_pcss": $p_pcss, "p_pexp": $p_pexp, "p_owop": $p_owop, "p_ipfti": $p_ipfti, "p_agoo": $p_agoo, "p_idt1": $p_idt1, "p_idt2": $p_idt2, "p_pityp": $p_pityp, "p_pfead1": $p_pfead1, "p_pfead2": $p_pfead2, "p_pfeat": $p_pfeat, "p_pccs": $p_pccs, "p_pexcd": $p_pexcd, "p_psncq": $p_psncq, "p_pctrack": $p_pctrack, "p_dwd": $p_dwd, "p_pt": $p_pt, "p_pdwdist": $p_pdwdist, "p_pswdpc": $p_pswdpc, "p_pswdmp": $p_pswdmp, "p_pswpol": $p_pswpol, "p_pswcas": $p_pswcas, "p_pswparam": $p_pswparam, "p_pswvio": $p_pswvio, "p_wbd": $p_wbd, "p_radwbd": $p_radwbd, "p_frswbd": $p_frswbd, "p_fntype": $p_fntype, "p_pidall": $p_pidall, "p_months_last_dmr": $p_months_last_dmr, "p_last_dmr_within": $p_last_dmr_within, "p_indsw": $p_indsw, "p_msgp_ptype": $p_msgp_ptype, "p_mon_type": $p_mon_type, "p_iagency": $p_iagency, "p_permitting_agency": $p_permitting_agency, "p_isws": $p_isws, "p_iswss": $p_iswss, "p_iswssID": $p_iswss_id, "p_ds1": $p_ds1, "p_ds2": $p_ds2, "p_da1": $p_da1, "p_da2": $p_da2, "p_MS4": $p_ms4, "p_ooFN": $p_oo_fn, "p_ooFNtype": $p_oo_f_ntype, "p_ooSA": $p_oo_sa, "p_ooSA1": $p_oo_sa1, "p_ooCt": $p_oo_ct, "p_ooSt": $p_oo_st, "p_ooZip": $p_oo_zip, "p_fac_ico": $p_fac_ico, "p_icoo": $p_icoo, "p_fac_icos": $p_fac_icos, "p_ejscreen": $p_ejscreen, "p_alrexceed": $p_alrexceed, "p_limit_addr": $p_limit_addr, "p_lat": $p_lat, "p_long": $p_long, "p_radius": $p_radius, "p_ejscreen_over80cnt": $p_ejscreen_over80cnt, "p_bio_flag": $p_bio_flag, "p_bio_fac_type": $p_bio_fac_type, "p_bio_trtmnt_procs": $p_bio_trtmnt_procs, "p_bio_analy_method_catgry": $p_bio_analy_method_catgry, "p_bio_total_volume_amt": $p_bio_total_volume_amt, "p_bio_mgmt_prctce_type": $p_bio_mgmt_prctce_type, "p_bio_mgmt_prctce_stype": $p_bio_mgmt_prctce_stype, "p_bio_mgmt_prctce_handler": $p_bio_mgmt_prctce_handler, "p_bio_mgmt_container": $p_bio_mgmt_container, "p_bio_mgmt_pathogen": $p_bio_mgmt_pathogen, "p_bio_mgmt_pathred": $p_bio_mgmt_pathred, "p_bio_mgmt_vector": $p_bio_mgmt_vector, "p_bio_mgmt_def_category": $p_bio_mgmt_def_category, "p_bio_mgmt_deficiencies": $p_bio_mgmt_deficiencies, "p_bio_vio_code": $p_bio_vio_code, "p_bio_current_vio": $p_bio_current_vio, "p_bio_qtrs_in_vio": $p_bio_qtrs_in_vio, "p_bio_rpt_year": $p_bio_rpt_year, "p_bio_vio_last_year": $p_bio_vio_last_year, "p_msgp_rpt_year": $p_msgp_rpt_year, "p_vio_last_year": $p_vio_last_year, "responseset": $responseset, "callback": $callback, "qcolumns": $qcolumns, "p_pretty_print": $p_pretty_print, "p_e90_count": $p_e90_count, "p_e90_years": $p_e90_years, "p_psc": $p_psc} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Clean Water Act (CWA) GeoJSON Service
#
# GET /cwa_rest_services.get_geojson
export def "cwa-rest-services-get-geojson get" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - GEOJSON = Facility results formatted as GeoJSON feature collection (default). - GEOJSONP = Facility results formatted as GeoJSON feature collection with Padding. - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column. Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag. Enter Y to column identified in the newsort parameter descending. Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> record<features: table<geometry: record, properties: record, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "newsort" $newsort "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "qcolumns" $qcolumns "scalar") (serialize-qp "p_pretty_print" $p_pretty_print "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cwa_rest_services.get_geojson" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "qid": $qid, "callback": $callback, "newsort": $newsort, "descending": $descending, "qcolumns": $qcolumns, "p_pretty_print": $p_pretty_print} | compact), body: null}
}

# Clean Water Act (CWA) GeoJSON Service
#
# POST /cwa_rest_services.get_geojson
export def "cwa-rest-services-get-geojson create" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - GEOJSON = Facility results formatted as GeoJSON feature collection (default). - GEOJSONP = Facility results formatted as GeoJSON feature collection with Padding. - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column. Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag. Enter Y to column identified in the newsort parameter descending. Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: any -> record<features: table<geometry: record, properties: record, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cwa_rest_services.get_geojson")
  let req_body = {"output": $output, "qid": $qid, "callback": $callback, "newsort": $newsort, "descending": $descending, "qcolumns": $qcolumns, "p_pretty_print": $p_pretty_print} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Clean Water Act (CWA) Info Clusters Service
#
# GET /cwa_rest_services.get_info_clusters
export def "cwa-rest-services-get-info-clusters get" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default). - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  --p-qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_qid" $p_qid "scalar") (serialize-qp "p_pretty_print" $p_pretty_print "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cwa_rest_services.get_info_clusters" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "p_qid": $p_qid, "p_pretty_print": $p_pretty_print} | compact), body: null}
}

# Clean Water Act (CWA) Info Clusters Service
#
# POST /cwa_rest_services.get_info_clusters
export def "cwa-rest-services-get-info-clusters create" [
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
  --output: string # Output Format Flag. Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default). - GEOJSOND = Facility results formatted as GeoJSON feature collection download.
  p_qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cwa_rest_services.get_info_clusters")
  let req_body = {"output": $output, "p_qid": $p_qid, "p_pretty_print": $p_pretty_print} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Clean Water Act (CWA) Map Service
#
# GET /cwa_rest_services.get_map
export def "cwa-rest-services-get-map get" [
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
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --c1-lat: float # Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c1-long: float # Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-lat: float # Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-long: float # Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-id: string # Nine-character code used to uniquely identify a permitted NPDES facility. The NPDES permit program regulates the direct discharge of pollutants into US waters.
]: nothing -> record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "tablelist" $tablelist "scalar") (serialize-qp "c1_lat" $c1_lat "scalar") (serialize-qp "c1_long" $c1_long "scalar") (serialize-qp "c2_lat" $c2_lat "scalar") (serialize-qp "c2_long" $c2_long "scalar") (serialize-qp "p_id" $p_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cwa_rest_services.get_map" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "qid": $qid, "callback": $callback, "tablelist": $tablelist, "c1_lat": $c1_lat, "c1_long": $c1_long, "c2_lat": $c2_lat, "c2_long": $c2_long, "p_id": $p_id} | compact), body: null}
}

# Clean Water Act (CWA) Map Service
#
# POST /cwa_rest_services.get_map
export def "cwa-rest-services-get-map create" [
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
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --c1-lat: float # Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c1-long: float # Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-lat: float # Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-long: float # Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  p_id: string # Nine-character code used to uniquely identify a permitted NPDES facility. The NPDES permit program regulates the direct discharge of pollutants into US waters.
]: any -> record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cwa_rest_services.get_map")
  let req_body = {"output": $output, "qid": $qid, "callback": $callback, "tablelist": $tablelist, "c1_lat": $c1_lat, "c1_long": $c1_long, "c2_lat": $c2_lat, "c2_long": $c2_long, "p_id": $p_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Clean Water Act (CWA) Paginated Results Service
#
# GET /cwa_rest_services.get_qid
export def "cwa-rest-services-get-qid get" [
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
]: nothing -> record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "pageno" $pageno "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "newsort" $newsort "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "qcolumns" $qcolumns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cwa_rest_services.get_qid" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "qid": $qid, "pageno": $pageno, "callback": $callback, "newsort": $newsort, "descending": $descending, "qcolumns": $qcolumns} | compact), body: null}
}

# Clean Water Act (CWA) Paginated Results Service
#
# POST /cwa_rest_services.get_qid
export def "cwa-rest-services-get-qid create" [
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
]: any -> record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cwa_rest_services.get_qid")
  let req_body = {"output": $output, "qid": $qid, "pageno": $pageno, "callback": $callback, "newsort": $newsort, "descending": $descending, "qcolumns": $qcolumns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Clean Water Act (CWA) Metadata Service
#
# GET /cwa_rest_services.metadata
export def "cwa-rest-services-metadata get" [
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
  let full_url = (build-url $base "/cwa_rest_services.metadata" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback} | compact), body: null}
}

# Clean Water Act (CWA) Metadata Service
#
# POST /cwa_rest_services.metadata
export def "cwa-rest-services-metadata create" [
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
  let full_url = (build-url $base "/cwa_rest_services.metadata")
  let req_body = {"output": $output, "callback": $callback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO BP Tribes Lookup Service
#
# GET /rest_lookups.bp_tribes
export def "rest-lookups-bp-tribes get" [
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
  let full_url = (build-url $base "/rest_lookups.bp_tribes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact), body: null}
}

# ECHO BP Tribes Lookup Service
#
# POST /rest_lookups.bp_tribes
export def "rest-lookups-bp-tribes create" [
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
  let full_url = (build-url $base "/rest_lookups.bp_tribes")
  let req_body = {"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact
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

# ECHO CWA Pollutants Lookup Service
#
# GET /rest_lookups.cwa_pollutants
export def "rest-lookups-cwa-pollutants get" [
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
  let full_url = (build-url $base "/rest_lookups.cwa_pollutants" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact), body: null}
}

# ECHO CWA Pollutants Lookup Service
#
# POST /rest_lookups.cwa_pollutants
export def "rest-lookups-cwa-pollutants create" [
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
  let full_url = (build-url $base "/rest_lookups.cwa_pollutants")
  let req_body = {"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO Federal Agency Lookup Service
#
# GET /rest_lookups.federal_agencies
export def "rest-lookups-federal-agencies get" [
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
  let full_url = (build-url $base "/rest_lookups.federal_agencies" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact), body: null}
}

# ECHO Federal Agency Lookup Service
#
# POST /rest_lookups.federal_agencies
export def "rest-lookups-federal-agencies create" [
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
  let full_url = (build-url $base "/rest_lookups.federal_agencies")
  let req_body = {"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO ICIS NPDES Inspection Types Lookup Service
#
# GET /rest_lookups.icis_inspection_types
export def "rest-lookups-icis-inspection-types get" [
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
  let full_url = (build-url $base "/rest_lookups.icis_inspection_types" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact), body: null}
}

# ECHO ICIS NPDES Inspection Types Lookup Service
#
# POST /rest_lookups.icis_inspection_types
export def "rest-lookups-icis-inspection-types create" [
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
  let full_url = (build-url $base "/rest_lookups.icis_inspection_types")
  let req_body = {"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO ICIS NPDES Law Sections Lookup Service
#
# GET /rest_lookups.icis_law_sections
export def "rest-lookups-icis-law-sections get" [
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
  --statute-code: string
  --status-flag: string
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
  --sort-order: float
]: nothing -> record<Results: record<LuValues: list<record>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "statute_code" $statute_code "scalar") (serialize-qp "status_flag" $status_flag "scalar") (serialize-qp "search_term" $search_term "scalar") (serialize-qp "search_code" $search_code "scalar") (serialize-qp "sort_order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest_lookups.icis_law_sections" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "statute_code": $statute_code, "status_flag": $status_flag, "search_term": $search_term, "search_code": $search_code, "sort_order": $sort_order} | compact), body: null}
}

# ECHO ICIS NPDES Law Sections Lookup Service
#
# POST /rest_lookups.icis_law_sections
export def "rest-lookups-icis-law-sections create" [
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
  --statute-code: string
  --status-flag: string
  --search-term: string # Enter a partial or complete search phrase or word.
  --search-code: string # Enter a partial or complete code value.
  --sort-order: float
]: any -> record<Results: record<LuValues: list<record>, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest_lookups.icis_law_sections")
  let req_body = {"output": $output, "callback": $callback, "statute_code": $statute_code, "status_flag": $status_flag, "search_term": $search_term, "search_code": $search_code, "sort_order": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO NAICS Codes Lookup Service
#
# GET /rest_lookups.naics_codes
export def "rest-lookups-naics-codes get" [
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
  let full_url = (build-url $base "/rest_lookups.naics_codes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact), body: null}
}

# ECHO NAICS Codes Lookup Service
#
# POST /rest_lookups.naics_codes
export def "rest-lookups-naics-codes create" [
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
  let full_url = (build-url $base "/rest_lookups.naics_codes")
  let req_body = {"output": $output, "callback": $callback, "search_term": $search_term, "search_code": $search_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO NPDES Parameters Lookup Service
#
# GET /rest_lookups.npdes_parameters
export def "rest-lookups-npdes-parameters get" [
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
]: nothing -> record<Results: record<LuValues: list<record>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "search_term" $search_term "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest_lookups.npdes_parameters" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "search_term": $search_term} | compact), body: null}
}

# ECHO NPDES Parameters Lookup Service
#
# POST /rest_lookups.npdes_parameters
export def "rest-lookups-npdes-parameters create" [
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
]: any -> record<Results: record<LuValues: list<record>, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest_lookups.npdes_parameters")
  let req_body = {"output": $output, "callback": $callback, "search_term": $search_term} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO WBD Code Lookup Service
#
# GET /rest_lookups.wbd_code_lu
export def "rest-lookups-wbd-code-lu get" [
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
  --wbd-code: string # Two-digit watershed code [Hydrologic Unit Code (HUC)].
  --wbd-level: string # The number of digits of the watershed code [Hydrologic Unit Code (HUC)] returned in the ValueCode. Must be an even number between 4 and 12.
]: nothing -> record<Results: record<LuValues: list<record>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "wbd_code" $wbd_code "scalar") (serialize-qp "wbd_level" $wbd_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest_lookups.wbd_code_lu" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "wbd_code": $wbd_code, "wbd_level": $wbd_level} | compact), body: null}
}

# ECHO WBD Code Lookup Service
#
# POST /rest_lookups.wbd_code_lu
export def "rest-lookups-wbd-code-lu create" [
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
  --wbd-code: string # Two-digit watershed code [Hydrologic Unit Code (HUC)].
  --wbd-level: string # The number of digits of the watershed code [Hydrologic Unit Code (HUC)] returned in the ValueCode. Must be an even number between 4 and 12.
]: any -> record<Results: record<LuValues: list<record>, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest_lookups.wbd_code_lu")
  let req_body = {"output": $output, "callback": $callback, "wbd_code": $wbd_code, "wbd_level": $wbd_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# ECHO WBD Name Lookup Service
#
# GET /rest_lookups.wbd_name_lu
export def "rest-lookups-wbd-name-lu get" [
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
  --wbd-name: string # Watershed Name Filter.
  --wbd-level: string # The number of digits of the watershed code [Hydrologic Unit Code (HUC)] returned in the ValueCode. Must be an even number between 4 and 12.
]: nothing -> record<Results: record<LuValues: list<record>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "wbd_name" $wbd_name "scalar") (serialize-qp "wbd_level" $wbd_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest_lookups.wbd_name_lu" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"output": $output, "callback": $callback, "wbd_name": $wbd_name, "wbd_level": $wbd_level} | compact), body: null}
}

# ECHO WBD Name Lookup Service
#
# POST /rest_lookups.wbd_name_lu
export def "rest-lookups-wbd-name-lu create" [
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
  wbd_name: string # Watershed Name Filter.
  --wbd-level: string # The number of digits of the watershed code [Hydrologic Unit Code (HUC)] returned in the ValueCode. Must be an even number between 4 and 12.
]: any -> record<Results: record<LuValues: list<record>, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest_lookups.wbd_name_lu")
  let req_body = {"output": $output, "callback": $callback, "wbd_name": $wbd_name, "wbd_level": $wbd_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
