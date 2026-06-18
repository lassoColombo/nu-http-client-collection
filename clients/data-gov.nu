# Auto-generated client for Regulations.gov v3.0
# Source: https://api.apis.guru/v2/specs/data.gov/3.0/swagger.json
# Auth: --token flag or $env.REGULATIONS_GOV_TOKEN

const BASE_URL = "https://api.data.gov/regulations/v3"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REGULATIONS_GOV_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)"} }
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

def base-url-completer [] { ["https://api.data.gov/regulations/v3"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def accept-completer [] { ["applicaiton/xml" "application/json"] }
def counts-only-completer [] { ["0" "1"] }
def encoded-completer [] { ["0" "1"] }
def dct-completer [] { ["FR" "N" "O" "PR" "PS" "SR"] }
def dkt-completer [] { ["N" "R"] }
def cp-completer [] { ["C" "O"] }
def rpp-completer [] { ["10" "100" "1000" "25" "500"] }
def cs-completer [] { ["0" "15" "3" "30" "90"] }
def np-completer [] { ["0" "15" "3" "30" "90"] }
def cat-completer [] { ["AD" "AEP" "BFS" "CT" "EELS" "EUMM" "HCFP" "ITT" "LES" "PRE"] }
def sb-completer [] { ["agency" "docId" "docketId" "documentType" "organization" "postedDate" "submitterName" "title"] }
def so-completer [] { ["ASC" "DESC"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "docket-response-format get" } } | get name | first)
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

# Returns Docket information
#
# GET /docket.{response_format}
# operationId: docket
export def "docket-response-format get" [
  response_format: string
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
  --docket-id: string # Docket ID (default: EPA-HQ-OAR-2011-0028)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "docketId" $docket_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({response_format: (encode-path-segment $response_format)} | format pattern "/docket.{response_format}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Document information
#
# GET /document.{response_format}
# operationId: document
export def "document-response-format get" [
  response_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: string # FDMS Document ID (default: EPA-HQ-OAR-2011-0028-0108)
  --federal-register-number: string # Federal Register Document Number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $document_id "scalar") (serialize-qp "federalRegisterNumber" $federal_register_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({response_format: (encode-path-segment $response_format)} | format pattern "/document.{response_format}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Search for Documents
#
# GET /documents.{response_format}
# operationId: documents
export def "documents-response-format get" [
  response_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --counts-only: int@counts-only-completer # Counts Only: 1 (will return only the document count for a search query)0 (will return documents as well)
  --encoded: int@encoded-completer # Encoded: 1 (will accept Regulations.gov style encoded parameters)0 (will not accept such encoded parameters)
  --s: string # Keyword(s)
  --dct: string@dct-completer # Document Type: N: NoticePR: Proposed RuleFR: RuleO: OtherSR: Supporting & Related MaterialPS: Public Submission
  --dktid: string # Valid Docket ID (ex. SEC-2012-0044)
  --dkt: string@dkt-completer # Docket Type: R: RulemakingN: NonrulemakingA Docket Type is either Rulemaking or Nonrulemaking. A Rulemaking docket includes the type of regulation that establishes a rule. While a Non-Rulemaking docket does not include a rule.
  --cp: string@cp-completer # Comment Period: O: OpenC: Closed
  --a: string # Federal Agency: List of accepted Federal Agency values. This field allows multiple values. Ex. a=FMCSA%252BEPA%252BFDA
  --rpp: string@rpp-completer # Results Per Page 10, 25, 100, 500, 1,000. Results per page may not exceed 1,000.
  --po: int # Enter the page offset (always starts with 0). This is used in conjunction with results per page to provide large data sets. For example, if a search produces 82 results and the result per page is set to 25, this will generate 4 pages. 3 pages will have 25 results and the last page will have 7 results. Page offset values for each page will be: Page 1: po=0 Page 2: po=25 Page 3: po=50 Page 4: po=75 The total number of pages is [total results/results per page] and page offset for page X is [X-1 * results per page]
  --cs: int@cs-completer # Comment Period Closing Soon: 0 (closing today)3 (closing within 3 days)15 (closing within 15 days)30 (closing within 30 days)90 (closing within 90 days)
  --np: int@np-completer # Newly Posted: 0 (posted today)3 (posted within last 3 days)15 (posted within last 15 days)30 (posted within last 30 days)90 (posted within last 90 days) For periods of time beyond 90-days, please use a date range with the Posted Date parameter.
  --cmsd: string # Comment Period Start Date: Enter a date in the form of MM/DD/YY. Note: If the Comment Period End Date is also provided, then ensure the Comment Period Start date is earlier. (format: date)
  --cmd: string # Comment Period End Date: Enter a date in the form of MM/DD/YY. Note: If the Comment Period Start Date is also provided, then ensure the Comment Period End date is after.* Comment Period Start and End Dates are mutually exclusive with the 'closing soon' parameter. If both are provided, 'closing soon' will be ignored. (format: date)
  --crd: string # Creation Date: Enter a date in the form of MM/DD/YY. Accepts a single date or a date range. Ex. crd=11/06/13-03/06/14 (format: date)
  --rd: string # Received Date: Enter a date in the form of MM/DD/YY. Accepts a single date or a date range. Ex. rd=11/06/13-03/06/14 (format: date)
  --pd: string # Posted Date: Enter a date in the form of MM/DD/YY. Accepts a single date or a date range. Ex. pd=11/06/13-03/06/14 (format: date)
  --cat: string@cat-completer # Document Category: AD (Aerospace and Transportation) AEP (Agriculture, Environment, and Public Lands) BFS (Banking and Financial) CT (Commerce and International) LES (Defense, Law Enforcement, and Security) EELS (Education, Labor, Presidential, and Government Services) EUMM (Energy, Natural Resources, and Utilities) HCFP (Food Safety, Health, and Pharmaceutical) PRE (Housing, Development, and Real Estate) ITT (Technology and Telecommunications)
  --sb: string@sb-completer # Sort By: docketId (Docket ID)docId (Document ID)title (Title)postedDate (Posted Date)agency (Agency)documentType (Document Type)submitterName (Submitter Name)organization (Organization) Sort Order is REQUIRED if this parameter is included.
  --so: string@so-completer # Sort Order: ASC: AscendingDESC: Descending
  --dktst: string # Docket Subtype: Only one docket subtype at a time may be selected. One or more agency values must be part of the request. Only values valid for the selected agency will be returned.
  --dktst2: string # Docket Sub-subtype: Only one docket sub-subtype at a time may be selected. One or more agency values must be part of the request. Only values valid for the selected agency will be returned.
  --docst: string # Document Subtype: Single or multiple document subtypes may be included. Multiple values should be passed as follows: docst=%20Certificate+of+Service%252BCorrespondence
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countsOnly" $counts_only "scalar") (serialize-qp "encoded" $encoded "scalar") (serialize-qp "s" $s "scalar") (serialize-qp "dct" $dct "scalar") (serialize-qp "dktid" $dktid "scalar") (serialize-qp "dkt" $dkt "scalar") (serialize-qp "cp" $cp "scalar") (serialize-qp "a" $a "scalar") (serialize-qp "rpp" $rpp "scalar") (serialize-qp "po" $po "scalar") (serialize-qp "cs" $cs "scalar") (serialize-qp "np" $np "scalar") (serialize-qp "cmsd" $cmsd "scalar") (serialize-qp "cmd" $cmd "scalar") (serialize-qp "crd" $crd "scalar") (serialize-qp "rd" $rd "scalar") (serialize-qp "pd" $pd "scalar") (serialize-qp "cat" $cat "scalar") (serialize-qp "sb" $sb "scalar") (serialize-qp "so" $so "scalar") (serialize-qp "dktst" $dktst "scalar") (serialize-qp "dktst2" $dktst2 "scalar") (serialize-qp "docst" $docst "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({response_format: (encode-path-segment $response_format)} | format pattern "/documents.{response_format}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
