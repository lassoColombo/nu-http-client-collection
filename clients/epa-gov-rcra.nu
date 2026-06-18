# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Resource Conservation and Recovery Act  v2019.10.15
# Source: https://api.apis.guru/v2/specs/epa.gov/rcra/2019.10.15/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____RESOURCE_CONSERVATION_AND_RECOVERY_ACT_TOKEN

const BASE_URL = "https://echodata.epa.gov/echo"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____RESOURCE_CONSERVATION_AND_RECOVERY_ACT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://echodata.epa.gov/echo"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def output-completer [] { ["JSON" "JSONP" "XML"] }
def p-reg-completer [] { ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10"] }
def p-usmex-completer [] { ["N" "Y"] }
def p-act-completer [] { ["A" "N" "Y"] }
def p-fea-completer [] { ["N" "W"] }
def p-feay-completer [] { ["1" "2" "3" "4" "5"] }
def p-feaa-completer [] { ["A" "E" "S"] }
def p-iea-completer [] { ["N" "W"] }
def p-ieay-completer [] { ["1" "2" "3" "4" "5"] }
def p-ieaa-completer [] { ["E" "S"] }
def p-qiv-completer [] { ["0" "12" "GT1" "GT2" "GT4" "GT8"] }
def p-impw-completer [] { ["N" "Y"] }
def p-trep-completer [] { ["CURR" "NOTCURR"] }
def p-oct-completer [] { ["GT0" "GT1000" "GT10000" "GT20000" "GT5000" "GT50000" "Z"] }
def p-pm-completer [] { ["GT10" "GT25" "GT5" "GT50" "GT75" "NONE"] }
def p-pd-completer [] { ["GT100" "GT1000" "GT10000" "GT20000" "GT500" "GT5000" "NONE"] }
def p-ico-completer [] { ["N" "Y"] }
def p-med-completer [] { ["A" "ALL" "M" "R" "S" "W"] }
def p-ysl-completer [] { ["N" "NV" "W"] }
def p-ysly-completer [] { ["1" "2" "3" "4" "5"] }
def p-ysla-completer [] { ["A" "E" "S"] }
def p-owop-completer [] { ["FEDERAL" "PRIVATE" "PUBLIC"] }
def p-agoo-completer [] { ["AND" "OR"] }
def p-cifdi-completer [] { ["Any" "No" "Undetermined" "Yes"] }
def p-psncq-completer [] { ["GE1" "GE12" "GE2" "GE4" "GE8" "GT1" "GT12" "GT2" "GT4" "GT8"] }
def p-dwd-completer [] { ["0" "GT0" "GT1000" "GT10000" "GT20000" "GT5000" "GT50000"] }
def p-violy-completer [] { ["1" "2" "3"] }
def p-fntype-completer [] { ["ALL" "BEGINS" "CONTAINS" "EXACT"] }
def p-pidall-completer [] { ["N" "Y"] }
def p-fac-ico-completer [] { ["N" "Y"] }
def p-limit-addr-completer [] { ["N" "Y"] }
def p-decouple-completer [] { ["N" "Y"] }
def p-ejscreen-over80cnt-completer [] { ["1" "10" "11" "2" "3" "4" "5" "6" "7" "8" "9"] }
def tablelist-completer [] { ["N" "Y"] }
def maplist-completer [] { ["N" "Y"] }
def summarylist-completer [] { ["N" "Y"] }
def descending-completer [] { ["N" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rcra-rest-services-get-download get" } } | get name | first)
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

# Resource Conservation and Recovery Act (RCRA) Download Data Service
#
# GET /rcra_rest_services.get_download
export def "rcra-rest-services-get-download get" [
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
  --qid: string # Query ID Selector. Enter the QueryID number from a previously run query.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "qcolumns" $qcolumns "scalar") (serialize-qp "p_pretty_print" $p_pretty_print "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rcra_rest_services.get_download" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resource Conservation and Recovery Act (RCRA) Download Data Service
#
# POST /rcra_rest_services.get_download
export def "rcra-rest-services-get-download create" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rcra_rest_services.get_download")
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Resource Conservation and Recovery Act (RCRA) Facility Search Service
#
# GET /rcra_rest_services.get_facilities
export def "rcra-rest-services-get-facilities get" [
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
  --p-stdist: string # State District Filter. Enter a single state district to restrict results.
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
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-cmps: string # RCRA Current Compliance Status Limiter. Enter one or more of the following keywords to limit results. Enter multiple values as a comma-delimited list. - No Violation - In Violation - In Significant Noncompliance
  --p-law: string # Law Statute Code Filter. Enter a single statute code to limit results.
  --p-section: string # Law Section Code Filter. Enter one or more law section codes to limit results. Provide multiple values as a comma-delimited list.
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-olr: string # Toxics Release Inventory Pounds of Off-Site Land Releases Limiter. Enter a keyword to filter results. - Z = Zero pounds of land releases. - GT0 = More than zero pounds of land releases. - GT1000 = More than one thousand pounds of land releases. - GT5000 = More than five thousand pounds of land releases. - GT10000 = More than ten thousand pounds of land releases. - GT20000 = More than twenty thousand pounds of land releases. - GT50000 = More than fifty thousand pounds of land releases.
  --p-oct: string@p-oct-completer # Toxic Release Inventory Pounds of Off-Site Chemical Releases Limiter. Enter a keyword to filter results. - Z = Zero pounds of chemical releases. - GT0 = More than zero pounds of chemical releases. - GT1000 = More than one thousand pounds of chemical releases. - GT5000 = More than five thousand pounds of chemical releases. - GT10000 = More than ten thousand pounds of chemical releases. - GT20000 = More than twenty thousand pounds of chemical releases. - GT50000 = More than fifty thousand pounds of chemical releases.
  --p-trichem: string
  --p-tri-lr-pol: string
  --p-tri-lr-yr: string
  --p-tri-lr-amt: string
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - W = Water - ALL = Air and Water and RCRA
  --p-owc: string
  --p-owd: string
  --p-opc: string
  --p-opd: string
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following codes to filter results: - PUBLIC - PRIVATE - FEDERAL
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type: - CAC = Corrective Action Inspection - CAV = Compliance Assistance Visit - CDI = Case Development Inspection - CEI = Inspection Inspection - CSE = Compliance Schedule Evaluation - FCI = Focused Compliance - FRR = Financial Record Review - FSD = Facility Self Disclosure - FUI = Follow-Up Inspection - GME = Groundwater Monitoring Evaluation - NRR = Non-Financial Record Review - OAM = Operation and Maintenance Inspection May contain multiple comma-separated values.
  --p-cifdi: string@p-cifdi-completer # Compliance issuess found during inspection.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-violy: float@p-violy-completer # Years Since Last Violation Limiter. Enter a value in the format GTXX where XX is replaced by the number of years since the last violation.
  --p-ncv: string # Number of Current Violations Limiter. Enter a value in the format GTXX replacing XX with a numeric value to select facilities with an equal to greater count of current violations. Enter Z to select facilities with zero violations.
  --p-fcv: string # Years of Continuing Violations Limiter. Enter a value in the format GTXX where XX is replaced by the number of years in continuing violation.
  --p-violt: string # RCRA Violation Type. Enter one or more Resource Conservation and Recovery Act violation types to limit results. Provide multiple values as a comma-delimited list.
  --p-des: string # Universe Designation Limiter. Enter one or more universe designation codes. Provide multiple values as a comma-delimited list. Use code "TSDF" to return the full enforcement TSDF universe and "Operating TSDF" to return the operating TSDF universe.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-decouple: string@p-decouple-completer # Decouple Inspection Code Search Flag. Enter "Y" to search for inspection code types with p_pityp without respect to the date range search provided with p_ysl* parameters.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --maplist: string@maplist-completer # Map List Flag. Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_fn" $p_fn "scalar") (serialize-qp "p_sa" $p_sa "scalar") (serialize-qp "p_sa1" $p_sa1 "scalar") (serialize-qp "p_ct" $p_ct "scalar") (serialize-qp "p_co" $p_co "scalar") (serialize-qp "p_fips" $p_fips "scalar") (serialize-qp "p_st" $p_st "scalar") (serialize-qp "p_stdist" $p_stdist "scalar") (serialize-qp "p_zip" $p_zip "scalar") (serialize-qp "p_frs" $p_frs "scalar") (serialize-qp "p_reg" $p_reg "scalar") (serialize-qp "p_sic" $p_sic "scalar") (serialize-qp "p_ncs" $p_ncs "scalar") (serialize-qp "p_pen" $p_pen "scalar") (serialize-qp "p_c1lat" $p_c1lat "scalar") (serialize-qp "p_c1lon" $p_c1lon "scalar") (serialize-qp "p_c2lat" $p_c2lat "scalar") (serialize-qp "p_c2lon" $p_c2lon "scalar") (serialize-qp "p_usmex" $p_usmex "scalar") (serialize-qp "p_sic2" $p_sic2 "scalar") (serialize-qp "p_sic4" $p_sic4 "scalar") (serialize-qp "p_fa" $p_fa "scalar") (serialize-qp "p_act" $p_act "scalar") (serialize-qp "p_fea" $p_fea "scalar") (serialize-qp "p_feay" $p_feay "scalar") (serialize-qp "p_feaa" $p_feaa "scalar") (serialize-qp "p_iea" $p_iea "scalar") (serialize-qp "p_ieay" $p_ieay "scalar") (serialize-qp "p_ieaa" $p_ieaa "scalar") (serialize-qp "p_cmps" $p_cmps "scalar") (serialize-qp "p_law" $p_law "scalar") (serialize-qp "p_section" $p_section "scalar") (serialize-qp "p_qiv" $p_qiv "scalar") (serialize-qp "p_impw" $p_impw "scalar") (serialize-qp "p_trep" $p_trep "scalar") (serialize-qp "p_olr" $p_olr "scalar") (serialize-qp "p_oct" $p_oct "scalar") (serialize-qp "p_trichem" $p_trichem "scalar") (serialize-qp "p_tri_lr_pol" $p_tri_lr_pol "scalar") (serialize-qp "p_tri_lr_yr" $p_tri_lr_yr "scalar") (serialize-qp "p_tri_lr_amt" $p_tri_lr_amt "scalar") (serialize-qp "p_pm" $p_pm "scalar") (serialize-qp "p_pd" $p_pd "scalar") (serialize-qp "p_ico" $p_ico "scalar") (serialize-qp "p_huc" $p_huc "scalar") (serialize-qp "p_wbd" $p_wbd "scalar") (serialize-qp "p_pid" $p_pid "scalar") (serialize-qp "p_med" $p_med "scalar") (serialize-qp "p_owc" $p_owc "scalar") (serialize-qp "p_owd" $p_owd "scalar") (serialize-qp "p_opc" $p_opc "scalar") (serialize-qp "p_opd" $p_opd "scalar") (serialize-qp "p_ysl" $p_ysl "scalar") (serialize-qp "p_ysly" $p_ysly "scalar") (serialize-qp "p_ysla" $p_ysla "scalar") (serialize-qp "p_qs" $p_qs "scalar") (serialize-qp "p_sfs" $p_sfs "scalar") (serialize-qp "p_tribeid" $p_tribeid "scalar") (serialize-qp "p_tribename" $p_tribename "scalar") (serialize-qp "p_tribedist" $p_tribedist "scalar") (serialize-qp "p_owop" $p_owop "scalar") (serialize-qp "p_agoo" $p_agoo "scalar") (serialize-qp "p_idt1" $p_idt1 "scalar") (serialize-qp "p_idt2" $p_idt2 "scalar") (serialize-qp "p_pityp" $p_pityp "scalar") (serialize-qp "p_cifdi" $p_cifdi "scalar") (serialize-qp "p_pfead1" $p_pfead1 "scalar") (serialize-qp "p_pfead2" $p_pfead2 "scalar") (serialize-qp "p_pfeat" $p_pfeat "scalar") (serialize-qp "p_psncq" $p_psncq "scalar") (serialize-qp "p_dwd" $p_dwd "scalar") (serialize-qp "p_violy" $p_violy "scalar") (serialize-qp "p_ncv" $p_ncv "scalar") (serialize-qp "p_fcv" $p_fcv "scalar") (serialize-qp "p_violt" $p_violt "scalar") (serialize-qp "p_des" $p_des "scalar") (serialize-qp "p_fntype" $p_fntype "scalar") (serialize-qp "p_pidall" $p_pidall "scalar") (serialize-qp "p_fac_ico" $p_fac_ico "scalar") (serialize-qp "p_icoo" $p_icoo "scalar") (serialize-qp "p_fac_icos" $p_fac_icos "scalar") (serialize-qp "p_ejscreen" $p_ejscreen "scalar") (serialize-qp "p_limit_addr" $p_limit_addr "scalar") (serialize-qp "p_lat" $p_lat "scalar") (serialize-qp "p_long" $p_long "scalar") (serialize-qp "p_radius" $p_radius "scalar") (serialize-qp "p_decouple" $p_decouple "scalar") (serialize-qp "p_ejscreen_over80cnt" $p_ejscreen_over80cnt "scalar") (serialize-qp "queryset" $queryset "scalar") (serialize-qp "responseset" $responseset "scalar") (serialize-qp "tablelist" $tablelist "scalar") (serialize-qp "maplist" $maplist "scalar") (serialize-qp "summarylist" $summarylist "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "qcolumns" $qcolumns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rcra_rest_services.get_facilities" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resource Conservation and Recovery Act (RCRA) Facility Search Service
#
# POST /rcra_rest_services.get_facilities
export def "rcra-rest-services-get-facilities create" [
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
]: any -> record<Results: record<BadSystemIDs: string, CVRows: string, FEARows: string, Facilities: list<record>, INSPRows: string, IndianCountryRows: string, InfFEARows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, SVRows: string, TotalPenalties: string, V3Rows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rcra_rest_services.get_facilities")
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Resource Conservation and Recovery Act (RCRA) Facility Enhanced Search Service
#
# GET /rcra_rest_services.get_facility_info
export def "rcra-rest-services-get-facility-info get" [
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
  --p-stdist: string # State District Filter. Enter a single state district to restrict results.
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
  --p-act: string@p-act-completer # Active Permits/Facilities Flag. Provide Y or N to filter results to facilities with active permits.
  --p-fea: string@p-fea-completer # Formal Enforcement Actions [within / not within] specified date range indicator. The date range is determined by parameters p_fead1 and p_fead2 or by parameter p_feay. - W = within date range - N = not within date range
  --p-feay: float@p-feay-completer # Years (1 to 5) Range. This value is used to create a date range for Formal Enforcement Actions (FEA). Used along with p_fea (which indicates whether to look within or outside of the date range) to find FEAs within (or not within) the number of years specified.
  --p-feaa: string@p-feaa-completer # Agency associated with Formal Enforcement Actions: - E = EPA - S = State - A = All
  --p-iea: string@p-iea-completer # Informal Enforcement Actions [within / not within] specified date range. The date range is determined by parameters p_iead1 and p_iead2 or by parameter p_ieay. - W = within date range - N = not within date range
  --p-ieay: float@p-ieay-completer # Years (1 to 5) Range. This value is used to create a date range for Informal Enforcement Actions (IEA). Used along with p_iea (which indicates whether to look within or outside of the date range) to find IEAs within (or not within) the number of years specified.
  --p-ieaa: string@p-ieaa-completer # Agency associated with Informal Enforcement Actions. If left blank, both agencies are included. - E = EPA - S = State
  --p-cmps: string # RCRA Current Compliance Status Limiter. Enter one or more of the following keywords to limit results. Enter multiple values as a comma-delimited list. - No Violation - In Violation - In Significant Noncompliance
  --p-law: string # Law Statute Code Filter. Enter a single statute code to limit results.
  --p-section: string # Law Section Code Filter. Enter one or more law section codes to limit results. Provide multiple values as a comma-delimited list.
  --p-qiv: string@p-qiv-completer # Quarters in Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of noncompliance. - Z = Zero quarters in noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in noncompliance.
  --p-impw: string@p-impw-completer # Discharging into Impaired Waters Flag. Enter Y to limit results to facilities with discharge to waterbodies listed as impaired in the ATTAINS database.
  --p-trep: string@p-trep-completer # Current Toxics Release Inventory (TRI) Reporter Limiter. Enter one of the following codes to limit results. - CURR = Current TRI reporter. - NONCURR = Has reported to TRI in the past but not for the current reporting year.
  --p-olr: string # Toxics Release Inventory Pounds of Off-Site Land Releases Limiter. Enter a keyword to filter results. - Z = Zero pounds of land releases. - GT0 = More than zero pounds of land releases. - GT1000 = More than one thousand pounds of land releases. - GT5000 = More than five thousand pounds of land releases. - GT10000 = More than ten thousand pounds of land releases. - GT20000 = More than twenty thousand pounds of land releases. - GT50000 = More than fifty thousand pounds of land releases.
  --p-oct: string@p-oct-completer # Toxic Release Inventory Pounds of Off-Site Chemical Releases Limiter. Enter a keyword to filter results. - Z = Zero pounds of chemical releases. - GT0 = More than zero pounds of chemical releases. - GT1000 = More than one thousand pounds of chemical releases. - GT5000 = More than five thousand pounds of chemical releases. - GT10000 = More than ten thousand pounds of chemical releases. - GT20000 = More than twenty thousand pounds of chemical releases. - GT50000 = More than fifty thousand pounds of chemical releases.
  --p-trichem: string
  --p-tri-lr-pol: string
  --p-tri-lr-yr: string
  --p-tri-lr-amt: string
  --p-pm: string@p-pm-completer # Percent Minority Population Limiter. Enter a value to restrict results to facilities with a given percentage of minority population within 3-mile radius. - NONE = 0% - GT5 = greater than 5% - GT10 = greater than 10% - GT25 = greater than 25% - GT50 = greater than 50% - GT75 = greater than 75%
  --p-pd: string@p-pd-completer # Population Density Limiter (per sq mile). Enter a value to limit results to facilities located in area of a given population density. - NONE = 0 population density per square mile - GT100 = More than 100 population density per square mile - GT500 = More than 500 population density per square mile - GT1000 = More than 1000 population density per square mile - GT5000 = More than 5000 population density per square mile - GT10000 = More than 10000 population density per square mile - GT20000 = More than 20000 population density per square mile
  --p-ico: string@p-ico-completer # Indian Country Flag. Enter a "Y" or "N" to restrict searches to facilities inside or outside Indian Country.
  --p-huc: string # 2-, 4-, 6-, or 8-character watershed code. May contain multiple comma-separated values.
  --p-wbd: string # 2-, 4-, 6-, 8-, 10-, or 12-character watershed (WBD from the USGS Watershed Boundary Dataset). May contain multiple comma-separated values. Uses the FRS Best Pick Coordinate to obtain the WBD12 Huc value.
  --p-pid: string # Nine-digit permit IDs. May contain up to 2000 comma-separated values.
  --p-med: string@p-med-completer # Filter Results by Media. - A = Air - M = RMP (Risk Management Plan) - R = RCRA (Hazardous Waste) - S = SDWA (Public Drinking Water Systems) - W = Water - ALL = Air and Water and RCRA
  --p-owc: string
  --p-owd: string
  --p-opc: string
  --p-opd: string
  --p-ysl: string@p-ysl-completer # Last Facility Inspection [within / not within] Specified Date Range Indicator. The date range is determined by parameters p_idt1 and p_idt2 or by parameter p_ysly. - W = within date range - N = not within date range
  --p-ysly: float@p-ysly-completer # Number of years (1 to 5) since last facility inspection. A value of 1 means that it has been inspected within the year.
  --p-ysla: string@p-ysla-completer # Facility Last Inspection Code Filter. If left blank, both agencies are included. Enter a value to limit results: - E = EPA - S = State
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-sfs: string # Single Facility Search Filter. Provide a facility name or program system identifier to limit results. For the all data search, the FRS registry identifier is also searched.
  --p-tribeid: float # Numeric code for tribe (or list of tribes).
  --p-tribename: string # Tribe Name Filter. Enter a single tribe name to filter results.
  --p-tribedist: float # Proximity to tribal land limiter. Enter an amount of mile between 0 and 25 to filter results. This parameter is only evaluated if p_tribeid is populated.
  --p-owop: string@p-owop-completer # Owner/Operator code filter. Enter one of the following codes to filter results: - PUBLIC - PRIVATE - FEDERAL
  --p-agoo: string@p-agoo-completer # Indicates whether to AND or OR the Owner/Operator parameter (p_owop) and the federal agency code (p_fa) parameters.
  --p-idt1: string # Beginning of date range of most recent facility inspection.
  --p-idt2: string # End of date range of most recent facility inspection.
  --p-pityp: string # Inspection Type: - CAC = Corrective Action Inspection - CAV = Compliance Assistance Visit - CDI = Case Development Inspection - CEI = Inspection Inspection - CSE = Compliance Schedule Evaluation - FCI = Focused Compliance - FRR = Financial Record Review - FSD = Facility Self Disclosure - FUI = Follow-Up Inspection - GME = Groundwater Monitoring Evaluation - NRR = Non-Financial Record Review - OAM = Operation and Maintenance Inspection May contain multiple comma-separated values.
  --p-cifdi: string@p-cifdi-completer # Compliance issuess found during inspection.
  --p-pfead1: string # Formal Enforcement Action Date Range Start. Enter a date in MM/DD/YYYY format to set the start of the range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfead2: string # Formal Enforcement Action Date Range End. Enter a date in MM/DD/YYYY format to set the end of the date range for filtering by recent Formal Enforcement Action (FEA) taken against the facility within the last five years.
  --p-pfeat: string # Formal Enforcement Action (FEA) Code Filter. Enter one or more three-letter FEA codes to restrict results to facilities with these attributes. Use p_fead1 and p_fead2 parameters to further restrict this filter by entering a date range. Provide multiple codes as a comma-delimited list.
  --p-psncq: string@p-psncq-completer # Quarters in Significant Noncompliance Limiter. Enter a coded value to limit results to facilities with given quarter of significant noncompliance. - Z = Zero quarters in significant noncompliance. - GEXX = Replacing XX with a numeric value, that number of quarterd or more in significant noncompliance. - GTXX = Replacing XX with a numeric value, more than that number of quarters in significant noncompliance.
  --p-dwd: string@p-dwd-completer # Direct Water Discharges. Pounds of toxic chemicals released directly to surface water as reported to the Toxics Release Inventory.
  --p-violy: float@p-violy-completer # Years Since Last Violation Limiter. Enter a value in the format GTXX where XX is replaced by the number of years since the last violation.
  --p-ncv: string # Number of Current Violations Limiter. Enter a value in the format GTXX replacing XX with a numeric value to select facilities with an equal to greater count of current violations. Enter Z to select facilities with zero violations.
  --p-fcv: string # Years of Continuing Violations Limiter. Enter a value in the format GTXX where XX is replaced by the number of years in continuing violation.
  --p-violt: string # RCRA Violation Type. Enter one or more Resource Conservation and Recovery Act violation types to limit results. Provide multiple values as a comma-delimited list.
  --p-des: string # Universe Designation Limiter. Enter one or more universe designation codes. Provide multiple values as a comma-delimited list. Use code "TSDF" to return the full enforcement TSDF universe and "Operating TSDF" to return the operating TSDF universe.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS =
  --p-pidall: string@p-pidall-completer # Controls whether search is restricted to existing system. Y means the search will match the p_pid parameter against all associated permits (AIR, RCRA, SDWIS, etc).
  --p-fac-ico: string@p-fac-ico-completer # FRS tribal land code flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land code.
  --p-icoo: string # Indian country search and/or flag. Enter "Y" to set indian country search conditions to return any results found using p_ico, p_fac_ico or p_fac_icoo. Otherwise only results matching all provided p_ico, p_fac_ico or p_fac_icoo conditions will be returned.
  --p-fac-icos: string # FRS tribal land spatial flag. Enter "Y" or "N" to include or exclude facilities based on FRS tribal land spatial flag.
  --p-ejscreen: string # Enter "Y" to limit facilities to Census block groups where one of more Environmental Justice indexes above 80th percentile.
  --p-limit-addr: string@p-limit-addr-completer # Limit Address Search Flag. Enter Y to restrict facility searches to native data source only.
  --p-lat: float # Latitude location in decimal degrees.
  --p-long: float # Longitude location in decimal degrees.
  --p-radius: float # Spatial Search Radius. Enter a radius up to 100 miles in which to spatially search for facilities.
  --p-decouple: string@p-decouple-completer # Decouple Inspection Code Search Flag. Enter "Y" to search for inspection code types with p_pityp without respect to the date range search provided with p_ysl* parameters.
  --p-ejscreen-over80cnt: string@p-ejscreen-over80cnt-completer # The number of Environmenmt Justice Indicators above the 80th percentile. Valid values are 1 through 11.
  --queryset: float # Query Limiter. Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --summarylist: string@summarylist-completer # Summary List Flag. Enter a Y to return a list of summary statistics based on the parameters submitted to the query service.
  --callback: string # JSONP Callback. For use with JSONP and GEOJSONP output only. Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output. A list of comma-separated column IDs of output objects that will be returned in the service query object or download. Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed. Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
]: nothing -> record<Results: record<BadSystemIDs: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_fn" $p_fn "scalar") (serialize-qp "p_sa" $p_sa "scalar") (serialize-qp "p_sa1" $p_sa1 "scalar") (serialize-qp "p_ct" $p_ct "scalar") (serialize-qp "p_co" $p_co "scalar") (serialize-qp "p_fips" $p_fips "scalar") (serialize-qp "p_st" $p_st "scalar") (serialize-qp "p_stdist" $p_stdist "scalar") (serialize-qp "p_zip" $p_zip "scalar") (serialize-qp "p_frs" $p_frs "scalar") (serialize-qp "p_reg" $p_reg "scalar") (serialize-qp "p_sic" $p_sic "scalar") (serialize-qp "p_ncs" $p_ncs "scalar") (serialize-qp "p_pen" $p_pen "scalar") (serialize-qp "xmin" $xmin "scalar") (serialize-qp "ymin" $ymin "scalar") (serialize-qp "xmax" $xmax "scalar") (serialize-qp "ymax" $ymax "scalar") (serialize-qp "p_usmex" $p_usmex "scalar") (serialize-qp "p_sic2" $p_sic2 "scalar") (serialize-qp "p_sic4" $p_sic4 "scalar") (serialize-qp "p_fa" $p_fa "scalar") (serialize-qp "p_act" $p_act "scalar") (serialize-qp "p_fea" $p_fea "scalar") (serialize-qp "p_feay" $p_feay "scalar") (serialize-qp "p_feaa" $p_feaa "scalar") (serialize-qp "p_iea" $p_iea "scalar") (serialize-qp "p_ieay" $p_ieay "scalar") (serialize-qp "p_ieaa" $p_ieaa "scalar") (serialize-qp "p_cmps" $p_cmps "scalar") (serialize-qp "p_law" $p_law "scalar") (serialize-qp "p_section" $p_section "scalar") (serialize-qp "p_qiv" $p_qiv "scalar") (serialize-qp "p_impw" $p_impw "scalar") (serialize-qp "p_trep" $p_trep "scalar") (serialize-qp "p_olr" $p_olr "scalar") (serialize-qp "p_oct" $p_oct "scalar") (serialize-qp "p_trichem" $p_trichem "scalar") (serialize-qp "p_tri_lr_pol" $p_tri_lr_pol "scalar") (serialize-qp "p_tri_lr_yr" $p_tri_lr_yr "scalar") (serialize-qp "p_tri_lr_amt" $p_tri_lr_amt "scalar") (serialize-qp "p_pm" $p_pm "scalar") (serialize-qp "p_pd" $p_pd "scalar") (serialize-qp "p_ico" $p_ico "scalar") (serialize-qp "p_huc" $p_huc "scalar") (serialize-qp "p_wbd" $p_wbd "scalar") (serialize-qp "p_pid" $p_pid "scalar") (serialize-qp "p_med" $p_med "scalar") (serialize-qp "p_owc" $p_owc "scalar") (serialize-qp "p_owd" $p_owd "scalar") (serialize-qp "p_opc" $p_opc "scalar") (serialize-qp "p_opd" $p_opd "scalar") (serialize-qp "p_ysl" $p_ysl "scalar") (serialize-qp "p_ysly" $p_ysly "scalar") (serialize-qp "p_ysla" $p_ysla "scalar") (serialize-qp "p_qs" $p_qs "scalar") (serialize-qp "p_sfs" $p_sfs "scalar") (serialize-qp "p_tribeid" $p_tribeid "scalar") (serialize-qp "p_tribename" $p_tribename "scalar") (serialize-qp "p_tribedist" $p_tribedist "scalar") (serialize-qp "p_owop" $p_owop "scalar") (serialize-qp "p_agoo" $p_agoo "scalar") (serialize-qp "p_idt1" $p_idt1 "scalar") (serialize-qp "p_idt2" $p_idt2 "scalar") (serialize-qp "p_pityp" $p_pityp "scalar") (serialize-qp "p_cifdi" $p_cifdi "scalar") (serialize-qp "p_pfead1" $p_pfead1 "scalar") (serialize-qp "p_pfead2" $p_pfead2 "scalar") (serialize-qp "p_pfeat" $p_pfeat "scalar") (serialize-qp "p_psncq" $p_psncq "scalar") (serialize-qp "p_dwd" $p_dwd "scalar") (serialize-qp "p_violy" $p_violy "scalar") (serialize-qp "p_ncv" $p_ncv "scalar") (serialize-qp "p_fcv" $p_fcv "scalar") (serialize-qp "p_violt" $p_violt "scalar") (serialize-qp "p_des" $p_des "scalar") (serialize-qp "p_fntype" $p_fntype "scalar") (serialize-qp "p_pidall" $p_pidall "scalar") (serialize-qp "p_fac_ico" $p_fac_ico "scalar") (serialize-qp "p_icoo" $p_icoo "scalar") (serialize-qp "p_fac_icos" $p_fac_icos "scalar") (serialize-qp "p_ejscreen" $p_ejscreen "scalar") (serialize-qp "p_limit_addr" $p_limit_addr "scalar") (serialize-qp "p_lat" $p_lat "scalar") (serialize-qp "p_long" $p_long "scalar") (serialize-qp "p_radius" $p_radius "scalar") (serialize-qp "p_decouple" $p_decouple "scalar") (serialize-qp "p_ejscreen_over80cnt" $p_ejscreen_over80cnt "scalar") (serialize-qp "queryset" $queryset "scalar") (serialize-qp "responseset" $responseset "scalar") (serialize-qp "summarylist" $summarylist "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "qcolumns" $qcolumns "scalar") (serialize-qp "p_pretty_print" $p_pretty_print "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rcra_rest_services.get_facility_info" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resource Conservation and Recovery Act (RCRA) Facility Enhanced Search Service
#
# POST /rcra_rest_services.get_facility_info
export def "rcra-rest-services-get-facility-info create" [
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
]: any -> record<Results: record<BadSystemIDs: string, CVRows: string, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, FEARows: string, Facilities: list<record>, INSPRows: string, IconBaseURL: string, IndianCountryRows: string, InfFEARows: string, Message: string, PopUpBaseURL: string, QueryID: string, QueryParameters: list<record>, QueryRows: string, SVRows: string, ServiceBaseURL: string, TotalPenalties: string, V3Rows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rcra_rest_services.get_facility_info")
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Resource Conservation and Recovery Act (RCRA) GeoJSON Service
#
# GET /rcra_rest_services.get_geojson
export def "rcra-rest-services-get-geojson get" [
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
  let full_url = (build-url $base "/rcra_rest_services.get_geojson" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resource Conservation and Recovery Act (RCRA) GeoJSON Service
#
# POST /rcra_rest_services.get_geojson
export def "rcra-rest-services-get-geojson create" [
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
]: any -> record<features: table<geometry: record, properties: record, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rcra_rest_services.get_geojson")
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Resource Conservation and Recovery Act (RCRA) Info Clusters Service
#
# GET /rcra_rest_services.get_info_clusters
export def "rcra-rest-services-get-info-clusters get" [
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
  let full_url = (build-url $base "/rcra_rest_services.get_info_clusters" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resource Conservation and Recovery Act (RCRA) Info Clusters Service
#
# POST /rcra_rest_services.get_info_clusters
export def "rcra-rest-services-get-info-clusters create" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rcra_rest_services.get_info_clusters")
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Resource Conservation and Recovery Act (RCRA) Map Service
#
# GET /rcra_rest_services.get_map
export def "rcra-rest-services-get-map get" [
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
  --p-id: string # Identifier for the service.
]: nothing -> record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "tablelist" $tablelist "scalar") (serialize-qp "c1_lat" $c1_lat "scalar") (serialize-qp "c1_long" $c1_long "scalar") (serialize-qp "c2_lat" $c2_lat "scalar") (serialize-qp "c2_long" $c2_long "scalar") (serialize-qp "p_id" $p_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rcra_rest_services.get_map" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resource Conservation and Recovery Act (RCRA) Map Service
#
# POST /rcra_rest_services.get_map
export def "rcra-rest-services-get-map create" [
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
]: any -> record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rcra_rest_services.get_map")
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Resource Conservation and Recovery Act (RCRA) Paginated Results Service
#
# GET /rcra_rest_services.get_qid
export def "rcra-rest-services-get-qid get" [
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
  let full_url = (build-url $base "/rcra_rest_services.get_qid" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resource Conservation and Recovery Act (RCRA) Paginated Results Service
#
# POST /rcra_rest_services.get_qid
export def "rcra-rest-services-get-qid create" [
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
]: any -> record<Results: record<Facilities: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rcra_rest_services.get_qid")
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Resource Conservation and Recovery Act (RCRA) Metadata Service
#
# GET /rcra_rest_services.metadata
export def "rcra-rest-services-metadata get" [
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
  let full_url = (build-url $base "/rcra_rest_services.metadata" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Resource Conservation and Recovery Act (RCRA) Metadata Service
#
# POST /rcra_rest_services.metadata
export def "rcra-rest-services-metadata create" [
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
]: any -> record<Results: record<Message: string, ResultColumns: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rcra_rest_services.metadata")
  let req_body = {"output": $output} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}
