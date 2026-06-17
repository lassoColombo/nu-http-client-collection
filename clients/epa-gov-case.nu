# Auto-generated client for U.S. EPA Enforcement and Compliance History Online (ECHO) - Enforcement Case Search v1.0.0
# Source: https://api.apis.guru/v2/specs/epa.gov/case/1.0.0/swagger.json
# Auth: --token flag or $env.U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____ENFORCEMENT_CASE_SEARCH_TOKEN

const BASE_URL = "https://echodata.epa.gov/echo"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o U_S_EPA_ENFORCEMENT_AND_COMPLIANCE_HISTORY_ONLINE__ECHO____ENFORCEMENT_CASE_SEARCH_TOKEN | default "" }
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
def output-completer [] { ["JSON" "JSONP" "XML"] }
def p-case-lead-completer [] { ["E" "S"] }
def p-region-completer [] { ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10"] }
def p-sic-ao-naics-completer [] { ["AND" "OR"] }
def p-sic-primary-flg-completer [] { ["N" "Y"] }
def p-sic-frs-flg-completer [] { ["N" "Y"] }
def p-naics-primary-flg-completer [] { ["N" "Y"] }
def p-naics-frs-flg-completer [] { ["N" "Y"] }
def p-rank-order-completer [] { ["0" "1"] }
def p-tribal-completer [] { ["N" "Y"] }
def p-oeca-core-completer [] { ["N" "Y"] }
def p-multimedia-completer [] { ["N" "Y"] }
def p-fed-case-completer [] { ["N" "Y"] }
def p-fed-penalty-completer [] { ["ANY" "GT100000" "GT1000000" "GT2500000" "GT5000" "GT50000" "GT500000" "LE5000"] }
def p-comp-act-val-completer [] { ["ANY" "GT100000" "GT1000000" "GT5000" "GT50000000" "LE5000"] }
def p-sep-val-completer [] { ["ANY" "GT10000" "GT100000" "GT1000000" "GT50000" "GT500000" "LE10000"] }
def p-case-summary-type-completer [] { ["ALL" "CONTAINS" "WITHIN"] }
def p-usmex-completer [] { ["N" "Y"] }
def p-fntype-completer [] { ["ALL" "BEGINS" "CONTAINS" "EXACT"] }
def p-civil-criminal-indicator-completer [] { ["ALL" "CI" "CR"] }
def accept-completer [] { ["application/json" "application/xml"] }
def maplist-completer [] { ["N" "Y"] }
def tablelist-completer [] { ["N" "Y"] }
def descending-completer [] { ["N" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "case-rest-servicesget-case-info get" } } | get name | first)
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

# Enforcement Case Search (new version)
#
# GET /case_rest_services.get_case_info
export def "case-rest-servicesget-case-info get" [
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
  --p-case-category: string # Case Category Filter.  Enter one or more case category codes to filter results.   Provide multiple values as a comma-delimited list. - AFR = Administrative - Formal - AIF = Administrative - Informal - JDC = Judicial
  --p-case-status: string # Case Status Code Filter.  Enter one or more case status codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-milestone: string # Administrative or Judicial Milestone Filter.  Enter one or milestone values to restrict results.  Provide multiple values as a comma-delimited list.
  --p-from-date: string # Administrative or Judicial Milestone Date Range Start Limiter.  Enter a date value in MM/DD/YYYY format to limit milestone results.  Parameter p_to_date must also be populated when using this parameter option.
  --p-to-date: string # Administrative or Judicial Milestone Date Range End Limiter.  Enter a date value in MM/DD/YYYY format to limit milestone results.  Parameter p_from_date must also be populated when using this parameter option.
  --p-milestone-fy: string # Administrative or Judicial Milestone Fiscal Year Limiter.  Enter a single fiscal year value to limit milestone searches to a given fiscal year.
  --p-name: string # Case Name Filter.  Enter one or more case names to restrict results.  Provide multiple values as a comma-delimited list.  When using this parameter the p_name_type parameter is required.
  --p-name-type: string # Case Name Filter Modifier.
  --p-case-number: string # Case Number Filter.  Enter one or more case numbers to restrict results.  Provide multiple values as a comma-delimited list.
  --p-docket-number: string # DOJ Docket Number Filter.  Enter a single docket number or partial docket number to restrict results.  Use "%" as a wildcard for more complex filtering.
  --p-court-docket-number: string
  --p-activity-number: string # Case Activity Number Filter.  Enter a single case activity number to filter results.
  --p-case-lead: string@p-case-lead-completer # Case Lead Limiter.  Enter E or S to limit results. - E = EPA is the case lead. - S = The state is the case lead.
  --p-case-sens-flg: string # Case Sensitive Data Flag.  Enter a Y or N to include or exclude cases with sensitive data.
  --p-region: string@p-region-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-state: string # Case Location State Filter.  Enter one or more state USPS postal codes to filter results.  Provide multiple values as a comma-delimited list.
  --p-district: string # Case Location Court District Limiter.  Enter a single state court district code to limit results.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter.  Enter a single 4-digit SIC Code to filter results.
  --p-sic-ao-naics: string@p-sic-ao-naics-completer # Case Location SIC/NAICS And/Or Modifier.  Enter either AND or OR to govern the search logic of SIC and NAICS codes. - AND = Search will return results having both the provided SIC code(s) and provided NAICS code(s). - OR = Search will return results having either the provided SIC code(s) or the provided NAICS code(s).
  --p-sic-primary-flg: string@p-sic-primary-flg-completer # Case Location Primary SIC Flag.  Enter Y to limit SIC search results to primary SIC codes only.
  --p-sic-frs-flg: string@p-sic-frs-flg-completer # Case Location Extended FRS SIC Search Flag.  Enter Y to expand SIC search to include Federal Registry Service datasets.
  --p-naics: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes.  Digits less than six will match to all codes beginning with the provided values.
  --p-naics-primary-flg: string@p-naics-primary-flg-completer # Case Location Primary NAICS Flag.  Enter Y to limit NAICS search results to primary NAICS codes only.
  --p-naics-frs-flg: string@p-naics-frs-flg-completer # Case Location Extended FRS NAICS Search Flag.  Enter Y to expand NAICS search to include Federal Registry Service datasets.
  --p-enf-type: string # Case Enforcement Type Filter. Enter one or more case enforcement type codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-law: string # Law Statute Code Filter.  Enter a single statute code to limit results.
  --p-section: string # Law Section Code Filter. Enter one or more law section codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-cp-citation: string # Law Section Code Filter Alternative. Enter a single law section code to limit results.  This parameter accepts partial codes and allows for advanced search modifiers.
  --p-rank-order: string@p-rank-order-completer # Law Status Rank Order Limiter.  Enter a single integer rank order to limit results.
  --p-enf-program: string # Enforcement Program Code Limiter.  Enter one or more enforcement program codes to limit results.  Provide multiple values as a comma-delimited list.  
  --p-violation: string # Violation Type Code Filter.  Enter one or more violation type codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-priority-area: string # Case Priority Area Filter.  Enter one or more case priority areas to limit results.  Provide multiple values as a comma-delimited list.
  --p-priority-area-desc: string # Case Priority Area Description Filter.  Enter a single case priority area description or partial case priority area description to limit results.  Use "%" as a wild-card match for more complex searches.
  --p-tribal: string@p-tribal-completer # Case Location Tribal Land Flag.  Enter Y or N to include or disallow cases on tribal land.
  --p-oeca-core: string@p-oeca-core-completer # OECA Core Program Flag.  Enter Y or N to include or exclude core program cases.
  --p-multimedia: string@p-multimedia-completer # Enforcement Multimedia Case Flag.  Enter Y or N to include or exclude multimedia cases.
  --p-fed-case: string@p-fed-case-completer # Federal Facility Involvement Flag.  Enter a Y or N to include or exclude cases involving federal facilities.
  --p-activity-contact: string # Activity Contact Last Name Filter.  Enter a single last name or partial last name to filter results.  Use "%" as a wild-card for advanced searching.
  --p-role: string # Activity Contact Role Code Filter.  Enter a single role code to restrict results.
  --p-fed-penalty: string@p-fed-penalty-completer # Federal Penalty Assessed Amount Filter.  Provide one of the following keywords to restrict results. - ANY = cases with any penalty amount. - LE5000 = cases with penalty amount less than or equal to $5,000. - GT5000 = cases with penalty amount more than $5,000. - GT50000 = cases with penalty amount more than $50,000. - GT100000 = cases with penalty amount more than $100,000. - GT500000 = cases with penalty amount more than $500,000. - GT1000000 = cases with penalty amount more than $1,000,000. - GT2500000 = cases with penalty amount more than $2,500,000.
  --p-total-fed-penalty: string # Total Federal Penalty Limiter.  Enter a keyword value to limit results to cases with given total federal penalties. - ANY = Cases with any federal penalty greater than zero. - LEXX = Replacing XX with a dollar value, return cases with federal penalty less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with federal penalty greater than the given amount.
  --p-cost-recovery: string # Cost Recovery Awarded Amount Limiter.  Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-total-cost-recovery: string # Total Cost Recovery Amount Limiter.  Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-complying-actions: string # Complying Actions Type Code Limiter.  Enter one or more complying action codes to restrict results.  Provide multiple values as a comma-delimited list.
  --p-comp-act-val: string@p-comp-act-val-completer # Compliance Action Cost Limiter. Enter a keyword value to limit results to cases with given compliance cost amounts. - ANY = Cases with any compliance cost amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with compliance cost amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with compliance cost amount greater than the given amount.
  --p-total-comp-act-val: string # Total Compliance Action Amount Limiter.  Enter a keyword value to limit results to cases with given total compliance action amounts. - ANY = Cases with any total compliance action amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with total compliance action amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with total compliance action amount greater than the given amount.
  --p-sep-cats: string # Supplemental Environmental Projects Activity Category Code Limiter.  Provide one or more SEP activity category codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-sep-val: string@p-sep-val-completer # Supplemental Environmental Projects Activity Value Limiter.  Provide a keyword to limit results. - ANY = return cases with any SEP activity amount. - LE10000 = return cases with SEP activity amount less than or equal to $10,000. - GT10000 = return cases with SEP activity amount greater than $10,000. - GT50000 = return cases with SEP activity amount greater than $50,000. - GT100000 = return cases with SEP activity amount greater than $100,000. - GT500000 = return cases with SEP activity amount greater than $500,000. - GT1000000 = return cases with SEP activity amount greater than $1,000,000.
  --p-total-sep-val: string # Supplemental Environmental Projects Total Value Limiter.  Provide a keyword to limit results. - ANY = return cases with any SEP total amount. - LE10000 = return cases with SEP total amount less than or equal to $10,000. - GT10000 = return cases with SEP total amount greater than $10,000. - GT50000 = return cases with SEP total amount greater than $50,000. - GT100000 = return cases with SEP total amount greater than $100,000. - GT500000 = return cases with SEP total amount greater than $500,000. - GT1000000 = return cases with SEP total amount greater than $1,000,000.
  --p-lodged-date: string # Settlement Lodged Date Limiter.  Enter a single settlement lodged date in MM/DD/YYYY format to limit results.
  --p-entered-date: string # Settlement Entered Date Limiter.  Enter a single settlement entered date in MM/DD/YYYY format to limit results.
  --p-facility-id: string # Case Facility Registration Identifier Limiter.  Enter a single complete facility identifier to limit results.
  --p-fac-city: string # Case Facility City Limiter.  Enter a single complete city name to filter cases by facility location city.
  --p-fac-zip: string # Case Facility ZIP Code Limiter.  Enter a single 5-digit zip code to filter cases by facility location zip code.
  --p-fac-county: string # Case Facility County Limiter.  Enter a single complete county name to filter cases by facility location county name.
  --p-case-summary: string # Case Summary Search Limiter.  Enter a single case summary to limit results.  This parameter accepts partial codes and allows for advanced search modifiers.
  --p-case-summary-type: string@p-case-summary-type-completer # Identifies how the the search terms enterened in p_case_summary are searched.  Valid values are ALL (Default), WITHIN, and CONTAINS.  Must be used with p_case_summary.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag.  Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-c1lat: float # In decimal degrees.  Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees.  Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees.  Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees.  Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-voluntary: string # Voluntary Self Disclosure Flag.  Enter Y or N to include or exclude cases results having voluntary disclosure.
  --p-fed-indicator: string # Federal Facility/Cross Media Flag.  Enter Y or N to limit results to cases with federal facility cross media.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS = 
  --p-civil-criminal-indicator: string@p-civil-criminal-indicator-completer # Civil/Criminal Case Limiter.  Provide a keyword to limit results. - ANY = return both civil and criminal cases. - CI = return only civil cases. - CR = return only criminal cases.
  --queryset: float # Query Limiter.  Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --mapset: string # Identifies the maxium number of case facilities to return from the case_rest_services.get_case_info query. (default: 1400)
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output.  A list of comma-separated column IDs of output objects that will be returned in the service query object or download.  Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-pretty-print: float # Optional flag to request GeoJSON formatted results to be pretty printed.  Only provide a numeric value when the output needs to be human readable as pretty printing has a performance cost.
  --p-ocmap-fy: string # Fiscal Year to select cases that are displayed in the Office of Complicance Fiscal Year Map Services
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-has-map: string
]: nothing -> record<Results: record<AFRRows: string, CERCLARows: string, CWARows: string, Cases: list<record>, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapLocations: string, Message: string, QueryParameters: list<record>, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_case_category" $p_case_category "scalar") (serialize-qp "p_case_status" $p_case_status "scalar") (serialize-qp "p_milestone" $p_milestone "scalar") (serialize-qp "p_from_date" $p_from_date "scalar") (serialize-qp "p_to_date" $p_to_date "scalar") (serialize-qp "p_milestone_fy" $p_milestone_fy "scalar") (serialize-qp "p_name" $p_name "scalar") (serialize-qp "p_name_type" $p_name_type "scalar") (serialize-qp "p_case_number" $p_case_number "scalar") (serialize-qp "p_docket_number" $p_docket_number "scalar") (serialize-qp "p_court_docket_number" $p_court_docket_number "scalar") (serialize-qp "p_activity_number" $p_activity_number "scalar") (serialize-qp "p_case_lead" $p_case_lead "scalar") (serialize-qp "p_case_sens_flg" $p_case_sens_flg "scalar") (serialize-qp "p_region" $p_region "scalar") (serialize-qp "p_state" $p_state "scalar") (serialize-qp "p_district" $p_district "scalar") (serialize-qp "p_sic" $p_sic "scalar") (serialize-qp "p_sic_ao_naics" $p_sic_ao_naics "scalar") (serialize-qp "p_sic_primary_flg" $p_sic_primary_flg "scalar") (serialize-qp "p_sic_frs_flg" $p_sic_frs_flg "scalar") (serialize-qp "p_naics" $p_naics "scalar") (serialize-qp "p_naics_primary_flg" $p_naics_primary_flg "scalar") (serialize-qp "p_naics_frs_flg" $p_naics_frs_flg "scalar") (serialize-qp "p_enf_type" $p_enf_type "scalar") (serialize-qp "p_law" $p_law "scalar") (serialize-qp "p_section" $p_section "scalar") (serialize-qp "p_cp_citation" $p_cp_citation "scalar") (serialize-qp "p_rank_order" $p_rank_order "scalar") (serialize-qp "p_enf_program" $p_enf_program "scalar") (serialize-qp "p_violation" $p_violation "scalar") (serialize-qp "p_priority_area" $p_priority_area "scalar") (serialize-qp "p_priority_area_desc" $p_priority_area_desc "scalar") (serialize-qp "p_tribal" $p_tribal "scalar") (serialize-qp "p_oeca_core" $p_oeca_core "scalar") (serialize-qp "p_multimedia" $p_multimedia "scalar") (serialize-qp "p_fed_case" $p_fed_case "scalar") (serialize-qp "p_activity_contact" $p_activity_contact "scalar") (serialize-qp "p_role" $p_role "scalar") (serialize-qp "p_fed_penalty" $p_fed_penalty "scalar") (serialize-qp "p_total_fed_penalty" $p_total_fed_penalty "scalar") (serialize-qp "p_cost_recovery" $p_cost_recovery "scalar") (serialize-qp "p_total_cost_recovery" $p_total_cost_recovery "scalar") (serialize-qp "p_complying_actions" $p_complying_actions "scalar") (serialize-qp "p_comp_act_val" $p_comp_act_val "scalar") (serialize-qp "p_total_comp_act_val" $p_total_comp_act_val "scalar") (serialize-qp "p_sep_cats" $p_sep_cats "scalar") (serialize-qp "p_sep_val" $p_sep_val "scalar") (serialize-qp "p_total_sep_val" $p_total_sep_val "scalar") (serialize-qp "p_lodged_date" $p_lodged_date "scalar") (serialize-qp "p_entered_date" $p_entered_date "scalar") (serialize-qp "p_facility_id" $p_facility_id "scalar") (serialize-qp "p_fac_city" $p_fac_city "scalar") (serialize-qp "p_fac_zip" $p_fac_zip "scalar") (serialize-qp "p_fac_county" $p_fac_county "scalar") (serialize-qp "p_case_summary" $p_case_summary "scalar") (serialize-qp "p_case_summary_type" $p_case_summary_type "scalar") (serialize-qp "p_usmex" $p_usmex "scalar") (serialize-qp "p_c1lat" $p_c1lat "scalar") (serialize-qp "p_c1lon" $p_c1lon "scalar") (serialize-qp "p_c2lat" $p_c2lat "scalar") (serialize-qp "p_c2lon" $p_c2lon "scalar") (serialize-qp "p_voluntary" $p_voluntary "scalar") (serialize-qp "p_fed_indicator" $p_fed_indicator "scalar") (serialize-qp "p_fntype" $p_fntype "scalar") (serialize-qp "p_civil_criminal_indicator" $p_civil_criminal_indicator "scalar") (serialize-qp "queryset" $queryset "scalar") (serialize-qp "responseset" $responseset "scalar") (serialize-qp "mapset" $mapset "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "qcolumns" $qcolumns "scalar") (serialize-qp "p_pretty_print" $p_pretty_print "scalar") (serialize-qp "p_ocmap_fy" $p_ocmap_fy "scalar") (serialize-qp "p_qs" $p_qs "scalar") (serialize-qp "p_has_map" $p_has_map "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_case_info" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Case Search (new version)
#
# POST /case_rest_services.get_case_info
export def "case-rest-servicesget-case-info post" [
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
]: any -> record<Results: record<AFRRows: string, CERCLARows: string, CWARows: string, Cases: list<record>, ClusterOutput: record<ClusterData: list>, ClusterRecords: string, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapLocations: string, Message: string, QueryParameters: list<record>, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/case_rest_services.get_case_info")
  let body = {"output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enforcement Case Summary Report Search
#
# GET /case_rest_services.get_case_report
export def "case-rest-servicesget-case-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --p-id: string # Case Number. Enter the case number identifier to retrieve the case report.
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<CAEDDocuments: list<record>, CaseInformation: record<Branch: string, CaseName: string, CaseNumber: string, CaseStatus: string, CaseStatusDate: string, CaseSummary: string, CaseType: string, DOJDocketNumber: string, EnforcementOutcome: string, EnforcementType: string, HeadquartersDivision: string, Lead: string, MultiMediaCase: string, RegionalDocketNumber: string, ReliefSought: string, ResultVolDisclosure: string, TotalComplianceActionCost: string, TotalCostRecovery: string, TotalFederalPenalty: string, TotalSEPCost: string, TotalStatePenalty: string, Violations: string>, CaseMilestones: list<record>, Citations: list<record>, Defendants: list<record>, EnforcementConclusions: list<record>, Facilities: list<record>, LawsAndSections: list<record>, Message: string, Pollutants: list<record>, ProgramLinks: list<record>, RelatedActivities: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_case_report" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Case Summary Report Search
#
# POST /case_rest_services.get_case_report
export def "case-rest-servicesget-case-report post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --p-id: string # Case Number. Enter the case number identifier to retrieve the case report.
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
]: any -> record<Results: record<CAEDDocuments: list<record>, CaseInformation: record<Branch: string, CaseName: string, CaseNumber: string, CaseStatus: string, CaseStatusDate: string, CaseSummary: string, CaseType: string, DOJDocketNumber: string, EnforcementOutcome: string, EnforcementType: string, HeadquartersDivision: string, Lead: string, MultiMediaCase: string, RegionalDocketNumber: string, ReliefSought: string, ResultVolDisclosure: string, TotalComplianceActionCost: string, TotalCostRecovery: string, TotalFederalPenalty: string, TotalSEPCost: string, TotalStatePenalty: string, Violations: string>, CaseMilestones: list<record>, Citations: list<record>, Defendants: list<record>, EnforcementConclusions: list<record>, Facilities: list<record>, LawsAndSections: list<record>, Message: string, Pollutants: list<record>, ProgramLinks: list<record>, RelatedActivities: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/case_rest_services.get_case_report")
  let body = {"p_id": $p_id, "output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enforcement Case Search
#
# GET /case_rest_services.get_cases
export def "case-rest-servicesget-cases get" [
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
  --p-case-category: string # Case Category Filter.  Enter one or more case category codes to filter results.   Provide multiple values as a comma-delimited list. - AFR = Administrative - Formal - AIF = Administrative - Informal - JDC = Judicial
  --p-case-status: string # Case Status Code Filter.  Enter one or more case status codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-violation: string # Violation Type Code Filter.  Enter one or more violation type codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-milestone: string # Administrative or Judicial Milestone Filter.  Enter one or milestone values to restrict results.  Provide multiple values as a comma-delimited list.
  --p-from-date: string # Administrative or Judicial Milestone Date Range Start Limiter.  Enter a date value in MM/DD/YYYY format to limit milestone results.  Parameter p_to_date must also be populated when using this parameter option.
  --p-to-date: string # Administrative or Judicial Milestone Date Range End Limiter.  Enter a date value in MM/DD/YYYY format to limit milestone results.  Parameter p_from_date must also be populated when using this parameter option.
  --p-milestone-fy: string # Administrative or Judicial Milestone Fiscal Year Limiter.  Enter a single fiscal year value to limit milestone searches to a given fiscal year.
  --p-name: string # Case Name Filter.  Enter one or more case names to restrict results.  Provide multiple values as a comma-delimited list.  When using this parameter the p_name_type parameter is required.
  --p-name-type: string # Case Name Filter Modifier.
  --p-case-number: string # Case Number Filter.  Enter one or more case numbers to restrict results.  Provide multiple values as a comma-delimited list.
  --p-docket-number: string # DOJ Docket Number Filter.  Enter a single docket number or partial docket number to restrict results.  Use "%" as a wildcard for more complex filtering.
  --p-court-docket-number: string
  --p-activity-number: string # Case Activity Number Filter.  Enter a single case activity number to filter results.
  --p-case-lead: string@p-case-lead-completer # Case Lead Limiter.  Enter E or S to limit results. - E = EPA is the case lead. - S = The state is the case lead.
  --p-case-sens-flg: string # Case Sensitive Data Flag.  Enter a Y or N to include or exclude cases with sensitive data.
  --p-region: string@p-region-completer # EPA Region Filter. Provide a single value of 01 thru 10 to restrict results to a single EPA region.
  --p-state: string # Case Location State Filter.  Enter one or more state USPS postal codes to filter results.  Provide multiple values as a comma-delimited list.
  --p-district: string # Case Location Court District Limiter.  Enter a single state court district code to limit results.
  --p-sic: string # Standard Industrial Classification (SIC) Code Filter.  Enter a single 4-digit SIC Code to filter results.
  --p-sic-ao-naics: string@p-sic-ao-naics-completer # Case Location SIC/NAICS And/Or Modifier.  Enter either AND or OR to govern the search logic of SIC and NAICS codes. - AND = Search will return results having both the provided SIC code(s) and provided NAICS code(s). - OR = Search will return results having either the provided SIC code(s) or the provided NAICS code(s).
  --p-sic-primary-flg: string@p-sic-primary-flg-completer # Case Location Primary SIC Flag.  Enter Y to limit SIC search results to primary SIC codes only.
  --p-sic-frs-flg: string@p-sic-frs-flg-completer # Case Location Extended FRS SIC Search Flag.  Enter Y to expand SIC search to include Federal Registry Service datasets.
  --p-naics: string # North American Industry Classification System Filter. Enter two to six digits to filter results to facilities having matching NAICS codes.  Digits less than six will match to all codes beginning with the provided values.
  --p-naics-primary-flg: string@p-naics-primary-flg-completer # Case Location Primary NAICS Flag.  Enter Y to limit NAICS search results to primary NAICS codes only.
  --p-naics-frs-flg: string@p-naics-frs-flg-completer # Case Location Extended FRS NAICS Search Flag.  Enter Y to expand NAICS search to include Federal Registry Service datasets.
  --p-enf-type: string # Case Enforcement Type Filter. Enter one or more case enforcement type codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-law: string # Law Statute Code Filter.  Enter a single statute code to limit results.
  --p-section: string # Law Section Code Filter. Enter one or more law section codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-cp-citation: string # Law Section Code Filter Alternative. Enter a single law section code to limit results.  This parameter accepts partial codes and allows for advanced search modifiers.
  --p-rank-order: string@p-rank-order-completer # Law Status Rank Order Limiter.  Enter a single integer rank order to limit results.
  --p-enf-program: string # Enforcement Program Code Limiter.  Enter one or more enforcement program codes to limit results.  Provide multiple values as a comma-delimited list.  
  --p-priority-area: string # Case Priority Area Filter.  Enter one or more case priority areas to limit results.  Provide multiple values as a comma-delimited list.
  --p-priority-area-desc: string # Case Priority Area Description Filter.  Enter a single case priority area description or partial case priority area description to limit results.  Use "%" as a wild-card match for more complex searches.
  --p-tribal: string@p-tribal-completer # Case Location Tribal Land Flag.  Enter Y or N to include or disallow cases on tribal land.
  --p-oeca-core: string@p-oeca-core-completer # OECA Core Program Flag.  Enter Y or N to include or exclude core program cases.
  --p-multimedia: string@p-multimedia-completer # Enforcement Multimedia Case Flag.  Enter Y or N to include or exclude multimedia cases.
  --p-fed-case: string@p-fed-case-completer # Federal Facility Involvement Flag.  Enter a Y or N to include or exclude cases involving federal facilities.
  --p-activity-contact: string # Activity Contact Last Name Filter.  Enter a single last name or partial last name to filter results.  Use "%" as a wild-card for advanced searching.
  --p-role: string # Activity Contact Role Code Filter.  Enter a single role code to restrict results.
  --p-fed-penalty: string@p-fed-penalty-completer # Federal Penalty Assessed Amount Filter.  Provide one of the following keywords to restrict results. - ANY = cases with any penalty amount. - LE5000 = cases with penalty amount less than or equal to $5,000. - GT5000 = cases with penalty amount more than $5,000. - GT50000 = cases with penalty amount more than $50,000. - GT100000 = cases with penalty amount more than $100,000. - GT500000 = cases with penalty amount more than $500,000. - GT1000000 = cases with penalty amount more than $1,000,000. - GT2500000 = cases with penalty amount more than $2,500,000.
  --p-total-fed-penalty: string # Total Federal Penalty Limiter.  Enter a keyword value to limit results to cases with given total federal penalties. - ANY = Cases with any federal penalty greater than zero. - LEXX = Replacing XX with a dollar value, return cases with federal penalty less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with federal penalty greater than the given amount.
  --p-cost-recovery: string # Cost Recovery Awarded Amount Limiter.  Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-total-cost-recovery: string # Total Cost Recovery Amount Limiter.  Enter a keyword value to limit results to cases with given cost recovery amounts. - ANY = Cases with any cost recovery amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with cost recovery amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with cost recovery amount greater than the given amount.
  --p-complying-actions: string # Complying Actions Type Code Limiter.  Enter one or more complying action codes to restrict results.  Provide multiple values as a comma-delimited list.
  --p-comp-act-val: string@p-comp-act-val-completer # Compliance Action Cost Limiter. Enter a keyword value to limit results to cases with given compliance cost amounts. - ANY = Cases with any compliance cost amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with compliance cost amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with compliance cost amount greater than the given amount.
  --p-total-comp-act-val: string # Total Compliance Action Amount Limiter.  Enter a keyword value to limit results to cases with given total compliance action amounts. - ANY = Cases with any total compliance action amount greater than zero. - LEXX = Replacing XX with a dollar value, return cases with total compliance action amount less than or equal to the given amount. - GTXX = Replacing XX with a dollar value, return cases with total compliance action amount greater than the given amount.
  --p-sep-cats: string # Supplemental Environmental Projects Activity Category Code Limiter.  Provide one or more SEP activity category codes to limit results.  Provide multiple values as a comma-delimited list.
  --p-sep-val: string@p-sep-val-completer # Supplemental Environmental Projects Activity Value Limiter.  Provide a keyword to limit results. - ANY = return cases with any SEP activity amount. - LE10000 = return cases with SEP activity amount less than or equal to $10,000. - GT10000 = return cases with SEP activity amount greater than $10,000. - GT50000 = return cases with SEP activity amount greater than $50,000. - GT100000 = return cases with SEP activity amount greater than $100,000. - GT500000 = return cases with SEP activity amount greater than $500,000. - GT1000000 = return cases with SEP activity amount greater than $1,000,000.
  --p-total-sep-val: string # Supplemental Environmental Projects Total Value Limiter.  Provide a keyword to limit results. - ANY = return cases with any SEP total amount. - LE10000 = return cases with SEP total amount less than or equal to $10,000. - GT10000 = return cases with SEP total amount greater than $10,000. - GT50000 = return cases with SEP total amount greater than $50,000. - GT100000 = return cases with SEP total amount greater than $100,000. - GT500000 = return cases with SEP total amount greater than $500,000. - GT1000000 = return cases with SEP total amount greater than $1,000,000.
  --p-lodged-date: string # Settlement Lodged Date Limiter.  Enter a single settlement lodged date in MM/DD/YYYY format to limit results.
  --p-entered-date: string # Settlement Entered Date Limiter.  Enter a single settlement entered date in MM/DD/YYYY format to limit results.
  --p-facility-id: string # Case Facility Registration Identifier Limiter.  Enter a single complete facility identifier to limit results.
  --p-fac-city: string # Case Facility City Limiter.  Enter a single complete city name to filter cases by facility location city.
  --p-fac-zip: string # Case Facility ZIP Code Limiter.  Enter a single 5-digit zip code to filter cases by facility location zip code.
  --p-fac-county: string # Case Facility County Limiter.  Enter a single complete county name to filter cases by facility location county name.
  --p-case-summary: string # Case Summary Search Limiter.  Enter a single case summary to limit results.  This parameter accepts partial codes and allows for advanced search modifiers.
  --p-case-summary-type: string@p-case-summary-type-completer # Identifies how the the search terms enterened in p_case_summary are searched.  Valid values are ALL (Default), WITHIN, and CONTAINS.  Must be used with p_case_summary.
  --p-usmex: string@p-usmex-completer # US-Mexico Border Flag.  Enter Y/N to restrict searches to facilities located within 100KM of the border.
  --p-c1lat: float # In decimal degrees.  Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c1lon: float # In decimal degrees.  Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lat: float # In decimal degrees.  Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-c2lon: float # In decimal degrees.  Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --p-voluntary: string # Voluntary Self Disclosure Flag.  Enter Y or N to include or exclude cases results having voluntary disclosure.
  --p-fed-indicator: string # Federal Facility/Cross Media Flag.  Enter Y or N to limit results to cases with federal facility cross media.
  --p-fntype: string@p-fntype-completer # Controls type of text search performed on facility name with parameter p_fn. - EXACT = Find facilities having the exact provided name(s). - BEGINS = Find facilities with names starting with the provided term(s). - ALL = Find facilities using Oracle text search terms. - CONTAINS = 
  --p-civil-criminal-indicator: string@p-civil-criminal-indicator-completer # Civil/Criminal Case Limiter.  Provide a keyword to limit results. - ANY = return both civil and criminal cases. - CI = return only civil cases. - CR = return only criminal cases.
  --queryset: float # Query Limiter.  Enter a value to limit the number of records returned for each query. Value cannot exceed 70,000.
  --responseset: float # Response Set Limiter. Enter a value to limit the number of records per page. Value cannot exceed 1,000.
  --maplist: string@maplist-completer # Map List Flag.  Provide a Y to return mappable coordinates representing the full geographic extent of the queryset (all facilities that met the selection criteria).
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
  --qcolumns: string # Used to customize service output.  A list of comma-separated column IDs of output objects that will be returned in the service query object or download.  Use the metadata service endpoint for a complete list of Ids and definitions.
  --p-ocmap-fy: string # Fiscal Year to select cases that are displayed in the Office of Complicance Fiscal Year Map Services
  --p-qs: string # Quick Search. Allows entry for city, state, and/or zip code.
  --p-has-map: string
]: nothing -> record<Results: record<AFRRows: string, CAARows: string, CERCLARows: string, CWARows: string, Cases: list<record>, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "p_case_category" $p_case_category "scalar") (serialize-qp "p_case_status" $p_case_status "scalar") (serialize-qp "p_violation" $p_violation "scalar") (serialize-qp "p_milestone" $p_milestone "scalar") (serialize-qp "p_from_date" $p_from_date "scalar") (serialize-qp "p_to_date" $p_to_date "scalar") (serialize-qp "p_milestone_fy" $p_milestone_fy "scalar") (serialize-qp "p_name" $p_name "scalar") (serialize-qp "p_name_type" $p_name_type "scalar") (serialize-qp "p_case_number" $p_case_number "scalar") (serialize-qp "p_docket_number" $p_docket_number "scalar") (serialize-qp "p_court_docket_number" $p_court_docket_number "scalar") (serialize-qp "p_activity_number" $p_activity_number "scalar") (serialize-qp "p_case_lead" $p_case_lead "scalar") (serialize-qp "p_case_sens_flg" $p_case_sens_flg "scalar") (serialize-qp "p_region" $p_region "scalar") (serialize-qp "p_state" $p_state "scalar") (serialize-qp "p_district" $p_district "scalar") (serialize-qp "p_sic" $p_sic "scalar") (serialize-qp "p_sic_ao_naics" $p_sic_ao_naics "scalar") (serialize-qp "p_sic_primary_flg" $p_sic_primary_flg "scalar") (serialize-qp "p_sic_frs_flg" $p_sic_frs_flg "scalar") (serialize-qp "p_naics" $p_naics "scalar") (serialize-qp "p_naics_primary_flg" $p_naics_primary_flg "scalar") (serialize-qp "p_naics_frs_flg" $p_naics_frs_flg "scalar") (serialize-qp "p_enf_type" $p_enf_type "scalar") (serialize-qp "p_law" $p_law "scalar") (serialize-qp "p_section" $p_section "scalar") (serialize-qp "p_cp_citation" $p_cp_citation "scalar") (serialize-qp "p_rank_order" $p_rank_order "scalar") (serialize-qp "p_enf_program" $p_enf_program "scalar") (serialize-qp "p_priority_area" $p_priority_area "scalar") (serialize-qp "p_priority_area_desc" $p_priority_area_desc "scalar") (serialize-qp "p_tribal" $p_tribal "scalar") (serialize-qp "p_oeca_core" $p_oeca_core "scalar") (serialize-qp "p_multimedia" $p_multimedia "scalar") (serialize-qp "p_fed_case" $p_fed_case "scalar") (serialize-qp "p_activity_contact" $p_activity_contact "scalar") (serialize-qp "p_role" $p_role "scalar") (serialize-qp "p_fed_penalty" $p_fed_penalty "scalar") (serialize-qp "p_total_fed_penalty" $p_total_fed_penalty "scalar") (serialize-qp "p_cost_recovery" $p_cost_recovery "scalar") (serialize-qp "p_total_cost_recovery" $p_total_cost_recovery "scalar") (serialize-qp "p_complying_actions" $p_complying_actions "scalar") (serialize-qp "p_comp_act_val" $p_comp_act_val "scalar") (serialize-qp "p_total_comp_act_val" $p_total_comp_act_val "scalar") (serialize-qp "p_sep_cats" $p_sep_cats "scalar") (serialize-qp "p_sep_val" $p_sep_val "scalar") (serialize-qp "p_total_sep_val" $p_total_sep_val "scalar") (serialize-qp "p_lodged_date" $p_lodged_date "scalar") (serialize-qp "p_entered_date" $p_entered_date "scalar") (serialize-qp "p_facility_id" $p_facility_id "scalar") (serialize-qp "p_fac_city" $p_fac_city "scalar") (serialize-qp "p_fac_zip" $p_fac_zip "scalar") (serialize-qp "p_fac_county" $p_fac_county "scalar") (serialize-qp "p_case_summary" $p_case_summary "scalar") (serialize-qp "p_case_summary_type" $p_case_summary_type "scalar") (serialize-qp "p_usmex" $p_usmex "scalar") (serialize-qp "p_c1lat" $p_c1lat "scalar") (serialize-qp "p_c1lon" $p_c1lon "scalar") (serialize-qp "p_c2lat" $p_c2lat "scalar") (serialize-qp "p_c2lon" $p_c2lon "scalar") (serialize-qp "p_voluntary" $p_voluntary "scalar") (serialize-qp "p_fed_indicator" $p_fed_indicator "scalar") (serialize-qp "p_fntype" $p_fntype "scalar") (serialize-qp "p_civil_criminal_indicator" $p_civil_criminal_indicator "scalar") (serialize-qp "queryset" $queryset "scalar") (serialize-qp "responseset" $responseset "scalar") (serialize-qp "maplist" $maplist "scalar") (serialize-qp "tablelist" $tablelist "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "qcolumns" $qcolumns "scalar") (serialize-qp "p_ocmap_fy" $p_ocmap_fy "scalar") (serialize-qp "p_qs" $p_qs "scalar") (serialize-qp "p_has_map" $p_has_map "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_cases" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Case Search
#
# POST /case_rest_services.get_cases
export def "case-rest-servicesget-cases post" [
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
]: any -> record<Results: record<AFRRows: string, CAARows: string, CERCLARows: string, CWARows: string, Cases: list<record>, CriminalRows: string, EPCRARows: string, FIFRARows: string, FedPenRows: string, FederalRows: string, JDCRows: string, MapOutput: record<IconBaseURL: string, MapData: list, PopUpBaseURL: string, QueryID: string>, Message: string, PageNo: string, QueryID: string, QueryRows: string, RCRARows: string, SDWARows: string, SEPRows: string, TSCARows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/case_rest_services.get_cases")
  let body = {"output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Placeholder
#
# GET /case_rest_services.get_cases_from_facility
export def "case-rest-servicesget-cases-from-facility get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --p-id: string # Identifier for the service.
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Results: record<CaseNumbers: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_cases_from_facility" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Placeholder
#
# POST /case_rest_services.get_cases_from_facility
export def "case-rest-servicesget-cases-from-facility post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --p-id: string # Identifier for the service.
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Results: record<CaseNumbers: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_cases_from_facility" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Criminal Case Summary Report Search
#
# GET /case_rest_services.get_crcase_report
export def "case-rest-servicesget-crcase-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --p-id: string # Prosecution Summary Identifier. Enter the numeric prosecution summary identifier to retrieve the criminal case report.
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
  --mapset: string # Identifies the maxium number of case facilities to return from the case_rest_services.get_case_info query. (default: 1400)
]: nothing -> record<Results: record<CRCaseInformation: record<CaseIdentifier: string, CaseSummary: string, Citations: string, FiscalYear: string, Statutes: string>, CRDefendants: list<record>, CRDetails: list<record>, Locations: list<record>, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "mapset" $mapset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_crcase_report" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Criminal Case Summary Report Search
#
# POST /case_rest_services.get_crcase_report
export def "case-rest-servicesget-crcase-report post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --p-id: string # Prosecution Summary Identifier. Enter the numeric prosecution summary identifier to retrieve the criminal case report.
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
]: any -> record<Results: record<CRCaseInformation: record<CaseIdentifier: string, CaseSummary: string, Citations: string, FiscalYear: string, Statutes: string>, CRDefendants: list<record>, CRDetails: list<record>, Locations: list<record>, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/case_rest_services.get_crcase_report")
  let body = {"p_id": $p_id, "output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enforcement Case Download Data Service
#
# GET /case_rest_services.get_download
export def "case-rest-servicesget-download get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string # Output Format Flag.  Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default).
  --qid: string # Query ID Selector.  Enter the QueryID number from a previously run query.
  --qcolumns: string # Used to customize service output.  A list of comma-separated column IDs of output objects that will be returned in the service query object or download.  Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "qcolumns" $qcolumns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_download" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Case Download Data Service
#
# POST /case_rest_services.get_download
export def "case-rest-servicesget-download post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --output: string # Output Format Flag.  Enter one of the following keywords: - CSV = Facility results formatted as comma delimited file download (default).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/case_rest_services.get_download")
  let body = {"output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Placeholder
#
# GET /case_rest_services.get_facilities_from_case
export def "case-rest-servicesget-facilities-from-case get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --p-id: string # Identifier for the service.
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Results: record<RegistryIDs: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_facilities_from_case" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Placeholder
#
# POST /case_rest_services.get_facilities_from_case
export def "case-rest-servicesget-facilities-from-case post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --p-id: string # Identifier for the service.
  --output: string@output-completer # Output Format Flag.  Enter one of the following keywords: - JSON = Data model formatted as Javascript Object Notation (default). - JSONP = Data model formatted as Javascript Object Notation with Padding.   - XML = Data model formatted as Extensible Markup Language.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Results: record<RegistryIDs: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p_id" $p_id "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_facilities_from_case" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Case Map Service
#
# GET /case_rest_services.get_map
export def "case-rest-servicesget-map get" [
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
  --qid: string # Query ID Selector.  Enter the QueryID number from a previously run query.
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
  --tablelist: string@tablelist-completer # Table List Flag. Enter a Y to display the first page of facility results.
  --c1-lat: float # Latitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c1-long: float # Longitude of 1st corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-lat: float # Latitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
  --c2-long: float # Longitude of 2nd corner of box that bounds the resulting facilities. The latitude and longitude of both corners of the bounding box must be provided.
]: nothing -> record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "tablelist" $tablelist "scalar") (serialize-qp "c1_lat" $c1_lat "scalar") (serialize-qp "c1_long" $c1_long "scalar") (serialize-qp "c2_lat" $c2_lat "scalar") (serialize-qp "c2_long" $c2_long "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_map" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Case Map Service
#
# POST /case_rest_services.get_map
export def "case-rest-servicesget-map post" [
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
]: any -> record<MapOutput: record<IconBaseURL: string, MapData: list<record>, PopUpBaseURL: string, QueryID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/case_rest_services.get_map")
  let body = {"output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enforcement Case Paginated Results Service
#
# GET /case_rest_services.get_qid
export def "case-rest-servicesget-qid get" [
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
  --qid: string # Query ID Selector.  Enter the QueryID number from a previously run query.
  --pageno: float # Indicates the number of the page to display. It is used only when the results are paginated. (default: 1)
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
  --newsort: float # Output Sort Column.  Enter the number of the column on which the data will be sorted. If unpopulated results will sort on the first column.
  --descending: string@descending-completer # Output Sort Column Descending Flag.  Enter Y to column identified in the newsort parameter descending.  Enter N to use ascending sort order. Used only when newsort parameter is populated.
  --qcolumns: string # Used to customize service output.  A list of comma-separated column IDs of output objects that will be returned in the service query object or download.  Use the metadata service endpoint for a complete list of Ids and definitions.
]: nothing -> record<Results: record<Cases: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "qid" $qid "scalar") (serialize-qp "pageno" $pageno "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "newsort" $newsort "scalar") (serialize-qp "descending" $descending "scalar") (serialize-qp "qcolumns" $qcolumns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.get_qid" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Case Paginated Results Service
#
# POST /case_rest_services.get_qid
export def "case-rest-servicesget-qid post" [
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
]: any -> record<Results: record<Cases: list<record>, Message: string, PageNo: string, QueryID: string, QueryRows: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/case_rest_services.get_qid")
  let body = {"output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enforcement Case Metadata Service
#
# GET /case_rest_services.metadata
export def "case-rest-servicesmetadata get" [
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
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
]: nothing -> record<Results: record<Message: string, ResultColumns: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/case_rest_services.metadata" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enforcement Case Metadata Service
#
# POST /case_rest_services.metadata
export def "case-rest-servicesmetadata post" [
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
]: any -> record<Results: record<Message: string, ResultColumns: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/case_rest_services.metadata")
  let body = {"output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# ECHO ICIS Law Sections Lookup Service
#
# GET /rest_lookups.icis_law_sections
export def "rest-lookupsicis-law-sections get" [
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
  --callback: string # JSONP Callback.  For use with JSONP and GEOJSONP output only.  Enter a name of the function in which to wrap the JSON response.
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ECHO ICIS Law Sections Lookup Service
#
# POST /rest_lookups.icis_law_sections
export def "rest-lookupsicis-law-sections post" [
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
]: any -> record<Results: record<LuValues: list<record>, Message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest_lookups.icis_law_sections")
  let body = {"output": $output} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
