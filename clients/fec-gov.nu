# Auto-generated client for OpenFEC v1.0
# Source: https://api.apis.guru/v2/specs/fec.gov/1.0/openapi.json
# Auth: --token flag or $env.OPENFEC_TOKEN

const BASE_URL = "http://localhost/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENFEC_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-Api-Key: $token_val}, query: "", location: "header"} }
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["http://localhost/v1"] }
def auth-scheme-completer [] { ["x-api-key" "query-api_key"] }

# Completers for enum parameters
def renderer-completer [] { ["csv" "ics"] }
def filer-type-completer [] { ["e-file" "paper"] }
def office-completer [] { ["" "H" "P" "S"] }
def aggregate-by-completer [] { ["office" "office-party" "office-state" "office-state-district"] }
def party-completer [] { ["" "DEM" "OTHER" "REP"] }
def support-oppose-indicator-completer [] { ["O" "S"] }
def office-completer-1 [] { ["house" "president" "senate"] }
def support-oppose-completer [] { ["O" "S"] }
def candidate-office-completer [] { ["" "H" "P" "S"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "audit-case get" } } | get name | first)
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

# This endpoint contains Final Audit Reports approved by the Commission since inception. The search can be based on information about the audited committee (Name, FEC ID Number, Type, Election Cycle) or the issues covered in the report.
#
# GET /audit-case/
export def "audit-case get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audit-case-id: list<string> # Primary/foreign key for audit tables
  --cycle: list<int> # Filter records to only those that are applicable to a given two-year period. This cycle follows the traditional House election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. The cycle begins with an odd year and is named for its ending, even year.
  --sub-category-id: string # The finding id of an audit. Finding are a category of broader issues. Each category has an unique ID. (default: all)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --min-election-cycle: int # Filter records to only those that are applicable to a given two-year period. This cycle follows the traditional House election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. The cycle begins with an odd year and is named for its ending, even year. (format: int32)
  --audit-id: list<int> # The audit issue. Each subcategory has an unique ID
  --q: list<string> # The name of the committee. If a committee changes its name, the most recent name will be shown. Committee names are not unique. Use committee_id for looking up records.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --max-election-cycle: int # Filter records to only those that are applicable to a given two-year period. This cycle follows the traditional House election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. The cycle begins with an odd year and is named for its ending, even year. (format: int32)
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --qq: list<string> # Name of candidate running for office
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --committee-designation: string # Type of committee: - H or S - Congressional - P - Presidential - X or Y or Z - Party - N or Q - PAC - I - Independent expenditure - O - Super PAC
  --primary-category-id: string # Audit category ID (table PK) (default: all)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [-cycle, committee_name])
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<audit_case_id: string, audit_id: int, candidate_id: string, candidate_name: string, committee_description: string, committee_designation: string, committee_id: string, committee_name: string, committee_type: string, cycle: int, far_release_date: string, link_to_report: string, primary_category_list: list>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "audit_case_id" $audit_case_id "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sub_category_id" $sub_category_id "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "min_election_cycle" $min_election_cycle "scalar") (serialize-qp "audit_id" $audit_id "multi") (serialize-qp "q" $q "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "max_election_cycle" $max_election_cycle "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "committee_type" $committee_type "multi") (serialize-qp "qq" $qq "multi") (serialize-qp "page" $page "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "committee_designation" $committee_designation "scalar") (serialize-qp "primary_category_id" $primary_category_id "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/audit-case/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"audit_case_id": $audit_case_id, "cycle": $cycle, "sub_category_id": $sub_category_id, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "min_election_cycle": $min_election_cycle, "audit_id": $audit_id, "q": $q, "per_page": $per_page, "max_election_cycle": $max_election_cycle, "candidate_id": $candidate_id, "committee_type": $committee_type, "qq": $qq, "page": $page, "committee_id": $committee_id, "api_key": $api_key, "committee_designation": $committee_designation, "primary_category_id": $primary_category_id, "sort_null_only": $sort_null_only, "sort": $qp_sort} | compact), body: null}
}

# This lists the options for the categories and subcategories available in the /audit-search/ endpoint.
#
# GET /audit-category/
export def "audit-category get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --primary-category-name: list<string> # Primary Audit Category - No Findings or Issues/Not a Committee - Net Outstanding Campaign/Convention Expenditures/Obligations - Payments/Disgorgements - Allocation Issues - Prohibited Contributions - Disclosure - Recordkeeping - Repayment to US Treasury - Other - Misstatement of Financial Activity - Excessive Contributions - Failure to File Reports/Schedules/Notices - Loans - Referred Findings Not Listed
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --primary-category-id: list<string> # Audit category ID (table PK)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: primary_category_name)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<primary_category_id: string, primary_category_name: string, sub_category_list: list>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "primary_category_name" $primary_category_name "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "primary_category_id" $primary_category_id "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audit-category/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "page": $page, "primary_category_name": $primary_category_name, "sort_hide_null": $sort_hide_null, "api_key": $api_key, "primary_category_id": $primary_category_id, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This lists the options for the primary categories available in the /audit-search/ endpoint.
#
# GET /audit-primary-category/
export def "audit-primary-category get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --primary-category-name: list<string> # Primary Audit Category - No Findings or Issues/Not a Committee - Net Outstanding Campaign/Convention Expenditures/Obligations - Payments/Disgorgements - Allocation Issues - Prohibited Contributions - Disclosure - Recordkeeping - Repayment to US Treasury - Other - Misstatement of Financial Activity - Excessive Contributions - Failure to File Reports/Schedules/Notices - Loans - Referred Findings Not Listed
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --primary-category-id: list<string> # Audit category ID (table PK)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: primary_category_name)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<primary_category_id: string, primary_category_name: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "primary_category_name" $primary_category_name "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "primary_category_id" $primary_category_id "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audit-primary-category/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "page": $page, "primary_category_name": $primary_category_name, "sort_hide_null": $sort_hide_null, "api_key": $api_key, "primary_category_id": $primary_category_id, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Combines the election and reporting dates with Commission meetings, conferences, outreach, Advisory Opinions, rules, litigation dates and other events into one calendar. State and report type filtering is no longer available.
#
# GET /calendar-dates/
export def "calendar-dates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-start-date: string # The minimum start date.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --calendar-category-id: list<int> # Each type of event has a calendar category with an integer id. Options are: Open Meetings: 32, Executive Sessions: 39, Public Hearings: 40, Conferences: 33, Roundtables: 34, Election Dates: 36, Federal Holidays: 37, FEA Periods: 38, Commission Meetings: 20, Reporting Deadlines: 21, Conferences and Outreach: 22, AOs and Rules: 23, Other: 24, Quarterly: 25, Monthly: 26, Pre and Post-Elections: 27, EC Periods:28, and IE Periods: 29
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-end-date: string # The minimum end date.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --event-id: int # An unique ID for an event. Useful for downloading a single event to your calendar. This ID is not a permanent, persistent ID. (format: int32)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --description: list<string> # Brief description of event
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -start_date)
  --max-end-date: string # The maximum end date.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --summary: list<string> # Longer description of event
  --max-start-date: string # The maximum start date.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<all_day: bool, calendar_category_id: int, category: string, description: string, end_date: string, event_id: int, location: string, start_date: string, state: list, summary: string, url: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "min_start_date" $min_start_date "scalar") (serialize-qp "calendar_category_id" $calendar_category_id "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_end_date" $min_end_date "scalar") (serialize-qp "event_id" $event_id "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "description" $description "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max_end_date" $max_end_date "scalar") (serialize-qp "summary" $summary "multi") (serialize-qp "max_start_date" $max_start_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calendar-dates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "page": $page, "min_start_date": $min_start_date, "calendar_category_id": $calendar_category_id, "sort_hide_null": $sort_hide_null, "api_key": $api_key, "min_end_date": $min_end_date, "event_id": $event_id, "sort_null_only": $sort_null_only, "per_page": $per_page, "description": $description, "sort": $qp_sort, "max_end_date": $max_end_date, "summary": $summary, "max_start_date": $max_start_date} | compact), body: null}
}

# Returns CSV or ICS for downloading directly into calendar applications like Google, Outlook or other applications. Combines the election and reporting dates with Commission meetings, conferences, outreach, Advisory Opinions, rules, litigation dates and other events into one calendar. State filtering now applies to elections, reports and reporting periods. Presidential pre-primary report due dates are not shown on even years. Filers generally opt to file monthly rather than submit over 50 pre-primary election reports. All reporting deadlines are available at /reporting-dates/ for reference. This is [the sql function](https://github.com/fecgov/openFEC/blob/develop/data/migrations/V40__omnibus_dates.sql) that creates the calendar.
#
# GET /calendar-dates/export/
export def "calendar-dates-export get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --renderer: string@renderer-completer # default: ics
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-start-date: string # The minimum start date.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --calendar-category-id: list<int> # Each type of event has a calendar category with an integer id. Options are: Open Meetings: 32, Executive Sessions: 39, Public Hearings: 40, Conferences: 33, Roundtables: 34, Election Dates: 36, Federal Holidays: 37, FEA Periods: 38, Commission Meetings: 20, Reporting Deadlines: 21, Conferences and Outreach: 22, AOs and Rules: 23, Other: 24, Quarterly: 25, Monthly: 26, Pre and Post-Elections: 27, EC Periods:28, and IE Periods: 29
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-end-date: string # The minimum end date.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --event-id: int # An unique ID for an event. Useful for downloading a single event to your calendar. This ID is not a permanent, persistent ID. (format: int32)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --description: list<string> # Brief description of event
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -start_date)
  --max-end-date: string # The maximum end date.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --summary: list<string> # Longer description of event
  --max-start-date: string # The maximum start date.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<all_day: bool, calendar_category_id: int, category: string, description: string, end_date: string, event_id: int, location: string, start_date: string, state: list, summary: string, url: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "renderer" $renderer "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "min_start_date" $min_start_date "scalar") (serialize-qp "calendar_category_id" $calendar_category_id "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_end_date" $min_end_date "scalar") (serialize-qp "event_id" $event_id "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "description" $description "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max_end_date" $max_end_date "scalar") (serialize-qp "summary" $summary "multi") (serialize-qp "max_start_date" $max_start_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calendar-dates/export/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"renderer": $renderer, "sort_nulls_last": $sort_nulls_last, "page": $page, "min_start_date": $min_start_date, "calendar_category_id": $calendar_category_id, "sort_hide_null": $sort_hide_null, "api_key": $api_key, "min_end_date": $min_end_date, "event_id": $event_id, "sort_null_only": $sort_null_only, "per_page": $per_page, "description": $description, "sort": $qp_sort, "max_end_date": $max_end_date, "summary": $summary, "max_start_date": $max_start_date} | compact), body: null}
}

# This endpoint is useful for finding detailed information about a particular candidate. Use the `candidate_id` to find the most recent information about that candidate.
#
# GET /candidate/{candidate_id}/
export def "candidate get" [
  candidate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string> # Federal office candidate runs for: H, S or P
  --candidate-status: list<string> # One-letter code explaining if the candidate is: - C present candidate - F future candidate - N not yet a candidate - P prior candidate
  --cycle: list<int> # Two-year election cycle in which a candidate runs for office. Calculated from Form 2. The cycle begins with an odd year and is named for its ending, even year. This cycle follows the traditional house election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. To retrieve data for the entire four years of a presidential term or six years of a senatorial term, you will need the `election_full` flag.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --state: list<string> # US state or territory where a candidate runs for office
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --year: string # Retrieve records pertaining to a particular election year. The list of election years is based on a candidate filing a statement of candidacy (F2) for that year.
  --name: list<string> # Name (candidate or committee) to search for. Alias for 'q'.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --federal-funds-flag: oneof<nothing, bool> # A boolean the describes if a presidential candidate has accepted federal funds. The flag will be false for House and Senate candidates.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: name)
  --has-raised-funds: oneof<nothing, bool> # A boolean that describes if a candidate's committee has ever received any receipts for their campaign for this particular office. (Candidates have separate candidate IDs for each office.)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --incumbent-challenge: list<string> # One-letter code ('I', 'C', 'O') explaining if the candidate is an incumbent, a challenger, or if the seat is open.
  --party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, address_city: string, address_state: string, address_street_1: string, address_street_2: string, address_zip: string, candidate_id: string, candidate_inactive: bool, candidate_status: string, cycles: list, district: string, district_number: int, election_districts: list, election_years: list, federal_funds_flag: bool, first_file_date: string, flags: string, has_raised_funds: bool, incumbent_challenge: string, incumbent_challenge_full: string, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, party: string, party_full: string, state: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($candidate_id | is-empty) { error make --unspanned { msg: "path parameter 'candidate_id' must be non-empty" } }
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "candidate_status" $candidate_status "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "state" $state "multi") (serialize-qp "district" $district "multi") (serialize-qp "year" $year "scalar") (serialize-qp "name" $name "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "federal_funds_flag" $federal_funds_flag "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_raised_funds" $has_raised_funds "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "incumbent_challenge" $incumbent_challenge "multi") (serialize-qp "party" $party "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({candidate_id: (encode-path-segment $candidate_id)} | format pattern "/candidate/{candidate_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "candidate_status": $candidate_status, "cycle": $cycle, "sort_nulls_last": $sort_nulls_last, "state": $state, "district": $district, "year": $year, "name": $name, "sort_hide_null": $sort_hide_null, "federal_funds_flag": $federal_funds_flag, "per_page": $per_page, "page": $page, "sort": $qp_sort, "has_raised_funds": $has_raised_funds, "election_year": $election_year, "api_key": $api_key, "sort_null_only": $sort_null_only, "incumbent_challenge": $incumbent_challenge, "party": $party} | compact), body: null}
}

# This endpoint is useful for finding detailed information about a particular committee or filer. Use the `committee_id` to find the most recent information about the committee.
#
# GET /candidate/{candidate_id}/committees/
export def "candidate-committees get" [
  candidate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --filing-frequency: list<string> # The one-letter code of the filing frequency: - A Administratively terminated - D Debt - M Monthly filer - Q Quarterly filer - T Terminated - W Waived
  --cycle: list<int> # A two year election cycle that the committee was active- (after original registration date but before expiration date in Form 1s) The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --year: list<int> # A year that the committee was active— (after original registration date or filing but before expiration date)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --organization-type: list<string> # The one-letter code for the kind for organization: - C corporation - L labor organization - M membership organization - T trade association - V cooperative - W corporation without capital stock
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: name)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<affiliated_committee_name: string, candidate_ids: list, city: string, committee_id: string, committee_type: string, committee_type_full: string, custodian_city: string, custodian_name_1: string, custodian_name_2: string, custodian_name_full: string, custodian_name_middle: string, custodian_name_prefix: string, custodian_name_suffix: string, custodian_name_title: string, custodian_phone: string, custodian_state: string, custodian_street_1: string, custodian_street_2: string, custodian_zip: string, cycles: list, designation: string, designation_full: string, email: string, fax: string, filing_frequency: string, first_f1_date: string, first_file_date: string, form_type: string, jfc_committee: list, last_f1_date: string, last_file_date: string, leadership_pac: string, lobbyist_registrant_pac: string, name: string, organization_type: string, organization_type_full: string, party: string, party_full: string, party_type: string, party_type_full: string, sponsor_candidate_ids: list, state: string, state_full: string, street_1: string, street_2: string, treasurer_city: string, treasurer_name: string, treasurer_name_1: string, treasurer_name_2: string, treasurer_name_middle: string, treasurer_name_prefix: string, treasurer_name_suffix: string, treasurer_name_title: string, treasurer_phone: string, treasurer_state: string, treasurer_street_1: string, treasurer_street_2: string, treasurer_zip: string, website: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($candidate_id | is-empty) { error make --unspanned { msg: "path parameter 'candidate_id' must be non-empty" } }
  let qp = [(serialize-qp "designation" $designation "multi") (serialize-qp "committee_type" $committee_type "multi") (serialize-qp "page" $page "scalar") (serialize-qp "filing_frequency" $filing_frequency "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "year" $year "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "organization_type" $organization_type "multi") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({candidate_id: (encode-path-segment $candidate_id)} | format pattern "/candidate/{candidate_id}/committees/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"designation": $designation, "committee_type": $committee_type, "page": $page, "filing_frequency": $filing_frequency, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "year": $year, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "organization_type": $organization_type, "sort": $qp_sort} | compact), body: null}
}

# Explore a filer's characteristics over time. This can be particularly useful if the committees change treasurers, designation, or `committee_type`.
#
# GET /candidate/{candidate_id}/committees/history/
export def "candidate-committees-history list" [
  candidate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -cycle)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<affiliated_committee_name: string, candidate_ids: list, city: string, committee_id: string, committee_label: string, committee_type: string, committee_type_full: string, convert_to_pac_flag: bool, cycle: int, cycles: list, cycles_has_activity: list, cycles_has_financial: list, designation: string, designation_full: string, filing_frequency: string, first_f1_date: string, first_file_date: string, former_candidate_election_year: int, former_candidate_id: string, former_candidate_name: string, former_committee_name: string, is_active: bool, jfc_committee: list, last_cycle_has_activity: int, last_cycle_has_financial: int, last_f1_date: string, last_file_date: string, name: string, organization_type: string, organization_type_full: string, party: string, party_full: string, sponsor_candidate_ids: list, state: string, state_full: string, street_1: string, street_2: string, treasurer_name: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($candidate_id | is-empty) { error make --unspanned { msg: "path parameter 'candidate_id' must be non-empty" } }
  let qp = [(serialize-qp "designation" $designation "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({candidate_id: (encode-path-segment $candidate_id)} | format pattern "/candidate/{candidate_id}/committees/history/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"designation": $designation, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Explore a filer's characteristics over time. This can be particularly useful if the committees change treasurers, designation, or `committee_type`.
#
# GET /candidate/{candidate_id}/committees/history/{cycle}/
export def "candidate-committees-history get" [
  candidate_id: string
  cycle: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -cycle)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<affiliated_committee_name: string, candidate_ids: list, city: string, committee_id: string, committee_label: string, committee_type: string, committee_type_full: string, convert_to_pac_flag: bool, cycle: int, cycles: list, cycles_has_activity: list, cycles_has_financial: list, designation: string, designation_full: string, filing_frequency: string, first_f1_date: string, first_file_date: string, former_candidate_election_year: int, former_candidate_id: string, former_candidate_name: string, former_committee_name: string, is_active: bool, jfc_committee: list, last_cycle_has_activity: int, last_cycle_has_financial: int, last_f1_date: string, last_file_date: string, name: string, organization_type: string, organization_type_full: string, party: string, party_full: string, sponsor_candidate_ids: list, state: string, state_full: string, street_1: string, street_2: string, treasurer_name: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($candidate_id | is-empty) { error make --unspanned { msg: "path parameter 'candidate_id' must be non-empty" } }
  if ($cycle | is-empty) { error make --unspanned { msg: "path parameter 'cycle' must be non-empty" } }
  let qp = [(serialize-qp "designation" $designation "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({candidate_id: (encode-path-segment $candidate_id), cycle: (encode-path-segment $cycle)} | format pattern "/candidate/{candidate_id}/committees/history/{cycle}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"designation": $designation, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# All official records and reports filed by or delivered to the FEC. Note: because the filings data includes many records, counts for large result sets are approximate; you will want to page through the records until no records are returned.
#
# GET /candidate/{candidate_id}/filings/
export def "candidate-filings get" [
  candidate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string> # Federal office candidate runs for: H, S or P
  --file-number: list<int> # Filing ID number
  --form-category: list<string> # The forms filed are categorized based on the nature of the filing: - REPORT F3, F3X, F3P, F3L, F4, F5, F7, F13 - NOTICE F5, F24, F6, F9, F10, F11 - STATEMENT F1, F2 - OTHER F1M, F8, F99, F12, FRQ
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --document-type: list<string> # The type of document for documents other than reports: - 2 24 Hour Contribution Notice - 4 48 Hour Contribution Notice - A Debt Settlement Statement - B Acknowledgment of Receipt of Debt Settlement Statement - C RFAI: Debt Settlement First Notice - D Commission Debt Settlement Review - E Commission Response TO Debt Settlement Request - F Administrative Termination - G Debt Settlement Plan Amendment - H Disavowal Notice - I Disavowal Response - J Conduit Report - K Termination Approval - L Repeat Non-Filer Notice - M Filing Frequency Change Notice - N Paper Amendment to Electronic Report - O Acknowledgment of Filing Frequency Change - S RFAI: Debt Settlement Second - T Miscellaneous Report TO FEC - V Repeat Violation Notice (441A OR 441B) - P Notice of Paper Filing - R F3L Filing Frequency Change Notice - Q Acknowledgment of F3L Filing Frequency Change - U Unregistered Committee Notice
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --state: list<string> # US state or territory where a candidate runs for office
  --amendment-indicator: list<string> # Amendent types: -N new -A amendment -T terminated -C consolidated -M multi-candidate -S secondary NULL might be new or amendment. If amendment indicator is null and the filings is the first or first in a chain treat it as if it was a new. If it is not the first or first in a chain then treat the filing as an amendment.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --is-amended: oneof<nothing, bool> # False indicates that a report is the most recent. True indicates that the report has been superseded by an amendment.
  --filer-type: string@filer-type-completer # The method used to file with the FEC, either electronic or on paper.
  --max-receipt-date: string # Selects all filings received before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --primary-general-indicator: list<string> # Primary, general or special election indicator.
  --request-type: list<string> # Requests for additional information (RFAIs) sent to filers. The request type is based on the type of document filed: - 1 Statement of Organization - 2 Report of Receipts and Expenditures (Form 3 and 3X) - 3 Second Notice - Reports - 4 Request for Additional Information - 5 Informational - Reports - 6 Second Notice - Statement of Organization - 7 Failure to File - 8 From Public Disclosure - 9 From Multi Candidate Status
  --report-year: list<int> # Forms with coverage date - year from the coverage ending date. Forms without coverage date - year from the receipt date.
  --form-type: list<string> # The form where the underlying data comes from, for example, Form 1 would appear as F1: - F1 Statement of Organization - F1M Notification of Multicandidate Status - F2 Statement of Candidacy - F3 Report of Receipts and Disbursements for an Authorized Committee - F3P Report of Receipts and Disbursements by an Authorized Committee of a Candidate for The Office of President or Vice President - F3L Report of Contributions Bundled by Lobbyists/Registrants and Lobbyist/Registrant PACs - F3X Report of Receipts and Disbursements for other than an Authorized Committee - F4 Report of Receipts and Disbursements for a Committee or Organization Supporting a Nomination Convention - F5 Report of Independent Expenditures Made and Contributions Received - F6 48 Hour Notice of Contributions/Loans Received - F7 Report of Communication Costs by Corporations and Membership Organizations - F8 Debt Settlement Plan - F9 24 Hour Notice of Disbursements for Electioneering Communications - F13 Report of Donations Accepted for Inaugural Committee - F99 Miscellaneous Text - FRQ Request for Additional Information
  --committee-type: string # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --beginning-image-number: list<string> # Unique identifier for the electronic or paper report. This number is used to construct PDF URLs to the original document.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [-receipt_date])
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-receipt-date: string # Selects all filings received after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --q-filer: list<string> # Keyword search for filer name or ID
  --report-type: list<string> # Name of report where the underlying data comes from: - 10D Pre-Election - 10G Pre-General - 10P Pre-Primary - 10R Pre-Run-Off - 10S Pre-Special - 12C Pre-Convention - 12G Pre-General - 12P Pre-Primary - 12R Pre-Run-Off - 12S Pre-Special - 30D Post-Election - 30G Post-General - 30P Post-Primary - 30R Post-Run-Off - 30S Post-Special - 60D Post-Convention - M1 January Monthly - M10 October Monthly - M11 November Monthly - M12 December Monthly - M2 February Monthly - M3 March Monthly - M4 April Monthly - M5 May Monthly - M6 June Monthly - M7 July Monthly - M8 August Monthly - M9 September Monthly - MY Mid-Year Report - Q1 April Quarterly - Q2 July Quarterly - Q3 October Quarterly - TER Termination Report - YE Year-End - ADJ COMP ADJUST AMEND - CA COMPREHENSIVE AMEND - 90S Post Inaugural Supplement - 90D Post Inaugural - 48 48 Hour Notification - 24 24 Hour Notification - M7S July Monthly/Semi-Annual - MSA Monthly Semi-Annual (MY) - MYS Monthly Year End/Semi-Annual - Q2S July Quarterly/Semi-Annual - QSA Quarterly Semi-Annual (MY) - QYS Quarterly Year End/Semi-Annual - QYE Quarterly Semi-Annual (YE) - QMS Quarterly Mid-Year/ Semi-Annual - MSY Monthly Semi-Annual (YE)
  --party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
  --most-recent: oneof<nothing, bool> # Report is either new or is the most-recently filed amendment
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<additional_bank_names: list, amendment_chain: list, amendment_indicator: string, amendment_version: int, bank_depository_city: string, bank_depository_name: string, bank_depository_state: string, bank_depository_street_1: string, bank_depository_street_2: string, bank_depository_zip: string, beginning_image_number: string, candidate_id: string, candidate_name: string, cash_on_hand_beginning_period: float, cash_on_hand_end_period: float, committee_id: string, committee_name: string, committee_type: string, coverage_end_date: string, coverage_start_date: string, csv_url: string, cycle: int, debts_owed_by_committee: float, debts_owed_to_committee: float, document_description: string, document_type: string, document_type_full: string, election_year: int, ending_image_number: string, fec_file_id: string, fec_url: string, file_number: int, form_category: string, form_type: string, house_personal_funds: float, html_url: string, is_amended: bool, means_filed: string, most_recent: bool, most_recent_file_number: int, net_donations: float, office: string, opposition_personal_funds: float, pages: int, party: string, pdf_url: string, previous_file_number: int, primary_general_indicator: string, receipt_date: string, report_type: string, report_type_full: string, report_year: int, request_type: string, senate_personal_funds: float, state: string, sub_id: string, total_communication_cost: float, total_disbursements: float, total_independent_expenditures: float, total_individual_contributions: float, total_receipts: float, treasurer_name: string, update_date: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($candidate_id | is-empty) { error make --unspanned { msg: "path parameter 'candidate_id' must be non-empty" } }
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "file_number" $file_number "multi") (serialize-qp "form_category" $form_category "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "multi") (serialize-qp "document_type" $document_type "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "state" $state "multi") (serialize-qp "amendment_indicator" $amendment_indicator "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "is_amended" $is_amended "scalar") (serialize-qp "filer_type" $filer_type "scalar") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "primary_general_indicator" $primary_general_indicator "multi") (serialize-qp "request_type" $request_type "multi") (serialize-qp "report_year" $report_year "multi") (serialize-qp "form_type" $form_type "multi") (serialize-qp "committee_type" $committee_type "scalar") (serialize-qp "beginning_image_number" $beginning_image_number "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "q_filer" $q_filer "multi") (serialize-qp "report_type" $report_type "multi") (serialize-qp "party" $party "multi") (serialize-qp "most_recent" $most_recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({candidate_id: (encode-path-segment $candidate_id)} | format pattern "/candidate/{candidate_id}/filings/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "file_number": $file_number, "form_category": $form_category, "cycle": $cycle, "district": $district, "document_type": $document_type, "sort_hide_null": $sort_hide_null, "state": $state, "amendment_indicator": $amendment_indicator, "sort_nulls_last": $sort_nulls_last, "is_amended": $is_amended, "filer_type": $filer_type, "max_receipt_date": $max_receipt_date, "per_page": $per_page, "primary_general_indicator": $primary_general_indicator, "request_type": $request_type, "report_year": $report_year, "form_type": $form_type, "committee_type": $committee_type, "beginning_image_number": $beginning_image_number, "page": $page, "sort": $qp_sort, "api_key": $api_key, "min_receipt_date": $min_receipt_date, "sort_null_only": $sort_null_only, "q_filer": $q_filer, "report_type": $report_type, "party": $party, "most_recent": $most_recent} | compact), body: null}
}

# Find out a candidate's characteristics over time. This is particularly useful if the candidate runs for the same office in different districts or you want to know more about a candidate's previous races. This information is organized by `candidate_id`, so it won't help you find a candidate who ran for different offices over time; candidates get a new ID for each office.
#
# GET /candidate/{candidate_id}/history/
export def "candidate-history list" [
  candidate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -two_year_period)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, address_city: string, address_state: string, address_street_1: string, address_street_2: string, address_zip: string, candidate_election_year: int, candidate_id: string, candidate_inactive: bool, candidate_status: string, cycles: list, district: string, district_number: int, election_districts: list, election_years: list, fec_cycles_in_election: list, first_file_date: string, flags: string, incumbent_challenge: string, incumbent_challenge_full: string, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, party: string, party_full: string, rounded_election_years: list, state: string, two_year_period: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($candidate_id | is-empty) { error make --unspanned { msg: "path parameter 'candidate_id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({candidate_id: (encode-path-segment $candidate_id)} | format pattern "/candidate/{candidate_id}/history/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "election_full": $election_full, "page": $page} | compact), body: null}
}

# Find out a candidate's characteristics over time. This is particularly useful if the candidate runs for the same office in different districts or you want to know more about a candidate's previous races. This information is organized by `candidate_id`, so it won't help you find a candidate who ran for different offices over time; candidates get a new ID for each office.
#
# GET /candidate/{candidate_id}/history/{cycle}/
export def "candidate-history get" [
  candidate_id: string
  cycle: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -two_year_period)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, address_city: string, address_state: string, address_street_1: string, address_street_2: string, address_zip: string, candidate_election_year: int, candidate_id: string, candidate_inactive: bool, candidate_status: string, cycles: list, district: string, district_number: int, election_districts: list, election_years: list, fec_cycles_in_election: list, first_file_date: string, flags: string, incumbent_challenge: string, incumbent_challenge_full: string, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, party: string, party_full: string, rounded_election_years: list, state: string, two_year_period: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($candidate_id | is-empty) { error make --unspanned { msg: "path parameter 'candidate_id' must be non-empty" } }
  if ($cycle | is-empty) { error make --unspanned { msg: "path parameter 'cycle' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({candidate_id: (encode-path-segment $candidate_id), cycle: (encode-path-segment $cycle)} | format pattern "/candidate/{candidate_id}/history/{cycle}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "election_full": $election_full, "page": $page} | compact), body: null}
}

# This endpoint provides information about a committee's Form 3, Form 3X, or Form 3P financial reports, which are aggregated by two-year period. We refer to two-year periods as a `cycle`. The cycle is named after the even-numbered year and includes the year before it. To obtain totals from 2013 and 2014, you would use 2014. In odd-numbered years, the current cycle is the next year — for example, in 2015, the current cycle is 2016. For presidential and Senate candidates, multiple two-year cycles exist between elections.
#
# GET /candidate/{candidate_id}/totals/
export def "candidate-totals get" [
  candidate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -cycle)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<all_loans_received: float, all_other_loans: float, allocated_federal_election_levin_share: float, candidate_contribution: float, cash_on_hand_beginning_period: float, committee_designation: string, committee_designation_full: string, committee_id: string, committee_name: string, committee_state: string, committee_type: string, committee_type_full: string, contribution_refunds: float, contributions: float, contributions_ie_and_party_expenditures_made_percent: float, convention_exp: float, coordinated_expenditures_by_party_committee: float, coverage_end_date: string, coverage_start_date: string, cycle: int, disbursements: float, exempt_legal_accounting_disbursement: float, exp_prior_years_subject_limits: float, exp_subject_limits: float, fed_candidate_committee_contributions: float, fed_candidate_contribution_refunds: float, fed_disbursements: float, fed_election_activity: float, fed_operating_expenditures: float, fed_receipts: float, federal_funds: float, filing_frequency: string, filing_frequency_full: string, first_f1_date: string, first_file_date: string, fundraising_disbursements: float, independent_expenditures: float, individual_contributions: float, individual_contributions_percent: float, individual_itemized_contributions: float, individual_unitemized_contributions: float, itemized_convention_exp: float, itemized_other_disb: float, itemized_other_income: float, itemized_other_refunds: float, itemized_refunds_relating_convention_exp: float, last_beginning_image_number: string, last_cash_on_hand_end_period: float, last_debts_owed_by_committee: float, last_debts_owed_to_committee: float, last_report_type_full: string, last_report_year: int, loan_repayments: float, loan_repayments_candidate_loans: float, loan_repayments_made: float, loan_repayments_other_loans: float, loan_repayments_received: float, loans: float, loans_and_loan_repayments_made: float, loans_and_loan_repayments_received: float, loans_made: float, loans_made_by_candidate: float, loans_received: float, loans_received_from_candidate: float, net_contributions: float, net_operating_expenditures: float, non_allocated_fed_election_activity: float, offsets_to_fundraising_expenditures: float, offsets_to_legal_accounting: float, offsets_to_operating_expenditures: float, operating_expenditures: float, operating_expenditures_percent: float, organization_type: string, organization_type_full: string, other_disbursements: float, other_fed_operating_expenditures: float, other_fed_receipts: float, other_loans_received: float, other_political_committee_contributions: float, other_receipts: float, other_refunds: float, party_and_other_committee_contributions_percent: float, party_full: string, pdf_url: string, political_party_committee_contributions: float, receipts: float, refunded_individual_contributions: float, refunded_other_political_committee_contributions: float, refunded_political_party_committee_contributions: float, refunds_relating_convention_exp: float, repayments_loans_made_by_candidate: float, repayments_other_loans: float, report_form: string, shared_fed_activity: float, shared_fed_activity_nonfed: float, shared_fed_operating_expenditures: float, shared_nonfed_operating_expenditures: float, total_exp_subject_limits: float, total_independent_contributions: float, total_independent_expenditures: float, total_offsets_to_operating_expenditures: float, total_transfers: float, transaction_coverage_date: string, transfers_from_affiliated_committee: float, transfers_from_affiliated_party: float, transfers_from_nonfed_account: float, transfers_from_nonfed_levin: float, transfers_from_other_authorized_committee: float, transfers_to_affiliated_committee: float, transfers_to_other_authorized_committee: float, treasurer_name: string, unitemized_convention_exp: float, unitemized_other_disb: float, unitemized_other_income: float, unitemized_other_refunds: float, unitemized_refunds_relating_convention_exp: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($candidate_id | is-empty) { error make --unspanned { msg: "path parameter 'candidate_id' must be non-empty" } }
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({candidate_id: (encode-path-segment $candidate_id)} | format pattern "/candidate/{candidate_id}/totals/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "cycle": $cycle, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Fetch basic information about candidates, and use parameters to filter results to the candidates you're looking for. Each result reflects a unique FEC candidate ID. That ID is particular to the candidate for a particular office sought. If a candidate runs for the same office multiple times, the ID stays the same. If the same person runs for another office — for example, a House candidate runs for a Senate office — that candidate will get a unique ID for each office.
#
# GET /candidates/
export def "candidates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string> # Federal office candidate runs for: H, S or P
  --candidate-status: list<string> # One-letter code explaining if the candidate is: - C present candidate - F future candidate - N not yet a candidate - P prior candidate
  --cycle: list<int> # Two-year election cycle in which a candidate runs for office. Calculated from Form 2. The cycle begins with an odd year and is named for its ending, even year. This cycle follows the traditional house election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. To retrieve data for the entire four years of a presidential term or six years of a senatorial term, you will need the `election_full` flag.
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --year: string # Retrieve records pertaining to a particular election year. The list of election years is based on a candidate filing a statement of candidacy (F2) for that year.
  --state: list<string> # US state or territory where a candidate runs for office
  --name: list<string> # Name (candidate or committee) to search for. Alias for 'q'.
  --is-active-candidate: oneof<nothing, bool> # Candidates who are actively seeking office. If no value is specified, all candidates are returned. When True is specified, only active candidates are returned. When False is specified, only inactive candidates are returned.
  --q: list<string> # Name of candidate running for office
  --federal-funds-flag: oneof<nothing, bool> # A boolean the describes if a presidential candidate has accepted federal funds. The flag will be false for House and Senate candidates.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --min-first-file-date: string # Selects all candidates whose first filing was received by the FEC after this date. (format: date)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: name)
  --has-raised-funds: oneof<nothing, bool> # A boolean that describes if a candidate's committee has ever received any receipts for their campaign for this particular office. (Candidates have separate candidate IDs for each office.)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --incumbent-challenge: list<string> # One-letter code ('I', 'C', 'O') explaining if the candidate is an incumbent, a challenger, or if the seat is open.
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --max-first-file-date: string # Selects all candidates whose first filing was received by the FEC before this date. (format: date)
  --party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, candidate_id: string, candidate_inactive: bool, candidate_status: string, cycles: list, district: string, district_number: int, election_districts: list, election_years: list, federal_funds_flag: bool, first_file_date: string, has_raised_funds: bool, inactive_election_years: list, incumbent_challenge: string, incumbent_challenge_full: string, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, party: string, party_full: string, principal_committees: list, state: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "candidate_status" $candidate_status "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "state" $state "multi") (serialize-qp "name" $name "multi") (serialize-qp "is_active_candidate" $is_active_candidate "scalar") (serialize-qp "q" $q "multi") (serialize-qp "federal_funds_flag" $federal_funds_flag "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "min_first_file_date" $min_first_file_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_raised_funds" $has_raised_funds "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "incumbent_challenge" $incumbent_challenge "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "max_first_file_date" $max_first_file_date "scalar") (serialize-qp "party" $party "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/candidates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "candidate_status": $candidate_status, "cycle": $cycle, "district": $district, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "year": $year, "state": $state, "name": $name, "is_active_candidate": $is_active_candidate, "q": $q, "federal_funds_flag": $federal_funds_flag, "per_page": $per_page, "candidate_id": $candidate_id, "min_first_file_date": $min_first_file_date, "page": $page, "sort": $qp_sort, "has_raised_funds": $has_raised_funds, "election_year": $election_year, "api_key": $api_key, "incumbent_challenge": $incumbent_challenge, "sort_null_only": $sort_null_only, "max_first_file_date": $max_first_file_date, "party": $party} | compact), body: null}
}

# Fetch basic information about candidates and their principal committees. Each result reflects a unique FEC candidate ID. That ID is assigned to the candidate for a particular office sought. If a candidate runs for the same office over time, that ID stays the same. If the same person runs for multiple offices — for example, a House candidate runs for a Senate office — that candidate will get a unique ID for each office. The candidate endpoints primarily use data from FEC registration [Form 1](https://www.fec.gov/pdf/forms/fecfrm1.pdf) for committee information and [Form 2](https://www.fec.gov/pdf/forms/fecfrm2.pdf) for candidate information.
#
# GET /candidates/search/
export def "candidates-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string> # Federal office candidate runs for: H, S or P
  --candidate-status: list<string> # One-letter code explaining if the candidate is: - C present candidate - F future candidate - N not yet a candidate - P prior candidate
  --cycle: list<int> # Two-year election cycle in which a candidate runs for office. Calculated from Form 2. The cycle begins with an odd year and is named for its ending, even year. This cycle follows the traditional house election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. To retrieve data for the entire four years of a presidential term or six years of a senatorial term, you will need the `election_full` flag.
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --year: string # Retrieve records pertaining to a particular election year. The list of election years is based on a candidate filing a statement of candidacy (F2) for that year.
  --state: list<string> # US state or territory where a candidate runs for office
  --name: list<string> # Name (candidate or committee) to search for. Alias for 'q'.
  --is-active-candidate: oneof<nothing, bool> # Candidates who are actively seeking office. If no value is specified, all candidates are returned. When True is specified, only active candidates are returned. When False is specified, only inactive candidates are returned.
  --q: list<string> # Name of candidate running for office
  --federal-funds-flag: oneof<nothing, bool> # A boolean the describes if a presidential candidate has accepted federal funds. The flag will be false for House and Senate candidates.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --min-first-file-date: string # Selects all candidates whose first filing was received by the FEC after this date. (format: date)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: name)
  --has-raised-funds: oneof<nothing, bool> # A boolean that describes if a candidate's committee has ever received any receipts for their campaign for this particular office. (Candidates have separate candidate IDs for each office.)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --incumbent-challenge: list<string> # One-letter code ('I', 'C', 'O') explaining if the candidate is an incumbent, a challenger, or if the seat is open.
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --max-first-file-date: string # Selects all candidates whose first filing was received by the FEC before this date. (format: date)
  --party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, candidate_id: string, candidate_inactive: bool, candidate_status: string, cycles: list, district: string, district_number: int, election_districts: list, election_years: list, federal_funds_flag: bool, first_file_date: string, has_raised_funds: bool, inactive_election_years: list, incumbent_challenge: string, incumbent_challenge_full: string, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, party: string, party_full: string, principal_committees: list, state: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "candidate_status" $candidate_status "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "state" $state "multi") (serialize-qp "name" $name "multi") (serialize-qp "is_active_candidate" $is_active_candidate "scalar") (serialize-qp "q" $q "multi") (serialize-qp "federal_funds_flag" $federal_funds_flag "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "min_first_file_date" $min_first_file_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_raised_funds" $has_raised_funds "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "incumbent_challenge" $incumbent_challenge "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "max_first_file_date" $max_first_file_date "scalar") (serialize-qp "party" $party "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/candidates/search/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "candidate_status": $candidate_status, "cycle": $cycle, "district": $district, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "year": $year, "state": $state, "name": $name, "is_active_candidate": $is_active_candidate, "q": $q, "federal_funds_flag": $federal_funds_flag, "per_page": $per_page, "candidate_id": $candidate_id, "min_first_file_date": $min_first_file_date, "page": $page, "sort": $qp_sort, "has_raised_funds": $has_raised_funds, "election_year": $election_year, "api_key": $api_key, "incumbent_challenge": $incumbent_challenge, "sort_null_only": $sort_null_only, "max_first_file_date": $max_first_file_date, "party": $party} | compact), body: null}
}

# Aggregated candidate receipts and disbursements grouped by cycle.
#
# GET /candidates/totals/
export def "candidates-totals get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string> # Federal office candidate runs for: H, S or P
  --min-receipts: string # Minimum aggregated receipts
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --district: list<string> # District of candidate
  --max-receipts: string # Maximum aggregated receipts
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --state: list<string> # State of candidate
  --max-debts-owed-by-committee: string # Maximum debt
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --min-debts-owed-by-committee: string # Minimum debt
  --is-active-candidate: oneof<nothing, bool> # Candidates who are actively seeking office. If no value is specified, all candidates are returned. When True is specified, only active candidates are returned. When False is specified, only inactive candidates are returned.
  --q: list<string> # Name of candidate running for office
  --federal-funds-flag: oneof<nothing, bool> # A boolean the describes if a presidential candidate has accepted federal funds. The flag will be false for House and Senate candidates.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --max-cash-on-hand-end-period: string # Maximum cash on hand
  --max-disbursements: string # Maximum aggregated disbursements
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --has-raised-funds: oneof<nothing, bool> # A boolean that describes if a candidate's committee has ever received any receipts for their campaign for this particular office. (Candidates have separate candidate IDs for each office.)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --election-year: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --min-cash-on-hand-end-period: string # Minimum cash on hand
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
  --party: list<string> # Three-letter party code
  --min-disbursements: string # Minimum aggregated disbursements
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, address_city: string, address_state: string, address_street_1: string, address_street_2: string, address_zip: string, candidate_election_year: int, candidate_id: string, candidate_inactive: bool, candidate_status: string, cash_on_hand_end_period: float, coverage_end_date: string, coverage_start_date: string, cycle: int, cycles: list, debts_owed_by_committee: float, disbursements: float, district: string, district_number: int, election_districts: list, election_year: int, election_years: list, fec_cycles_in_election: list, federal_funds_flag: bool, first_file_date: string, flags: string, has_raised_funds: bool, incumbent_challenge: string, incumbent_challenge_full: string, individual_itemized_contributions: float, is_election: bool, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, other_political_committee_contributions: float, party: string, party_full: string, receipts: float, rounded_election_years: list, state: string, transfers_from_other_authorized_committee: float, two_year_period: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "min_receipts" $min_receipts "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "multi") (serialize-qp "max_receipts" $max_receipts "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "state" $state "multi") (serialize-qp "max_debts_owed_by_committee" $max_debts_owed_by_committee "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "min_debts_owed_by_committee" $min_debts_owed_by_committee "scalar") (serialize-qp "is_active_candidate" $is_active_candidate "scalar") (serialize-qp "q" $q "multi") (serialize-qp "federal_funds_flag" $federal_funds_flag "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "max_cash_on_hand_end_period" $max_cash_on_hand_end_period "scalar") (serialize-qp "max_disbursements" $max_disbursements "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "has_raised_funds" $has_raised_funds "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "min_cash_on_hand_end_period" $min_cash_on_hand_end_period "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "party" $party "multi") (serialize-qp "min_disbursements" $min_disbursements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/candidates/totals/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "min_receipts": $min_receipts, "cycle": $cycle, "district": $district, "max_receipts": $max_receipts, "sort_hide_null": $sort_hide_null, "state": $state, "max_debts_owed_by_committee": $max_debts_owed_by_committee, "sort_nulls_last": $sort_nulls_last, "min_debts_owed_by_committee": $min_debts_owed_by_committee, "is_active_candidate": $is_active_candidate, "q": $q, "federal_funds_flag": $federal_funds_flag, "per_page": $per_page, "max_cash_on_hand_end_period": $max_cash_on_hand_end_period, "max_disbursements": $max_disbursements, "candidate_id": $candidate_id, "page": $page, "has_raised_funds": $has_raised_funds, "election_full": $election_full, "election_year": $election_year, "api_key": $api_key, "sort_null_only": $sort_null_only, "min_cash_on_hand_end_period": $min_cash_on_hand_end_period, "sort": $qp_sort, "party": $party, "min_disbursements": $min_disbursements} | compact), body: null}
}

# Candidate total receipts and disbursements aggregated by `aggregate_by`.
#
# GET /candidates/totals/aggregates/
export def "candidates-totals-aggregates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: string@office-completer # Federal office candidate runs for: H, S or P
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --state: list<string> # US state or territory where a candidate runs for office
  --min-election-cycle: int # Filter records to only those that are applicable to a given two-year period. This cycle follows the traditional House election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. The cycle begins with an odd year and is named for its ending, even year. (format: int32)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --is-active-candidate: oneof<nothing, bool> # Candidates who are actively seeking office. If no value is specified, all candidates are returned. When True is specified, only active candidates are returned. When False is specified, only inactive candidates are returned.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --max-election-cycle: int # Filter records to only those that are applicable to a given two-year period. This cycle follows the traditional House election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. The cycle begins with an odd year and is named for its ending, even year. (format: int32)
  --aggregate-by: string@aggregate-by-completer # Candidate totals aggregate_by (Chose one of dropdown options): - ' ' grouped by election year - office grouped by election year, by office - office-state grouped by election year, by office, by state - office-state-district grouped by election year, by office, by state, by district - office-party grouped by election year, by office, by party
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --election-year: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [-election_year])
  --party: string@party-completer # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<district: string, district_number: int, election_year: int, office: string, party: string, state: string, total_cash_on_hand_end_period: float, total_debts_owed_by_committee: float, total_disbursements: float, total_individual_itemized_contributions: float, total_other_political_committee_contributions: float, total_receipts: float, total_transfers_from_other_authorized_committee: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "district" $district "multi") (serialize-qp "state" $state "multi") (serialize-qp "min_election_cycle" $min_election_cycle "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "is_active_candidate" $is_active_candidate "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "max_election_cycle" $max_election_cycle "scalar") (serialize-qp "aggregate_by" $aggregate_by "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "party" $party "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/candidates/totals/aggregates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "sort_nulls_last": $sort_nulls_last, "district": $district, "state": $state, "min_election_cycle": $min_election_cycle, "sort_hide_null": $sort_hide_null, "is_active_candidate": $is_active_candidate, "per_page": $per_page, "max_election_cycle": $max_election_cycle, "aggregate_by": $aggregate_by, "page": $page, "election_year": $election_year, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "sort": $qp_sort, "party": $party} | compact), body: null}
}

# Aggregated candidate receipts and disbursements grouped by office by cycle.
#
# GET /candidates/totals/by_office/
export def "candidates-totals-by-office get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: string@office-completer # Federal office candidate runs for: H, S or P
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-election-cycle: int # Filter records to only those that are applicable to a given two-year period. This cycle follows the traditional House election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. The cycle begins with an odd year and is named for its ending, even year. (format: int32)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-year: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --is-active-candidate: oneof<nothing, bool> # Candidates who are actively seeking office. If no value is specified, all candidates are returned. When True is specified, only active candidates are returned. When False is specified, only inactive candidates are returned.
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --max-election-cycle: int # Filter records to only those that are applicable to a given two-year period. This cycle follows the traditional House election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. The cycle begins with an odd year and is named for its ending, even year. (format: int32)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<election_year: int, office: string, total_disbursements: float, total_individual_itemized_contributions: float, total_other_political_committee_contributions: float, total_receipts: float, total_transfers_from_other_authorized_committee: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "min_election_cycle" $min_election_cycle "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "is_active_candidate" $is_active_candidate "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "max_election_cycle" $max_election_cycle "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/candidates/totals/by_office/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "sort_nulls_last": $sort_nulls_last, "page": $page, "min_election_cycle": $min_election_cycle, "sort_hide_null": $sort_hide_null, "election_year": $election_year, "election_full": $election_full, "api_key": $api_key, "is_active_candidate": $is_active_candidate, "sort_null_only": $sort_null_only, "per_page": $per_page, "max_election_cycle": $max_election_cycle, "sort": $qp_sort} | compact), body: null}
}

# Aggregated candidate receipts and disbursements grouped by office by party by cycle.
#
# GET /candidates/totals/by_office/by_party/
export def "candidates-totals-by-office-by-party get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: string@office-completer # Federal office candidate runs for: H, S or P
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-year: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --is-active-candidate: oneof<nothing, bool> # Candidates who are actively seeking office. If no value is specified, all candidates are returned. When True is specified, only active candidates are returned. When False is specified, only inactive candidates are returned.
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<election_year: int, office: string, party: string, total_disbursements: float, total_receipts: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "is_active_candidate" $is_active_candidate "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/candidates/totals/by_office/by_party/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_year": $election_year, "election_full": $election_full, "api_key": $api_key, "is_active_candidate": $is_active_candidate, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This endpoint is useful for finding detailed information about a particular committee or filer. Use the `committee_id` to find the most recent information about the committee.
#
# GET /committee/{committee_id}/
export def "committee get" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --filing-frequency: list<string> # The one-letter code of the filing frequency: - A Administratively terminated - D Debt - M Monthly filer - Q Quarterly filer - T Terminated - W Waived
  --cycle: list<int> # A two year election cycle that the committee was active- (after original registration date but before expiration date in Form 1s) The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --year: list<int> # A year that the committee was active— (after original registration date or filing but before expiration date)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --organization-type: list<string> # The one-letter code for the kind for organization: - C corporation - L labor organization - M membership organization - T trade association - V cooperative - W corporation without capital stock
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: name)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<affiliated_committee_name: string, candidate_ids: list, city: string, committee_id: string, committee_type: string, committee_type_full: string, custodian_city: string, custodian_name_1: string, custodian_name_2: string, custodian_name_full: string, custodian_name_middle: string, custodian_name_prefix: string, custodian_name_suffix: string, custodian_name_title: string, custodian_phone: string, custodian_state: string, custodian_street_1: string, custodian_street_2: string, custodian_zip: string, cycles: list, designation: string, designation_full: string, email: string, fax: string, filing_frequency: string, first_f1_date: string, first_file_date: string, form_type: string, jfc_committee: list, last_f1_date: string, last_file_date: string, leadership_pac: string, lobbyist_registrant_pac: string, name: string, organization_type: string, organization_type_full: string, party: string, party_full: string, party_type: string, party_type_full: string, sponsor_candidate_ids: list, state: string, state_full: string, street_1: string, street_2: string, treasurer_city: string, treasurer_name: string, treasurer_name_1: string, treasurer_name_2: string, treasurer_name_middle: string, treasurer_name_prefix: string, treasurer_name_suffix: string, treasurer_name_title: string, treasurer_phone: string, treasurer_state: string, treasurer_street_1: string, treasurer_street_2: string, treasurer_zip: string, website: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  let qp = [(serialize-qp "designation" $designation "multi") (serialize-qp "committee_type" $committee_type "multi") (serialize-qp "page" $page "scalar") (serialize-qp "filing_frequency" $filing_frequency "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "year" $year "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "organization_type" $organization_type "multi") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committee/{committee_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"designation": $designation, "committee_type": $committee_type, "page": $page, "filing_frequency": $filing_frequency, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "year": $year, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "organization_type": $organization_type, "sort": $qp_sort} | compact), body: null}
}

# This endpoint is useful for finding detailed information about a particular candidate. Use the `candidate_id` to find the most recent information about that candidate.
#
# GET /committee/{committee_id}/candidates/
export def "committee-candidates get" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string> # Federal office candidate runs for: H, S or P
  --candidate-status: list<string> # One-letter code explaining if the candidate is: - C present candidate - F future candidate - N not yet a candidate - P prior candidate
  --cycle: list<int> # Two-year election cycle in which a candidate runs for office. Calculated from Form 2. The cycle begins with an odd year and is named for its ending, even year. This cycle follows the traditional house election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. To retrieve data for the entire four years of a presidential term or six years of a senatorial term, you will need the `election_full` flag.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --state: list<string> # US state or territory where a candidate runs for office
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --year: string # Retrieve records pertaining to a particular election year. The list of election years is based on a candidate filing a statement of candidacy (F2) for that year.
  --name: list<string> # Name (candidate or committee) to search for. Alias for 'q'.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --federal-funds-flag: oneof<nothing, bool> # A boolean the describes if a presidential candidate has accepted federal funds. The flag will be false for House and Senate candidates.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: name)
  --has-raised-funds: oneof<nothing, bool> # A boolean that describes if a candidate's committee has ever received any receipts for their campaign for this particular office. (Candidates have separate candidate IDs for each office.)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --incumbent-challenge: list<string> # One-letter code ('I', 'C', 'O') explaining if the candidate is an incumbent, a challenger, or if the seat is open.
  --party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, address_city: string, address_state: string, address_street_1: string, address_street_2: string, address_zip: string, candidate_id: string, candidate_inactive: bool, candidate_status: string, cycles: list, district: string, district_number: int, election_districts: list, election_years: list, federal_funds_flag: bool, first_file_date: string, flags: string, has_raised_funds: bool, incumbent_challenge: string, incumbent_challenge_full: string, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, party: string, party_full: string, state: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "candidate_status" $candidate_status "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "state" $state "multi") (serialize-qp "district" $district "multi") (serialize-qp "year" $year "scalar") (serialize-qp "name" $name "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "federal_funds_flag" $federal_funds_flag "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "has_raised_funds" $has_raised_funds "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "incumbent_challenge" $incumbent_challenge "multi") (serialize-qp "party" $party "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committee/{committee_id}/candidates/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "candidate_status": $candidate_status, "cycle": $cycle, "sort_nulls_last": $sort_nulls_last, "state": $state, "district": $district, "year": $year, "name": $name, "sort_hide_null": $sort_hide_null, "federal_funds_flag": $federal_funds_flag, "per_page": $per_page, "page": $page, "sort": $qp_sort, "has_raised_funds": $has_raised_funds, "election_year": $election_year, "api_key": $api_key, "sort_null_only": $sort_null_only, "incumbent_challenge": $incumbent_challenge, "party": $party} | compact), body: null}
}

# Find out a candidate's characteristics over time. This is particularly useful if the candidate runs for the same office in different districts or you want to know more about a candidate's previous races. This information is organized by `candidate_id`, so it won't help you find a candidate who ran for different offices over time; candidates get a new ID for each office.
#
# GET /committee/{committee_id}/candidates/history/
export def "committee-candidates-history list" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -two_year_period)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, address_city: string, address_state: string, address_street_1: string, address_street_2: string, address_zip: string, candidate_election_year: int, candidate_id: string, candidate_inactive: bool, candidate_status: string, cycles: list, district: string, district_number: int, election_districts: list, election_years: list, fec_cycles_in_election: list, first_file_date: string, flags: string, incumbent_challenge: string, incumbent_challenge_full: string, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, party: string, party_full: string, rounded_election_years: list, state: string, two_year_period: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committee/{committee_id}/candidates/history/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "election_full": $election_full, "page": $page} | compact), body: null}
}

# Find out a candidate's characteristics over time. This is particularly useful if the candidate runs for the same office in different districts or you want to know more about a candidate's previous races. This information is organized by `candidate_id`, so it won't help you find a candidate who ran for different offices over time; candidates get a new ID for each office.
#
# GET /committee/{committee_id}/candidates/history/{cycle}/
export def "committee-candidates-history get" [
  committee_id: string
  cycle: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -two_year_period)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_through: int, address_city: string, address_state: string, address_street_1: string, address_street_2: string, address_zip: string, candidate_election_year: int, candidate_id: string, candidate_inactive: bool, candidate_status: string, cycles: list, district: string, district_number: int, election_districts: list, election_years: list, fec_cycles_in_election: list, first_file_date: string, flags: string, incumbent_challenge: string, incumbent_challenge_full: string, last_f2_date: string, last_file_date: string, load_date: string, name: string, office: string, office_full: string, party: string, party_full: string, rounded_election_years: list, state: string, two_year_period: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  if ($cycle | is-empty) { error make --unspanned { msg: "path parameter 'cycle' must be non-empty" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id), cycle: (encode-path-segment $cycle)} | format pattern "/committee/{committee_id}/candidates/history/{cycle}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "election_full": $election_full, "page": $page} | compact), body: null}
}

# All official records and reports filed by or delivered to the FEC. Note: because the filings data includes many records, counts for large result sets are approximate; you will want to page through the records until no records are returned.
#
# GET /committee/{committee_id}/filings/
export def "committee-filings get" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string> # Federal office candidate runs for: H, S or P
  --file-number: list<int> # Filing ID number
  --form-category: list<string> # The forms filed are categorized based on the nature of the filing: - REPORT F3, F3X, F3P, F3L, F4, F5, F7, F13 - NOTICE F5, F24, F6, F9, F10, F11 - STATEMENT F1, F2 - OTHER F1M, F8, F99, F12, FRQ
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --document-type: list<string> # The type of document for documents other than reports: - 2 24 Hour Contribution Notice - 4 48 Hour Contribution Notice - A Debt Settlement Statement - B Acknowledgment of Receipt of Debt Settlement Statement - C RFAI: Debt Settlement First Notice - D Commission Debt Settlement Review - E Commission Response TO Debt Settlement Request - F Administrative Termination - G Debt Settlement Plan Amendment - H Disavowal Notice - I Disavowal Response - J Conduit Report - K Termination Approval - L Repeat Non-Filer Notice - M Filing Frequency Change Notice - N Paper Amendment to Electronic Report - O Acknowledgment of Filing Frequency Change - S RFAI: Debt Settlement Second - T Miscellaneous Report TO FEC - V Repeat Violation Notice (441A OR 441B) - P Notice of Paper Filing - R F3L Filing Frequency Change Notice - Q Acknowledgment of F3L Filing Frequency Change - U Unregistered Committee Notice
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --state: list<string> # US state or territory where a candidate runs for office
  --amendment-indicator: list<string> # Amendent types: -N new -A amendment -T terminated -C consolidated -M multi-candidate -S secondary NULL might be new or amendment. If amendment indicator is null and the filings is the first or first in a chain treat it as if it was a new. If it is not the first or first in a chain then treat the filing as an amendment.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --is-amended: oneof<nothing, bool> # False indicates that a report is the most recent. True indicates that the report has been superseded by an amendment.
  --filer-type: string@filer-type-completer # The method used to file with the FEC, either electronic or on paper.
  --max-receipt-date: string # Selects all filings received before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --primary-general-indicator: list<string> # Primary, general or special election indicator.
  --request-type: list<string> # Requests for additional information (RFAIs) sent to filers. The request type is based on the type of document filed: - 1 Statement of Organization - 2 Report of Receipts and Expenditures (Form 3 and 3X) - 3 Second Notice - Reports - 4 Request for Additional Information - 5 Informational - Reports - 6 Second Notice - Statement of Organization - 7 Failure to File - 8 From Public Disclosure - 9 From Multi Candidate Status
  --report-year: list<int> # Forms with coverage date - year from the coverage ending date. Forms without coverage date - year from the receipt date.
  --form-type: list<string> # The form where the underlying data comes from, for example, Form 1 would appear as F1: - F1 Statement of Organization - F1M Notification of Multicandidate Status - F2 Statement of Candidacy - F3 Report of Receipts and Disbursements for an Authorized Committee - F3P Report of Receipts and Disbursements by an Authorized Committee of a Candidate for The Office of President or Vice President - F3L Report of Contributions Bundled by Lobbyists/Registrants and Lobbyist/Registrant PACs - F3X Report of Receipts and Disbursements for other than an Authorized Committee - F4 Report of Receipts and Disbursements for a Committee or Organization Supporting a Nomination Convention - F5 Report of Independent Expenditures Made and Contributions Received - F6 48 Hour Notice of Contributions/Loans Received - F7 Report of Communication Costs by Corporations and Membership Organizations - F8 Debt Settlement Plan - F9 24 Hour Notice of Disbursements for Electioneering Communications - F13 Report of Donations Accepted for Inaugural Committee - F99 Miscellaneous Text - FRQ Request for Additional Information
  --committee-type: string # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --beginning-image-number: list<string> # Unique identifier for the electronic or paper report. This number is used to construct PDF URLs to the original document.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [-receipt_date])
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-receipt-date: string # Selects all filings received after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --q-filer: list<string> # Keyword search for filer name or ID
  --report-type: list<string> # Name of report where the underlying data comes from: - 10D Pre-Election - 10G Pre-General - 10P Pre-Primary - 10R Pre-Run-Off - 10S Pre-Special - 12C Pre-Convention - 12G Pre-General - 12P Pre-Primary - 12R Pre-Run-Off - 12S Pre-Special - 30D Post-Election - 30G Post-General - 30P Post-Primary - 30R Post-Run-Off - 30S Post-Special - 60D Post-Convention - M1 January Monthly - M10 October Monthly - M11 November Monthly - M12 December Monthly - M2 February Monthly - M3 March Monthly - M4 April Monthly - M5 May Monthly - M6 June Monthly - M7 July Monthly - M8 August Monthly - M9 September Monthly - MY Mid-Year Report - Q1 April Quarterly - Q2 July Quarterly - Q3 October Quarterly - TER Termination Report - YE Year-End - ADJ COMP ADJUST AMEND - CA COMPREHENSIVE AMEND - 90S Post Inaugural Supplement - 90D Post Inaugural - 48 48 Hour Notification - 24 24 Hour Notification - M7S July Monthly/Semi-Annual - MSA Monthly Semi-Annual (MY) - MYS Monthly Year End/Semi-Annual - Q2S July Quarterly/Semi-Annual - QSA Quarterly Semi-Annual (MY) - QYS Quarterly Year End/Semi-Annual - QYE Quarterly Semi-Annual (YE) - QMS Quarterly Mid-Year/ Semi-Annual - MSY Monthly Semi-Annual (YE)
  --party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
  --most-recent: oneof<nothing, bool> # Report is either new or is the most-recently filed amendment
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<additional_bank_names: list, amendment_chain: list, amendment_indicator: string, amendment_version: int, bank_depository_city: string, bank_depository_name: string, bank_depository_state: string, bank_depository_street_1: string, bank_depository_street_2: string, bank_depository_zip: string, beginning_image_number: string, candidate_id: string, candidate_name: string, cash_on_hand_beginning_period: float, cash_on_hand_end_period: float, committee_id: string, committee_name: string, committee_type: string, coverage_end_date: string, coverage_start_date: string, csv_url: string, cycle: int, debts_owed_by_committee: float, debts_owed_to_committee: float, document_description: string, document_type: string, document_type_full: string, election_year: int, ending_image_number: string, fec_file_id: string, fec_url: string, file_number: int, form_category: string, form_type: string, house_personal_funds: float, html_url: string, is_amended: bool, means_filed: string, most_recent: bool, most_recent_file_number: int, net_donations: float, office: string, opposition_personal_funds: float, pages: int, party: string, pdf_url: string, previous_file_number: int, primary_general_indicator: string, receipt_date: string, report_type: string, report_type_full: string, report_year: int, request_type: string, senate_personal_funds: float, state: string, sub_id: string, total_communication_cost: float, total_disbursements: float, total_independent_expenditures: float, total_individual_contributions: float, total_receipts: float, treasurer_name: string, update_date: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "file_number" $file_number "multi") (serialize-qp "form_category" $form_category "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "multi") (serialize-qp "document_type" $document_type "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "state" $state "multi") (serialize-qp "amendment_indicator" $amendment_indicator "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "is_amended" $is_amended "scalar") (serialize-qp "filer_type" $filer_type "scalar") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "primary_general_indicator" $primary_general_indicator "multi") (serialize-qp "request_type" $request_type "multi") (serialize-qp "report_year" $report_year "multi") (serialize-qp "form_type" $form_type "multi") (serialize-qp "committee_type" $committee_type "scalar") (serialize-qp "beginning_image_number" $beginning_image_number "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "q_filer" $q_filer "multi") (serialize-qp "report_type" $report_type "multi") (serialize-qp "party" $party "multi") (serialize-qp "most_recent" $most_recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committee/{committee_id}/filings/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "file_number": $file_number, "form_category": $form_category, "cycle": $cycle, "district": $district, "document_type": $document_type, "sort_hide_null": $sort_hide_null, "state": $state, "amendment_indicator": $amendment_indicator, "sort_nulls_last": $sort_nulls_last, "is_amended": $is_amended, "filer_type": $filer_type, "max_receipt_date": $max_receipt_date, "per_page": $per_page, "primary_general_indicator": $primary_general_indicator, "request_type": $request_type, "report_year": $report_year, "form_type": $form_type, "committee_type": $committee_type, "beginning_image_number": $beginning_image_number, "page": $page, "sort": $qp_sort, "api_key": $api_key, "min_receipt_date": $min_receipt_date, "sort_null_only": $sort_null_only, "q_filer": $q_filer, "report_type": $report_type, "party": $party, "most_recent": $most_recent} | compact), body: null}
}

# Explore a filer's characteristics over time. This can be particularly useful if the committees change treasurers, designation, or `committee_type`.
#
# GET /committee/{committee_id}/history/
export def "committee-history list" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -cycle)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<affiliated_committee_name: string, candidate_ids: list, city: string, committee_id: string, committee_label: string, committee_type: string, committee_type_full: string, convert_to_pac_flag: bool, cycle: int, cycles: list, cycles_has_activity: list, cycles_has_financial: list, designation: string, designation_full: string, filing_frequency: string, first_f1_date: string, first_file_date: string, former_candidate_election_year: int, former_candidate_id: string, former_candidate_name: string, former_committee_name: string, is_active: bool, jfc_committee: list, last_cycle_has_activity: int, last_cycle_has_financial: int, last_f1_date: string, last_file_date: string, name: string, organization_type: string, organization_type_full: string, party: string, party_full: string, sponsor_candidate_ids: list, state: string, state_full: string, street_1: string, street_2: string, treasurer_name: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  let qp = [(serialize-qp "designation" $designation "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committee/{committee_id}/history/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"designation": $designation, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Explore a filer's characteristics over time. This can be particularly useful if the committees change treasurers, designation, or `committee_type`.
#
# GET /committee/{committee_id}/history/{cycle}/
export def "committee-history get" [
  committee_id: string
  cycle: int
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -cycle)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<affiliated_committee_name: string, candidate_ids: list, city: string, committee_id: string, committee_label: string, committee_type: string, committee_type_full: string, convert_to_pac_flag: bool, cycle: int, cycles: list, cycles_has_activity: list, cycles_has_financial: list, designation: string, designation_full: string, filing_frequency: string, first_f1_date: string, first_file_date: string, former_candidate_election_year: int, former_candidate_id: string, former_candidate_name: string, former_committee_name: string, is_active: bool, jfc_committee: list, last_cycle_has_activity: int, last_cycle_has_financial: int, last_f1_date: string, last_file_date: string, name: string, organization_type: string, organization_type_full: string, party: string, party_full: string, sponsor_candidate_ids: list, state: string, state_full: string, street_1: string, street_2: string, treasurer_name: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  if ($cycle | is-empty) { error make --unspanned { msg: "path parameter 'cycle' must be non-empty" } }
  let qp = [(serialize-qp "designation" $designation "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id), cycle: (encode-path-segment $cycle)} | format pattern "/committee/{committee_id}/history/{cycle}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"designation": $designation, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Each report represents the summary information from Form 3, Form 3X and Form 3P. These reports have key statistics that illuminate the financial status of a given committee. Things like cash on hand, debts owed by committee, total receipts, and total disbursements are especially helpful for understanding a committee's financial dealings. By default, this endpoint includes both amended and final versions of each report. To restrict to only the final versions of each report, use `is_amended=false`; to retrieve only reports that have been amended, use `is_amended=true`. Several different reporting structures exist, depending on the type of organization that submits financial information. To see an example of these reporting requirements, look at the summary and detailed summary pages of Form 3, Form 3X, and Form 3P. DISCLAIMER: The field labels contained within this resource are subject to change. We are attempting to succinctly label these fields while conveying clear meaning to ensure accessibility for all users.
#
# GET /committee/{committee_id}/reports/
export def "committee-reports get" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-debts-owed-amount: string # Filter for all amounts greater than a value.
  --max-disbursements-amount: string # Filter for all amounts less than a value.
  --max-total-contributions: string # Filter for all amounts less than a value.
  --max-debts-owed-expenditures: string # Filter for all amounts less than a value.
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --year: list<int> # Forms with coverage date - year from the coverage ending date. Forms without coverage date - year from the receipt date.
  --max-receipts-amount: string # Filter for all amounts less than a value.
  --max-cash-on-hand-end-period-amount: string # Filter for all amounts less than a value.
  --is-amended: oneof<nothing, bool> # False indicates that a report is the most recent. True indicates that the report has been superseded by an amendment.
  --min-disbursements-amount: string # Filter for all amounts greater than a value.
  --max-party-coordinated-expenditures: string # Filter for all amounts less than a value.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --max-independent-expenditures: string # Filter for all amounts less than a value.
  --min-receipts-amount: string # Filter for all amounts greater than a value.
  --min-party-coordinated-expenditures: string # Filter for all amounts greater than a value.
  --candidate-id: string # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --beginning-image-number: list<string> # Unique identifier for the electronic or paper report. This number is used to construct PDF URLs to the original document.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [-coverage_end_date])
  --min-total-contributions: string # Filter for all amounts greater than a value.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-cash-on-hand-end-period-amount: string # Filter for all amounts greater than a value.
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --min-independent-expenditures: string # Filter for all amounts greater than a value.
  --report-type: list<string> # Report type; prefix with "-" to exclude. Name of report where the underlying data comes from: - 10D Pre-Election - 10G Pre-General - 10P Pre-Primary - 10R Pre-Run-Off - 10S Pre-Special - 12C Pre-Convention - 12G Pre-General - 12P Pre-Primary - 12R Pre-Run-Off - 12S Pre-Special - 30D Post-Election - 30G Post-General - 30P Post-Primary - 30R Post-Run-Off - 30S Post-Special - 60D Post-Convention - M1 January Monthly - M10 October Monthly - M11 November Monthly - M12 December Monthly - M2 February Monthly - M3 March Monthly - M4 April Monthly - M5 May Monthly - M6 June Monthly - M7 July Monthly - M8 August Monthly - M9 September Monthly - MY Mid-Year Report - Q1 April Quarterly - Q2 July Quarterly - Q3 October Quarterly - TER Termination Report - YE Year-End - ADJ COMP ADJUST AMEND - CA COMPREHENSIVE AMEND
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<aggregate_amount_personal_contributions_general: float, aggregate_contributions_personal_funds_primary: float, all_loans_received_period: float, all_loans_received_ytd: float, all_other_loans_period: float, all_other_loans_ytd: float, allocated_federal_election_levin_share_period: float, amendment_chain: list, amendment_indicator: string, amendment_indicator_full: string, beginning_image_number: string, calendar_ytd: int, candidate_contribution_period: float, candidate_contribution_ytd: float, cash_on_hand_beginning_calendar_ytd: float, cash_on_hand_beginning_period: float, cash_on_hand_close_ytd: float, cash_on_hand_end_period: float, committee_id: string, committee_name: string, committee_type: string, coordinated_expenditures_by_party_committee_period: float, coordinated_expenditures_by_party_committee_ytd: float, coverage_end_date: string, coverage_start_date: string, csv_url: string, cycle: int, debts_owed_by_committee: float, debts_owed_to_committee: float, document_description: string, end_image_number: string, exempt_legal_accounting_disbursement_period: float, exempt_legal_accounting_disbursement_ytd: float, expenditure_subject_to_limits: float, fec_file_id: string, fec_url: string, fed_candidate_committee_contribution_refunds_ytd: float, fed_candidate_committee_contributions_period: float, fed_candidate_committee_contributions_ytd: float, fed_candidate_contribution_refunds_period: float, federal_funds_period: float, federal_funds_ytd: float, file_number: int, fundraising_disbursements_period: float, fundraising_disbursements_ytd: float, gross_receipt_authorized_committee_general: float, gross_receipt_authorized_committee_primary: float, gross_receipt_minus_personal_contribution_general: float, gross_receipt_minus_personal_contributions_primary: float, html_url: string, independent_contributions_period: float, independent_expenditures_period: float, independent_expenditures_ytd: float, individual_itemized_contributions_period: float, individual_itemized_contributions_ytd: float, individual_unitemized_contributions_period: float, individual_unitemized_contributions_ytd: float, is_amended: bool, items_on_hand_liquidated: float, loan_repayments_candidate_loans_period: float, loan_repayments_candidate_loans_ytd: float, loan_repayments_made_period: float, loan_repayments_made_ytd: float, loan_repayments_other_loans_period: float, loan_repayments_other_loans_ytd: float, loan_repayments_received_period: float, loan_repayments_received_ytd: float, loans_made_by_candidate_period: float, loans_made_by_candidate_ytd: float, loans_made_period: float, loans_made_ytd: float, loans_received_from_candidate_period: float, loans_received_from_candidate_ytd: float, means_filed: string, most_recent: bool, most_recent_file_number: float, net_contributions_cycle_to_date: float, net_contributions_period: float, net_contributions_ytd: float, net_operating_expenditures_cycle_to_date: float, net_operating_expenditures_period: float, net_operating_expenditures_ytd: float, non_allocated_fed_election_activity_period: float, non_allocated_fed_election_activity_ytd: float, nonfed_share_allocated_disbursements_period: float, offsets_to_fundraising_expenditures_period: float, offsets_to_fundraising_expenditures_ytd: float, offsets_to_legal_accounting_period: float, offsets_to_legal_accounting_ytd: float, offsets_to_operating_expenditures_period: float, offsets_to_operating_expenditures_ytd: float, operating_expenditures_period: float, operating_expenditures_ytd: float, other_disbursements_period: float, other_disbursements_ytd: float, other_fed_operating_expenditures_period: float, other_fed_operating_expenditures_ytd: float, other_fed_receipts_period: float, other_fed_receipts_ytd: float, other_loans_received_period: float, other_loans_received_ytd: float, other_political_committee_contributions_period: float, other_political_committee_contributions_ytd: float, other_receipts_period: float, other_receipts_ytd: float, pdf_url: string, political_party_committee_contributions_period: float, political_party_committee_contributions_ytd: float, previous_file_number: float, receipt_date: string, refunded_individual_contributions_period: float, refunded_individual_contributions_ytd: float, refunded_other_political_committee_contributions_period: float, refunded_other_political_committee_contributions_ytd: float, refunded_political_party_committee_contributions_period: float, refunded_political_party_committee_contributions_ytd: float, refunds_total_contributions_col_total_ytd: float, repayments_loans_made_by_candidate_period: float, repayments_loans_made_candidate_ytd: float, repayments_other_loans_period: float, repayments_other_loans_ytd: float, report_form: string, report_type: string, report_type_full: string, report_year: int, shared_fed_activity_nonfed_ytd: float, shared_fed_activity_period: float, shared_fed_activity_ytd: float, shared_fed_operating_expenditures_period: float, shared_fed_operating_expenditures_ytd: float, shared_nonfed_operating_expenditures_period: float, shared_nonfed_operating_expenditures_ytd: float, subtotal_period: float, subtotal_summary_page_period: float, subtotal_summary_period: float, subtotal_summary_ytd: float, total_contribution_refunds_col_total_period: float, total_contribution_refunds_period: float, total_contribution_refunds_ytd: float, total_contributions_column_total_period: float, total_contributions_period: float, total_contributions_ytd: float, total_disbursements_period: float, total_disbursements_ytd: float, total_fed_disbursements_period: float, total_fed_disbursements_ytd: float, total_fed_election_activity_period: float, total_fed_election_activity_ytd: float, total_fed_operating_expenditures_period: float, total_fed_operating_expenditures_ytd: float, total_fed_receipts_period: float, total_fed_receipts_ytd: float, total_individual_contributions_period: float, total_individual_contributions_ytd: float, total_loan_repayments_made_period: float, total_loan_repayments_made_ytd: float, total_loans_received_period: float, total_loans_received_ytd: float, total_nonfed_transfers_period: float, total_nonfed_transfers_ytd: float, total_offsets_to_operating_expenditures_period: float, total_offsets_to_operating_expenditures_ytd: float, total_operating_expenditures_period: float, total_operating_expenditures_ytd: float, total_period: float, total_receipts_period: float, total_receipts_ytd: float, total_ytd: float, transfers_from_affiliated_committee_period: float, transfers_from_affiliated_committee_ytd: float, transfers_from_affiliated_party_period: float, transfers_from_affiliated_party_ytd: float, transfers_from_nonfed_account_period: float, transfers_from_nonfed_account_ytd: float, transfers_from_nonfed_levin_period: float, transfers_from_nonfed_levin_ytd: float, transfers_from_other_authorized_committee_period: float, transfers_from_other_authorized_committee_ytd: float, transfers_to_affiliated_committee_period: float, transfers_to_affilitated_committees_ytd: float, transfers_to_other_authorized_committee_period: float, transfers_to_other_authorized_committee_ytd: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  let qp = [(serialize-qp "min_debts_owed_amount" $min_debts_owed_amount "scalar") (serialize-qp "max_disbursements_amount" $max_disbursements_amount "scalar") (serialize-qp "max_total_contributions" $max_total_contributions "scalar") (serialize-qp "max_debts_owed_expenditures" $max_debts_owed_expenditures "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "year" $year "multi") (serialize-qp "max_receipts_amount" $max_receipts_amount "scalar") (serialize-qp "max_cash_on_hand_end_period_amount" $max_cash_on_hand_end_period_amount "scalar") (serialize-qp "is_amended" $is_amended "scalar") (serialize-qp "min_disbursements_amount" $min_disbursements_amount "scalar") (serialize-qp "max_party_coordinated_expenditures" $max_party_coordinated_expenditures "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "max_independent_expenditures" $max_independent_expenditures "scalar") (serialize-qp "min_receipts_amount" $min_receipts_amount "scalar") (serialize-qp "min_party_coordinated_expenditures" $min_party_coordinated_expenditures "scalar") (serialize-qp "candidate_id" $candidate_id "scalar") (serialize-qp "beginning_image_number" $beginning_image_number "multi") (serialize-qp "page" $page "scalar") (serialize-qp "type" $type "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "min_total_contributions" $min_total_contributions "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_cash_on_hand_end_period_amount" $min_cash_on_hand_end_period_amount "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "min_independent_expenditures" $min_independent_expenditures "scalar") (serialize-qp "report_type" $report_type "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committee/{committee_id}/reports/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"min_debts_owed_amount": $min_debts_owed_amount, "max_disbursements_amount": $max_disbursements_amount, "max_total_contributions": $max_total_contributions, "max_debts_owed_expenditures": $max_debts_owed_expenditures, "cycle": $cycle, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "year": $year, "max_receipts_amount": $max_receipts_amount, "max_cash_on_hand_end_period_amount": $max_cash_on_hand_end_period_amount, "is_amended": $is_amended, "min_disbursements_amount": $min_disbursements_amount, "max_party_coordinated_expenditures": $max_party_coordinated_expenditures, "per_page": $per_page, "max_independent_expenditures": $max_independent_expenditures, "min_receipts_amount": $min_receipts_amount, "min_party_coordinated_expenditures": $min_party_coordinated_expenditures, "candidate_id": $candidate_id, "beginning_image_number": $beginning_image_number, "page": $page, "type": $type, "sort": $qp_sort, "min_total_contributions": $min_total_contributions, "api_key": $api_key, "min_cash_on_hand_end_period_amount": $min_cash_on_hand_end_period_amount, "sort_null_only": $sort_null_only, "min_independent_expenditures": $min_independent_expenditures, "report_type": $report_type} | compact), body: null}
}

# This endpoint provides information about a committee's Form 3, Form 3X, or Form 3P financial reports, which are aggregated by two-year period. We refer to two-year periods as a `cycle`. The cycle is named after the even-numbered year and includes the year before it. To obtain totals from 2013 and 2014, you would use 2014. In odd-numbered years, the current cycle is the next year — for example, in 2015, the current cycle is 2016. For presidential and Senate candidates, multiple two-year cycles exist between elections.
#
# GET /committee/{committee_id}/totals/
export def "committee-totals get" [
  committee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -cycle)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<all_loans_received: float, all_other_loans: float, allocated_federal_election_levin_share: float, candidate_contribution: float, cash_on_hand_beginning_period: float, committee_designation: string, committee_designation_full: string, committee_id: string, committee_name: string, committee_state: string, committee_type: string, committee_type_full: string, contribution_refunds: float, contributions: float, contributions_ie_and_party_expenditures_made_percent: float, convention_exp: float, coordinated_expenditures_by_party_committee: float, coverage_end_date: string, coverage_start_date: string, cycle: int, disbursements: float, exempt_legal_accounting_disbursement: float, exp_prior_years_subject_limits: float, exp_subject_limits: float, fed_candidate_committee_contributions: float, fed_candidate_contribution_refunds: float, fed_disbursements: float, fed_election_activity: float, fed_operating_expenditures: float, fed_receipts: float, federal_funds: float, filing_frequency: string, filing_frequency_full: string, first_f1_date: string, first_file_date: string, fundraising_disbursements: float, independent_expenditures: float, individual_contributions: float, individual_contributions_percent: float, individual_itemized_contributions: float, individual_unitemized_contributions: float, itemized_convention_exp: float, itemized_other_disb: float, itemized_other_income: float, itemized_other_refunds: float, itemized_refunds_relating_convention_exp: float, last_beginning_image_number: string, last_cash_on_hand_end_period: float, last_debts_owed_by_committee: float, last_debts_owed_to_committee: float, last_report_type_full: string, last_report_year: int, loan_repayments: float, loan_repayments_candidate_loans: float, loan_repayments_made: float, loan_repayments_other_loans: float, loan_repayments_received: float, loans: float, loans_and_loan_repayments_made: float, loans_and_loan_repayments_received: float, loans_made: float, loans_made_by_candidate: float, loans_received: float, loans_received_from_candidate: float, net_contributions: float, net_operating_expenditures: float, non_allocated_fed_election_activity: float, offsets_to_fundraising_expenditures: float, offsets_to_legal_accounting: float, offsets_to_operating_expenditures: float, operating_expenditures: float, operating_expenditures_percent: float, organization_type: string, organization_type_full: string, other_disbursements: float, other_fed_operating_expenditures: float, other_fed_receipts: float, other_loans_received: float, other_political_committee_contributions: float, other_receipts: float, other_refunds: float, party_and_other_committee_contributions_percent: float, party_full: string, pdf_url: string, political_party_committee_contributions: float, receipts: float, refunded_individual_contributions: float, refunded_other_political_committee_contributions: float, refunded_political_party_committee_contributions: float, refunds_relating_convention_exp: float, repayments_loans_made_by_candidate: float, repayments_other_loans: float, report_form: string, shared_fed_activity: float, shared_fed_activity_nonfed: float, shared_fed_operating_expenditures: float, shared_nonfed_operating_expenditures: float, total_exp_subject_limits: float, total_independent_contributions: float, total_independent_expenditures: float, total_offsets_to_operating_expenditures: float, total_transfers: float, transaction_coverage_date: string, transfers_from_affiliated_committee: float, transfers_from_affiliated_party: float, transfers_from_nonfed_account: float, transfers_from_nonfed_levin: float, transfers_from_other_authorized_committee: float, transfers_to_affiliated_committee: float, transfers_to_other_authorized_committee: float, treasurer_name: string, unitemized_convention_exp: float, unitemized_other_disb: float, unitemized_other_income: float, unitemized_other_refunds: float, unitemized_refunds_relating_convention_exp: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($committee_id | is-empty) { error make --unspanned { msg: "path parameter 'committee_id' must be non-empty" } }
  let qp = [(serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({committee_id: (encode-path-segment $committee_id)} | format pattern "/committee/{committee_id}/totals/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cycle": $cycle, "sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "api_key": $api_key, "page": $page} | compact), body: null}
}

# Fetch basic information about committees and filers. Use parameters to filter for particular characteristics.
#
# GET /committees/
export def "committees get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --max-first-f1-date: string # Filter for committees whose first Form 1 was received on or before this date. (format: date)
  --min-first-f1-date: string # Filter for committees whose first Form 1 was received on or after this date. (format: date)
  --cycle: list<int> # A two year election cycle that the committee was active- (after original registration date but before expiration date in Form 1s) The cycle begins with an odd year and is named for its ending, even year.
  --filing-frequency: list<string> # The one-letter code of the filing frequency: - A Administratively terminated - D Debt - M Monthly filer - Q Quarterly filer - T Terminated - W Waived
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --year: list<int> # A year that the committee was active— (after original registration date or filing but before expiration date)
  --state: list<string> # US state or territory
  --sponsor-candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office. This is a filter for Leadership PAC sponsor.
  --q: list<string> # The name of the committee. If a committee changes its name, the most recent name will be shown. Committee names are not unique. Use committee_id for looking up records.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --min-last-f1-date: string # Filter for committees whose latest Form 1 was received on or after this date. (format: date)
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --min-first-file-date: string # Filter for committees whose first filing was received on or after this date. (format: date)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: name)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --max-last-f1-date: string # Filter for committees whose latest Form 1 was received on or before this date. (format: date)
  --treasurer-name: list<string> # Name of the Committee's treasurer. If multiple treasurers for the committee, the most recent treasurer will be shown.
  --organization-type: list<string> # The one-letter code for the kind for organization: - C corporation - L labor organization - M membership organization - T trade association - V cooperative - W corporation without capital stock
  --max-first-file-date: string # Filter for committees whose first filing was received on or before this date. (format: date)
  --party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<affiliated_committee_name: string, candidate_ids: list, committee_id: string, committee_type: string, committee_type_full: string, cycles: list, designation: string, designation_full: string, filing_frequency: string, first_f1_date: string, first_file_date: string, last_f1_date: string, last_file_date: string, name: string, organization_type: string, organization_type_full: string, party: string, party_full: string, sponsor_candidate_ids: list, sponsor_candidate_list: list, state: string, treasurer_name: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "designation" $designation "multi") (serialize-qp "max_first_f1_date" $max_first_f1_date "scalar") (serialize-qp "min_first_f1_date" $min_first_f1_date "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "filing_frequency" $filing_frequency "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "year" $year "multi") (serialize-qp "state" $state "multi") (serialize-qp "sponsor_candidate_id" $sponsor_candidate_id "multi") (serialize-qp "q" $q "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "min_last_f1_date" $min_last_f1_date "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "committee_type" $committee_type "multi") (serialize-qp "min_first_file_date" $min_first_file_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "max_last_f1_date" $max_last_f1_date "scalar") (serialize-qp "treasurer_name" $treasurer_name "multi") (serialize-qp "organization_type" $organization_type "multi") (serialize-qp "max_first_file_date" $max_first_file_date "scalar") (serialize-qp "party" $party "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/committees/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"designation": $designation, "max_first_f1_date": $max_first_f1_date, "min_first_f1_date": $min_first_f1_date, "cycle": $cycle, "filing_frequency": $filing_frequency, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "year": $year, "state": $state, "sponsor_candidate_id": $sponsor_candidate_id, "q": $q, "per_page": $per_page, "min_last_f1_date": $min_last_f1_date, "candidate_id": $candidate_id, "committee_type": $committee_type, "min_first_file_date": $min_first_file_date, "page": $page, "sort": $qp_sort, "committee_id": $committee_id, "api_key": $api_key, "sort_null_only": $sort_null_only, "max_last_f1_date": $max_last_f1_date, "treasurer_name": $treasurer_name, "organization_type": $organization_type, "max_first_file_date": $max_first_file_date, "party": $party} | compact), body: null}
}

# 52 U.S.C. 30118 allows "communications by a corporation to its stockholders and executive or administrative personnel and their families or by a labor organization to its members and their families on any subject," including the express advocacy of the election or defeat of any Federal candidate. The costs of such communications must be reported to the Federal Election Commission under certain circumstances.
#
# GET /communication_costs/
export def "communication-costs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-amount: string # Filter for all amounts less than a value.
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --support-oppose-indicator: list<string> # Support or opposition
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-date: string # Minimum date (format: date)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-amount: string # Filter for all amounts greater than a value.
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
  --max-date: string # Maximum date (format: date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<action_code: string, action_code_full: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_full: string, candidate_office_state: string, committee_id: string, committee_name: string, communication_class: string, communication_type: string, communication_type_full: string, cycle: int, file_number: int, form_type_code: string, image_number: string, original_sub_id: int, pdf_url: string, primary_general_indicator: string, primary_general_indicator_description: string, purpose: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, state_full: string, sub_id: int, support_oppose_indicator: string, tran_id: string, transaction_amount: float, transaction_date: string, transaction_type: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "support_oppose_indicator" $support_oppose_indicator "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/communication_costs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_amount": $max_amount, "max_image_number": $max_image_number, "sort_nulls_last": $sort_nulls_last, "support_oppose_indicator": $support_oppose_indicator, "sort_hide_null": $sort_hide_null, "line_number": $line_number, "per_page": $per_page, "candidate_id": $candidate_id, "page": $page, "min_date": $min_date, "committee_id": $committee_id, "api_key": $api_key, "min_amount": $min_amount, "min_image_number": $min_image_number, "sort_null_only": $sort_null_only, "image_number": $image_number, "sort": $qp_sort, "max_date": $max_date} | compact), body: null}
}

# Communication cost aggregated by candidate ID and committee ID.
#
# GET /communication_costs/aggregates/
export def "communication-costs-aggregates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --support-oppose-indicator: string@support-oppose-indicator-completer # Support or opposition
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate: string, candidate_id: string, candidate_name: string, committee: string, committee_id: string, committee_name: string, count: int, cycle: int, support_oppose_indicator: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "support_oppose_indicator" $support_oppose_indicator "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/communication_costs/aggregates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "page": $page, "cycle": $cycle, "support_oppose_indicator": $support_oppose_indicator, "sort_hide_null": $sort_hide_null, "sort_nulls_last": $sort_nulls_last, "committee_id": $committee_id, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Communication cost aggregated by candidate ID and committee ID.
#
# GET /communication_costs/by_candidate/
export def "communication-costs-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: string@office-completer-1 # Federal office candidate runs for: H, S or P
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --district: string # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --state: string # US state or territory where a candidate runs for office
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --support-oppose: string@support-oppose-completer # Support or opposition
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate: string, candidate_id: string, candidate_name: string, committee: string, committee_id: string, committee_name: string, count: int, cycle: int, support_oppose_indicator: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "support_oppose" $support_oppose "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/communication_costs/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "candidate_id": $candidate_id, "cycle": $cycle, "district": $district, "state": $state, "page": $page, "support_oppose": $support_oppose, "election_full": $election_full, "sort_hide_null": $sort_hide_null, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Total communications costs aggregated across committees on supported or opposed candidates by cycle or candidate election year.
#
# GET /communication_costs/totals/by_candidate/
export def "communication-costs-totals-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, cycle: int, support_oppose_indicator: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/communication_costs/totals/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "page": $page, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Basic information about electronic files coming into the FEC, posted as they are received.
#
# GET /efile/filings/
export def "efile-filings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-number: list<int> # Filing ID number
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-receipt-date: string # Selects all filings received after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --max-receipt-date: string # Selects all filings received before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --q-filer: list<string> # Keyword search for filer name or ID
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -receipt_date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<amended_by: int, amendment_chain: list, amendment_number: int, amends_file: int, beginning_image_number: string, committee_id: string, committee_name: string, coverage_end_date: string, coverage_start_date: string, csv_url: string, document_description: string, ending_image_number: string, fec_file_id: string, fec_url: string, file_number: int, filed_date: string, form_type: string, html_url: string, is_amended: bool, load_timestamp: string, most_recent: bool, most_recent_filing: int, pdf_url: string, receipt_date: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_number" $file_number "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "q_filer" $q_filer "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/efile/filings/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"file_number": $file_number, "sort_nulls_last": $sort_nulls_last, "page": $page, "per_page": $per_page, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "min_receipt_date": $min_receipt_date, "max_receipt_date": $max_receipt_date, "q_filer": $q_filer, "sort_null_only": $sort_null_only, "sort": $qp_sort} | compact), body: null}
}

# Key financial data reported periodically by committees as they are reported. This feed includes summary information from the the House F3 reports, the presidential F3p reports and the PAC and party F3x reports. Generally, committees file reports on a quarterly or monthly basis, but some must also submit a report 12 days before primary elections. Therefore, during the primary season, the period covered by this file may be different for different committees. These totals also incorporate any changes made by committees, if any report covering the period is amended. DISCLAIMER: The field labels contained within this resource are subject to change. We are attempting to succinctly label these fields while conveying clear meaning to ensure accessibility for all users.
#
# GET /efile/reports/house-senate/
export def "efile-reports-house-senate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-number: list<int> # Filing ID number
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-receipt-date: string # Selects all filings received after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --max-receipt-date: string # Selects all filings received before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --q-filer: list<string> # Keyword search for filer name or ID
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -receipt_date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<amended_address: string, amended_by: int, amendment: string, amendment_chain: list, beginning_image_number: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_prefix: string, candidate_suffix: string, cash_on_hand_beginning_period: int, city: string, committee_id: string, committee_name: string, coverage_end_date: string, coverage_start_date: string, csv_url: string, district: int, document_description: string, election_date: string, election_state: string, f3z1: int, fec_file_id: string, fec_url: string, file_number: int, general_election: string, is_amended: bool, most_recent: bool, most_recent_filing: int, pdf_url: string, prefix: string, primary_election: string, receipt_date: string, report: string, report_type: string, report_year: int, rpt_pgi: string, runoff_election: string, sign_date: string, special_election: string, state: string, street_1: string, street_2: string, suffix: string, summary_lines: string, treasurer_first_name: string, treasurer_last_name: string, treasurer_middle_name: string, treasurer_name: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_number" $file_number "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "q_filer" $q_filer "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/efile/reports/house-senate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"file_number": $file_number, "sort_nulls_last": $sort_nulls_last, "page": $page, "per_page": $per_page, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "min_receipt_date": $min_receipt_date, "max_receipt_date": $max_receipt_date, "q_filer": $q_filer, "sort_null_only": $sort_null_only, "sort": $qp_sort} | compact), body: null}
}

# Key financial data reported periodically by committees as they are reported. This feed includes summary information from the the House F3 reports, the presidential F3p reports and the PAC and party F3x reports. Generally, committees file reports on a quarterly or monthly basis, but some must also submit a report 12 days before primary elections. Therefore, during the primary season, the period covered by this file may be different for different committees. These totals also incorporate any changes made by committees, if any report covering the period is amended. DISCLAIMER: The field labels contained within this resource are subject to change. We are attempting to succinctly label these fields while conveying clear meaning to ensure accessibility for all users.
#
# GET /efile/reports/pac-party/
export def "efile-reports-pac-party get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-number: list<int> # Filing ID number
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-receipt-date: string # Selects all filings received after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --max-receipt-date: string # Selects all filings received before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --q-filer: list<string> # Keyword search for filer name or ID
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -receipt_date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<amend_address: string, amended_by: int, amendment: string, amendment_chain: list, beginning_image_number: string, city: string, committee_id: string, committee_name: string, coverage_end_date: string, coverage_start_date: string, csv_url: string, document_description: string, election_date: string, election_state: string, fec_file_id: string, fec_url: string, file_number: int, is_amended: bool, most_recent: bool, most_recent_filing: int, pdf_url: string, qualified_multicandidate_committee: string, receipt_date: string, report: string, report_type: string, report_year: int, rpt_pgi: string, sign_date: string, state: string, street_1: string, street_2: string, summary_lines: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_number" $file_number "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "q_filer" $q_filer "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/efile/reports/pac-party/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"file_number": $file_number, "sort_nulls_last": $sort_nulls_last, "page": $page, "per_page": $per_page, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "min_receipt_date": $min_receipt_date, "max_receipt_date": $max_receipt_date, "q_filer": $q_filer, "sort_null_only": $sort_null_only, "sort": $qp_sort} | compact), body: null}
}

# Key financial data reported periodically by committees as they are reported. This feed includes summary information from the the House F3 reports, the presidential F3p reports and the PAC and party F3x reports. Generally, committees file reports on a quarterly or monthly basis, but some must also submit a report 12 days before primary elections. Therefore, during the primary season, the period covered by this file may be different for different committees. These totals also incorporate any changes made by committees, if any report covering the period is amended. DISCLAIMER: The field labels contained within this resource are subject to change. We are attempting to succinctly label these fields while conveying clear meaning to ensure accessibility for all users.
#
# GET /efile/reports/presidential/
export def "efile-reports-presidential get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-number: list<int> # Filing ID number
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-receipt-date: string # Selects all filings received after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --max-receipt-date: string # Selects all filings received before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --q-filer: list<string> # Keyword search for filer name or ID
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -receipt_date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<amended_by: int, amendment: string, amendment_chain: list, beginning_image_number: string, cash_on_hand_beginning_period: float, cash_on_hand_end_period: float, city: string, committee_id: string, committee_name: string, coverage_end_date: string, coverage_start_date: string, csv_url: string, debts_owed_by_committee: float, debts_owed_to_committee: float, document_description: string, election_date: string, election_state: string, expenditure_subject_to_limits: float, fec_file_id: string, fec_url: string, file_number: int, general_election: string, is_amended: bool, most_recent: bool, most_recent_filing: int, net_contributions_cycle_to_date: float, net_operating_expenditures_cycle_to_date: float, pdf_url: string, prefix: string, primary_election: string, receipt_date: string, report: string, report_type: string, report_year: int, rpt_pgi: string, sign_date: string, state: string, street_1: string, street_2: string, subtotal_summary_period: string, suffix: string, summary_lines: string, treasurer_first_name: string, treasurer_last_name: string, treasurer_middle_name: string, treasurer_name: string, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_number" $file_number "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "q_filer" $q_filer "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/efile/reports/presidential/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"file_number": $file_number, "sort_nulls_last": $sort_nulls_last, "page": $page, "per_page": $per_page, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "min_receipt_date": $min_receipt_date, "max_receipt_date": $max_receipt_date, "q_filer": $q_filer, "sort_null_only": $sort_null_only, "sort": $qp_sort} | compact), body: null}
}

# FEC election dates since 1995.
#
# GET /election-dates/
export def "election-dates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-update-date: string # The maximum date this record was last updated.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --max-primary-general-date: string # The maximum date of primary or general election.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --min-update-date: string # The minimum date this record was last updated.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --max-create-date: string # The maximum date this record was added to the system.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --min-election-date: string # The minimum date of election. (format: date)
  --election-party: list<string> # Party, if applicable.
  --election-type-id: list<string> # Election type id
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-create-date: string # The minimum date this record was added to the system.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --min-primary-general-date: string # The minimum date of primary or general election.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --election-year: list<string> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --election-district: list<string> # House district of the office sought, if applicable.
  --office-sought: list<string> # House, Senate or presidential office.
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --max-election-date: string # The maximum date of election. (format: date)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -election_date)
  --election-state: list<string> # State or territory of the office sought.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<active_election: bool, create_date: string, election_date: string, election_district: int, election_notes: string, election_party: string, election_state: string, election_type_full: string, election_type_id: string, election_year: int, office_sought: string, primary_general_date: string, update_date: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_update_date" $max_update_date "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "max_primary_general_date" $max_primary_general_date "scalar") (serialize-qp "min_update_date" $min_update_date "scalar") (serialize-qp "max_create_date" $max_create_date "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "min_election_date" $min_election_date "scalar") (serialize-qp "election_party" $election_party "multi") (serialize-qp "election_type_id" $election_type_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "min_create_date" $min_create_date "scalar") (serialize-qp "min_primary_general_date" $min_primary_general_date "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "election_district" $election_district "multi") (serialize-qp "office_sought" $office_sought "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "max_election_date" $max_election_date "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "election_state" $election_state "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/election-dates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_update_date": $max_update_date, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "max_primary_general_date": $max_primary_general_date, "min_update_date": $min_update_date, "max_create_date": $max_create_date, "per_page": $per_page, "min_election_date": $min_election_date, "election_party": $election_party, "election_type_id": $election_type_id, "page": $page, "min_create_date": $min_create_date, "min_primary_general_date": $min_primary_general_date, "election_year": $election_year, "api_key": $api_key, "election_district": $election_district, "office_sought": $office_sought, "sort_null_only": $sort_null_only, "max_election_date": $max_election_date, "sort": $qp_sort, "election_state": $election_state} | compact), body: null}
}

# An electioneering communication is any broadcast, cable or satellite communication that fulfills each of the following conditions: _The communication refers to a clearly identified federal candidate._ _The communication is publicly distributed by a television station, radio station, cable television system or satellite system for a fee._ _The communication is distributed within 60 days prior to a general election or 30 days prior to a primary election to federal office._
#
# GET /electioneering/
export def "electioneering get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --max-amount: string # Filter for all amounts less than a value.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --min-date: string # Minimum disbursement date (format: date)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-amount: string # Filter for all amounts greater than a value.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --description: string
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
  --report-year: list<int> # Forms with coverage date - year from the coverage ending date. Forms without coverage date - year from the receipt date.
  --last-index: int # Index of last result from previous page (format: int32)
  --max-date: string # Maximum disbursement date (format: date)
]: nothing -> record<pagination: record<count: int, last_indexes: string, pages: int, per_page: int>, results: table<amendment_indicator: string, beginning_image_number: string, calculated_candidate_share: float, candidate_district: string, candidate_id: string, candidate_name: string, candidate_office: string, candidate_state: string, committee_id: string, committee_name: string, communication_date: string, disbursement_amount: float, disbursement_date: string, election_type: string, file_number: int, link_id: int, number_of_candidates: float, payee_name: string, payee_state: string, pdf_url: string, public_distribution_date: string, purpose_description: string, receipt_date: string, report_year: int, sb_image_num: string, sb_link_id: string, sub_id: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "report_year" $report_year "multi") (serialize-qp "last_index" $last_index "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/electioneering/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "max_amount": $max_amount, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "min_date": $min_date, "api_key": $api_key, "min_amount": $min_amount, "per_page": $per_page, "sort_null_only": $sort_null_only, "description": $description, "sort": $qp_sort, "report_year": $report_year, "last_index": $last_index, "max_date": $max_date} | compact), body: null}
}

# Electioneering communications costs aggregates
#
# GET /electioneering/aggregates/
export def "electioneering-aggregates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate: string, candidate_id: string, candidate_name: string, committee: string, committee_id: string, committee_name: string, count: int, cycle: int, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/electioneering/aggregates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "page": $page, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Electioneering costs aggregated by candidate
#
# GET /electioneering/by_candidate/
export def "electioneering-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: string@office-completer-1 # Federal office candidate runs for: H, S or P
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --district: string # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --state: string # US state or territory where a candidate runs for office
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate: string, candidate_id: string, candidate_name: string, committee: string, committee_id: string, committee_name: string, count: int, cycle: int, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/electioneering/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "candidate_id": $candidate_id, "cycle": $cycle, "district": $district, "state": $state, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Total electioneering communications spent on candidates by cycle or candidate election year
#
# GET /electioneering/totals/by_candidate/
export def "electioneering-totals-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, cycle: int, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/electioneering/totals/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "page": $page, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Look at the top-level financial information for all candidates running for the same office. Choose a 2-year cycle, and `house`, `senate` or `presidential`. If you are looking for a Senate seat, you will need to select the state using a two-letter abbreviation. House races require state and a two-digit district number. Since this endpoint reflects financial information, it will only have candidates once they file financial reporting forms. Query the `/candidates` endpoint to retrieve an-up-to-date list of all the candidates that filed to run for a particular seat.
#
# GET /elections/
export def "elections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: string@office-completer-1 # Federal office candidate runs for: H, S or P
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --district: string # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --state: string # US state or territory where a candidate runs for office
  --cycle: int # Two-year election cycle in which a candidate runs for office. Calculated from Form 2. The cycle begins with an odd year and is named for its ending, even year. This cycle follows the traditional house election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. To retrieve data for the entire four years of a presidential term or six years of a senatorial term, you will need the `election_full` flag. (format: int32)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -total_receipts)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_election_year: int, candidate_id: string, candidate_name: string, candidate_pcc_id: string, candidate_pcc_name: string, cash_on_hand_end_period: float, committee_ids: list, coverage_end_date: string, incumbent_challenge_full: string, party_full: string, total_disbursements: float, total_receipts: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "district" $district "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "cycle" $cycle "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/elections/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "page": $page, "district": $district, "state": $state, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# List elections by cycle, office, state, and district.
#
# GET /elections/search/
export def "elections-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string>
  --cycle: list<int> # Two-year election cycle in which a candidate runs for office. Calculated from Form 2. The cycle begins with an odd year and is named for its ending, even year. This cycle follows the traditional house election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. To retrieve data for the entire four years of a presidential term or six years of a senatorial term, you will need the `election_full` flag.
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --zip: list<int> # Zip code
  --state: list<string> # US state or territory where a candidate runs for office
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [sort_order, district])
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<cycle: int, district: string, office: string, state: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "multi") (serialize-qp "zip" $zip "multi") (serialize-qp "state" $state "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/elections/search/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "cycle": $cycle, "district": $district, "zip": $zip, "state": $state, "sort_hide_null": $sort_hide_null, "sort_nulls_last": $sort_nulls_last, "page": $page, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# List elections by cycle, office, state, and district.
#
# GET /elections/summary/
export def "elections-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: string@office-completer-1 # Federal office candidate runs for: H, S or P
  --cycle: int # Two-year election cycle in which a candidate runs for office. Calculated from Form 2. The cycle begins with an odd year and is named for its ending, even year. This cycle follows the traditional house election cycle and subdivides the presidential and Senate elections into comparable two-year blocks. To retrieve data for the entire four years of a presidential term or six years of a senatorial term, you will need the `election_full` flag. (format: int32)
  --district: string # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --state: string # US state or territory where a candidate runs for office
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
]: nothing -> record<count: int, disbursements: float, independent_expenditures: float, receipts: float> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "scalar") (serialize-qp "cycle" $cycle "scalar") (serialize-qp "district" $district "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "election_full" $election_full "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/elections/summary/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "cycle": $cycle, "district": $district, "state": $state, "api_key": $api_key, "election_full": $election_full} | compact), body: null}
}

# All official records and reports filed by or delivered to the FEC. Note: because the filings data includes many records, counts for large result sets are approximate; you will want to page through the records until no records are returned.
#
# GET /filings/
export def "filings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: list<string> # Federal office candidate runs for: H, S or P
  --file-number: list<int> # Filing ID number
  --form-category: list<string> # The forms filed are categorized based on the nature of the filing: - REPORT F3, F3X, F3P, F3L, F4, F5, F7, F13 - NOTICE F5, F24, F6, F9, F10, F11 - STATEMENT F1, F2 - OTHER F1M, F8, F99, F12, FRQ
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --document-type: list<string> # The type of document for documents other than reports: - 2 24 Hour Contribution Notice - 4 48 Hour Contribution Notice - A Debt Settlement Statement - B Acknowledgment of Receipt of Debt Settlement Statement - C RFAI: Debt Settlement First Notice - D Commission Debt Settlement Review - E Commission Response TO Debt Settlement Request - F Administrative Termination - G Debt Settlement Plan Amendment - H Disavowal Notice - I Disavowal Response - J Conduit Report - K Termination Approval - L Repeat Non-Filer Notice - M Filing Frequency Change Notice - N Paper Amendment to Electronic Report - O Acknowledgment of Filing Frequency Change - S RFAI: Debt Settlement Second - T Miscellaneous Report TO FEC - V Repeat Violation Notice (441A OR 441B) - P Notice of Paper Filing - R F3L Filing Frequency Change Notice - Q Acknowledgment of F3L Filing Frequency Change - U Unregistered Committee Notice
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --state: list<string> # US state or territory where a candidate runs for office
  --amendment-indicator: list<string> # Amendent types: -N new -A amendment -T terminated -C consolidated -M multi-candidate -S secondary NULL might be new or amendment. If amendment indicator is null and the filings is the first or first in a chain treat it as if it was a new. If it is not the first or first in a chain then treat the filing as an amendment.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --is-amended: oneof<nothing, bool> # False indicates that a report is the most recent. True indicates that the report has been superseded by an amendment.
  --filer-type: string@filer-type-completer # The method used to file with the FEC, either electronic or on paper.
  --max-receipt-date: string # Selects all filings received before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --primary-general-indicator: list<string> # Primary, general or special election indicator.
  --request-type: list<string> # Requests for additional information (RFAIs) sent to filers. The request type is based on the type of document filed: - 1 Statement of Organization - 2 Report of Receipts and Expenditures (Form 3 and 3X) - 3 Second Notice - Reports - 4 Request for Additional Information - 5 Informational - Reports - 6 Second Notice - Statement of Organization - 7 Failure to File - 8 From Public Disclosure - 9 From Multi Candidate Status
  --report-year: list<int> # Forms with coverage date - year from the coverage ending date. Forms without coverage date - year from the receipt date.
  --form-type: list<string> # The form where the underlying data comes from, for example, Form 1 would appear as F1: - F1 Statement of Organization - F1M Notification of Multicandidate Status - F2 Statement of Candidacy - F3 Report of Receipts and Disbursements for an Authorized Committee - F3P Report of Receipts and Disbursements by an Authorized Committee of a Candidate for The Office of President or Vice President - F3L Report of Contributions Bundled by Lobbyists/Registrants and Lobbyist/Registrant PACs - F3X Report of Receipts and Disbursements for other than an Authorized Committee - F4 Report of Receipts and Disbursements for a Committee or Organization Supporting a Nomination Convention - F5 Report of Independent Expenditures Made and Contributions Received - F6 48 Hour Notice of Contributions/Loans Received - F7 Report of Communication Costs by Corporations and Membership Organizations - F8 Debt Settlement Plan - F9 24 Hour Notice of Disbursements for Electioneering Communications - F13 Report of Donations Accepted for Inaugural Committee - F99 Miscellaneous Text - FRQ Request for Additional Information
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --committee-type: string # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --beginning-image-number: list<string> # Unique identifier for the electronic or paper report. This number is used to construct PDF URLs to the original document.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [-receipt_date])
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-receipt-date: string # Selects all filings received after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --q-filer: list<string> # Keyword search for filer name or ID
  --report-type: list<string> # Name of report where the underlying data comes from: - 10D Pre-Election - 10G Pre-General - 10P Pre-Primary - 10R Pre-Run-Off - 10S Pre-Special - 12C Pre-Convention - 12G Pre-General - 12P Pre-Primary - 12R Pre-Run-Off - 12S Pre-Special - 30D Post-Election - 30G Post-General - 30P Post-Primary - 30R Post-Run-Off - 30S Post-Special - 60D Post-Convention - M1 January Monthly - M10 October Monthly - M11 November Monthly - M12 December Monthly - M2 February Monthly - M3 March Monthly - M4 April Monthly - M5 May Monthly - M6 June Monthly - M7 July Monthly - M8 August Monthly - M9 September Monthly - MY Mid-Year Report - Q1 April Quarterly - Q2 July Quarterly - Q3 October Quarterly - TER Termination Report - YE Year-End - ADJ COMP ADJUST AMEND - CA COMPREHENSIVE AMEND - 90S Post Inaugural Supplement - 90D Post Inaugural - 48 48 Hour Notification - 24 24 Hour Notification - M7S July Monthly/Semi-Annual - MSA Monthly Semi-Annual (MY) - MYS Monthly Year End/Semi-Annual - Q2S July Quarterly/Semi-Annual - QSA Quarterly Semi-Annual (MY) - QYS Quarterly Year End/Semi-Annual - QYE Quarterly Semi-Annual (YE) - QMS Quarterly Mid-Year/ Semi-Annual - MSY Monthly Semi-Annual (YE)
  --party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
  --most-recent: oneof<nothing, bool> # Report is either new or is the most-recently filed amendment
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<additional_bank_names: list, amendment_chain: list, amendment_indicator: string, amendment_version: int, bank_depository_city: string, bank_depository_name: string, bank_depository_state: string, bank_depository_street_1: string, bank_depository_street_2: string, bank_depository_zip: string, beginning_image_number: string, candidate_id: string, candidate_name: string, cash_on_hand_beginning_period: float, cash_on_hand_end_period: float, committee_id: string, committee_name: string, committee_type: string, coverage_end_date: string, coverage_start_date: string, csv_url: string, cycle: int, debts_owed_by_committee: float, debts_owed_to_committee: float, document_description: string, document_type: string, document_type_full: string, election_year: int, ending_image_number: string, fec_file_id: string, fec_url: string, file_number: int, form_category: string, form_type: string, house_personal_funds: float, html_url: string, is_amended: bool, means_filed: string, most_recent: bool, most_recent_file_number: int, net_donations: float, office: string, opposition_personal_funds: float, pages: int, party: string, pdf_url: string, previous_file_number: int, primary_general_indicator: string, receipt_date: string, report_type: string, report_type_full: string, report_year: int, request_type: string, senate_personal_funds: float, state: string, sub_id: string, total_communication_cost: float, total_disbursements: float, total_independent_expenditures: float, total_individual_contributions: float, total_receipts: float, treasurer_name: string, update_date: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "multi") (serialize-qp "file_number" $file_number "multi") (serialize-qp "form_category" $form_category "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "multi") (serialize-qp "document_type" $document_type "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "state" $state "multi") (serialize-qp "amendment_indicator" $amendment_indicator "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "is_amended" $is_amended "scalar") (serialize-qp "filer_type" $filer_type "scalar") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "primary_general_indicator" $primary_general_indicator "multi") (serialize-qp "request_type" $request_type "multi") (serialize-qp "report_year" $report_year "multi") (serialize-qp "form_type" $form_type "multi") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "committee_type" $committee_type "scalar") (serialize-qp "beginning_image_number" $beginning_image_number "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "q_filer" $q_filer "multi") (serialize-qp "report_type" $report_type "multi") (serialize-qp "party" $party "multi") (serialize-qp "most_recent" $most_recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/filings/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "file_number": $file_number, "form_category": $form_category, "cycle": $cycle, "district": $district, "document_type": $document_type, "sort_hide_null": $sort_hide_null, "state": $state, "amendment_indicator": $amendment_indicator, "sort_nulls_last": $sort_nulls_last, "is_amended": $is_amended, "filer_type": $filer_type, "max_receipt_date": $max_receipt_date, "per_page": $per_page, "primary_general_indicator": $primary_general_indicator, "request_type": $request_type, "report_year": $report_year, "form_type": $form_type, "candidate_id": $candidate_id, "committee_type": $committee_type, "beginning_image_number": $beginning_image_number, "page": $page, "sort": $qp_sort, "committee_id": $committee_id, "api_key": $api_key, "min_receipt_date": $min_receipt_date, "sort_null_only": $sort_null_only, "q_filer": $q_filer, "report_type": $report_type, "party": $party, "most_recent": $most_recent} | compact), body: null}
}

# Search legal documents by document type, or across all document types using keywords, parameter values and ranges.
#
# GET /legal/search/
export def "legal-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hits-returned: int # Number of results to return (max 10) (format: int32)
  --af-report-year: string # Admin fine report year
  --case-max-open-date: string # The latest date opened of case (format: date)
  --ao-max-issue-date: string # Latest issue date of advisory opinion (format: date)
  --case-statutory-citation: list<string> # Statutory citations
  --case-respondents: string # Cases respondents
  --q: string # Text to search legal documents for
  --ao-min-issue-date: string # Earliest issue date of advisory opinion (format: date)
  --af-max-fd-date: string # The latest Final Determination date (format: date)
  --from-hit: int # Get results starting from this index (format: int32)
  --af-fd-fine-amount: int # Final Determination fine amount (format: int32)
  --type: string # Legal Document type to refine search by - statutes - regulations - advisory_opinions - murs - admin_fines
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --af-name: list<string> # Admin fine committee name
  --ao-requestor-type: list<int> # Code of the advisory opinion requestor type.
  --ao-statutory-citation: list<string> # Statutory citations
  --ao-entity-name: list<string> # Name of commenter or representative
  --mur-type: string # Type of MUR : current or archived
  --ao-regulatory-citation: list<string> # Regulatory citations
  --af-committee-id: string # Admin fine committee ID
  --ao-requestor: string # The requestor of the advisory opinion
  --case-citation-require-all: oneof<nothing, bool> # Require all citations to be in document (default behavior is any)
  --af-min-fd-date: string # The earliest Final Determination date (format: date)
  --ao-is-pending: oneof<nothing, bool> # AO is pending
  --af-rtb-fine-amount: int # Reason to Believe fine amount (format: int32)
  --case-election-cycles: int # Cases election cycles (format: int32)
  --ao-category: list<string> # Category of the document
  --ao-citation-require-all: oneof<nothing, bool> # Require all citations to be in document (default behavior is any)
  --case-dispositions: list<string> # Cases dispositions
  --af-max-rtb-date: string # The latest Reason to Believe date (format: date)
  --case-min-open-date: string # The earliest date opened of case (format: date)
  --case-max-close-date: string # The latest date closed of case (format: date)
  --ao-min-request-date: string # Earliest request date of advisory opinion (format: date)
  --ao-status: string # Status of AO (pending, withdrawn, or final)
  --case-doc-category-id: list<string> # Select one or more case_doc_category_id to filter by corresponding CASE_DOCUMENT_CATEGORY: - 1 - Conciliation Agreements - 2 - Complaint, Responses, Designation of Counsel and Extensions of Timee - 3 - General Counsel Reports, Briefs, Notifications and Responses - 4 - Certifications - 5 - Civil Penalties, Disgorgements and Other Payments - 6 - Statements of Reasons
  --af-min-rtb-date: string # The earliest Reason to Believe date (format: date)
  --ao-name: list<string> # Force advisory opinion name
  --case-regulatory-citation: list<string> # Regulatory citations
  --ao-no: list<string> # Force advisory opinion number
  --case-min-close-date: string # The earliest date closed of case (format: date)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. ex: `-case_no`
  --ao-max-request-date: string # Latest request date of advisory opinion (format: date)
  --case-no: list<string> # Enforcement matter case number
]: nothing -> record<admin_fines: table<challenge_outcome: string, challenge_receipt_date: string, check_amount: float, commission_votes: list, committee_id: string, doc_id: string, document_highlights: record, documents: list, final_determination_amount: float, final_determination_date: string, highlights: list, name: string, no: string, petition_court_decision_date: string, petition_court_filing_date: string, reason_to_believe_action_date: string, reason_to_believe_fine_amount: float, report_type: string, report_year: string, treasury_referral_amount: float, treasury_referral_date: string, url: string>, adrs: table<close_date: string, commission_votes: list, dispositions: list, doc_id: string, document_highlights: record, documents: list, election_cycles: int, highlights: list, name: string, no: string, open_date: string, participants: list, respondents: list, subjects: list, url: string>, advisory_opinions: table<ao_citations: list, aos_cited_by: list, commenter_names: list, document_highlights: record, documents: list, entities: list, highlights: list, is_pending: bool, issue_date: string, name: string, no: string, regulatory_citations: list, representative_names: list, request_date: string, requestor_names: list, requestor_types: list, status: string, statutory_citations: list, summary: string>, murs: table<close_date: string, commission_votes: list, dispositions: list, doc_id: string, document_highlights: record, documents: list, election_cycles: int, highlights: list, mur_type: string, name: string, no: string, open_date: string, participants: list, respondents: list, subjects: list, url: string>, regulations: table<doc_id: string, document_highlights: record, highlights: list, name: string, no: string, url: string>, statutes: table<chapter: string, doc_id: string, document_highlights: record, highlights: list, name: string, no: string, title: string, url: string>, total_admin_fines: int, total_adrs: int, total_advisory_opinions: int, total_all: int, total_murs: int, total_regulations: int, total_statutes: int> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hits_returned" $hits_returned "scalar") (serialize-qp "af_report_year" $af_report_year "scalar") (serialize-qp "case_max_open_date" $case_max_open_date "scalar") (serialize-qp "ao_max_issue_date" $ao_max_issue_date "scalar") (serialize-qp "case_statutory_citation" $case_statutory_citation "multi") (serialize-qp "case_respondents" $case_respondents "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "ao_min_issue_date" $ao_min_issue_date "scalar") (serialize-qp "af_max_fd_date" $af_max_fd_date "scalar") (serialize-qp "from_hit" $from_hit "scalar") (serialize-qp "af_fd_fine_amount" $af_fd_fine_amount "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "af_name" $af_name "multi") (serialize-qp "ao_requestor_type" $ao_requestor_type "multi") (serialize-qp "ao_statutory_citation" $ao_statutory_citation "multi") (serialize-qp "ao_entity_name" $ao_entity_name "multi") (serialize-qp "mur_type" $mur_type "scalar") (serialize-qp "ao_regulatory_citation" $ao_regulatory_citation "multi") (serialize-qp "af_committee_id" $af_committee_id "scalar") (serialize-qp "ao_requestor" $ao_requestor "scalar") (serialize-qp "case_citation_require_all" $case_citation_require_all "scalar") (serialize-qp "af_min_fd_date" $af_min_fd_date "scalar") (serialize-qp "ao_is_pending" $ao_is_pending "scalar") (serialize-qp "af_rtb_fine_amount" $af_rtb_fine_amount "scalar") (serialize-qp "case_election_cycles" $case_election_cycles "scalar") (serialize-qp "ao_category" $ao_category "multi") (serialize-qp "ao_citation_require_all" $ao_citation_require_all "scalar") (serialize-qp "case_dispositions" $case_dispositions "multi") (serialize-qp "af_max_rtb_date" $af_max_rtb_date "scalar") (serialize-qp "case_min_open_date" $case_min_open_date "scalar") (serialize-qp "case_max_close_date" $case_max_close_date "scalar") (serialize-qp "ao_min_request_date" $ao_min_request_date "scalar") (serialize-qp "ao_status" $ao_status "scalar") (serialize-qp "case_doc_category_id" $case_doc_category_id "multi") (serialize-qp "af_min_rtb_date" $af_min_rtb_date "scalar") (serialize-qp "ao_name" $ao_name "multi") (serialize-qp "case_regulatory_citation" $case_regulatory_citation "multi") (serialize-qp "ao_no" $ao_no "multi") (serialize-qp "case_min_close_date" $case_min_close_date "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "ao_max_request_date" $ao_max_request_date "scalar") (serialize-qp "case_no" $case_no "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/legal/search/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hits_returned": $hits_returned, "af_report_year": $af_report_year, "case_max_open_date": $case_max_open_date, "ao_max_issue_date": $ao_max_issue_date, "case_statutory_citation": $case_statutory_citation, "case_respondents": $case_respondents, "q": $q, "ao_min_issue_date": $ao_min_issue_date, "af_max_fd_date": $af_max_fd_date, "from_hit": $from_hit, "af_fd_fine_amount": $af_fd_fine_amount, "type": $type, "api_key": $api_key, "af_name": $af_name, "ao_requestor_type": $ao_requestor_type, "ao_statutory_citation": $ao_statutory_citation, "ao_entity_name": $ao_entity_name, "mur_type": $mur_type, "ao_regulatory_citation": $ao_regulatory_citation, "af_committee_id": $af_committee_id, "ao_requestor": $ao_requestor, "case_citation_require_all": $case_citation_require_all, "af_min_fd_date": $af_min_fd_date, "ao_is_pending": $ao_is_pending, "af_rtb_fine_amount": $af_rtb_fine_amount, "case_election_cycles": $case_election_cycles, "ao_category": $ao_category, "ao_citation_require_all": $ao_citation_require_all, "case_dispositions": $case_dispositions, "af_max_rtb_date": $af_max_rtb_date, "case_min_open_date": $case_min_open_date, "case_max_close_date": $case_max_close_date, "ao_min_request_date": $ao_min_request_date, "ao_status": $ao_status, "case_doc_category_id": $case_doc_category_id, "af_min_rtb_date": $af_min_rtb_date, "ao_name": $ao_name, "case_regulatory_citation": $case_regulatory_citation, "ao_no": $ao_no, "case_min_close_date": $case_min_close_date, "sort": $qp_sort, "ao_max_request_date": $ao_max_request_date, "case_no": $case_no} | compact), body: null}
}

# Search for candidates or committees by name. If you're looking for information on a particular person or group, using a name to find the `candidate_id` or `committee_id` on this endpoint can be a helpful first step.
#
# GET /names/audit_candidates/
export def "names-audit-candidates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --q: list<string> # Name (candidate or committee) to search for
]: nothing -> record<results: table<id: string, name: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "q" $q "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/names/audit_candidates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "q": $q} | compact), body: null}
}

# Search for candidates or committees by name. If you're looking for information on a particular person or group, using a name to find the `candidate_id` or `committee_id` on this endpoint can be a helpful first step.
#
# GET /names/audit_committees/
export def "names-audit-committees get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --q: list<string> # Name (candidate or committee) to search for
]: nothing -> record<results: table<id: string, name: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "q" $q "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/names/audit_committees/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "q": $q} | compact), body: null}
}

# Search for candidates or committees by name. If you're looking for information on a particular person or group, using a name to find the `candidate_id` or `committee_id` on this endpoint can be a helpful first step.
#
# GET /names/candidates/
export def "names-candidates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --q: list<string> # Name (candidate or committee) to search for
]: nothing -> record<results: table<id: string, name: string, office_sought: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "q" $q "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/names/candidates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "q": $q} | compact), body: null}
}

# Search for candidates or committees by name. If you're looking for information on a particular person or group, using a name to find the `candidate_id` or `committee_id` on this endpoint can be a helpful first step.
#
# GET /names/committees/
export def "names-committees get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --q: list<string> # Name (candidate or committee) to search for
]: nothing -> record<results: table<id: string, is_active: bool, name: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "q" $q "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/names/committees/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api_key": $api_key, "q": $q} | compact), body: null}
}

# The Operations log contains details of each report loaded into the database. It is primarily used as status check to determine when all of the data processes, from initial entry through review are complete.
#
# GET /operations-log/
export def "operations-log get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-coverage-end-date: string # Ending date of the reporting period before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --amendment-indicator: list<string> # Amendent types: -N new -A amendment -T terminated -C consolidated -M multi-candidate -S secondary NULL might be new or amendment. If amendment indicator is null and the filings is the first or first in a chain treat it as if it was a new. If it is not the first or first in a chain then treat the filing as an amendment.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --max-receipt-date: string # Selects all filings received before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --min-transaction-data-complete-date: string # Select all filings processed completely after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --form-type: list<string> # The form where the underlying data comes from, for example, Form 1 would appear as F1: - F1 Statement of Organization - F1M Notification of Multicandidate Status - F2 Statement of Candidacy - F3 Report of Receipts and Disbursements for an Authorized Committee - F3P Report of Receipts and Disbursements by an Authorized Committee of a Candidate for The Office of President or Vice President - F3L Report of Contributions Bundled by Lobbyists/Registrants and Lobbyist/Registrant PACs - F3X Report of Receipts and Disbursements for other than an Authorized Committee - F4 Report of Receipts and Disbursements for a Committee or Organization Supporting a Nomination Convention - F5 Report of Independent Expenditures Made and Contributions Received - F6 48 Hour Notice of Contributions/Loans Received - F7 Report of Communication Costs by Corporations and Membership Organizations - F8 Debt Settlement Plan - F9 24 Hour Notice of Disbursements for Electioneering Communications - F13 Report of Donations Accepted for Inaugural Committee - F99 Miscellaneous Text - FRQ Request for Additional Information
  --max-transaction-data-complete-date: string # Select all filings processed completely before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --beginning-image-number: list<string> # Unique identifier for the electronic or paper report. This number is used to construct PDF URLs to the original document.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-coverage-end-date: string # Ending date of the reporting period after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [-report_year])
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-receipt-date: string # Selects all filings received after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --candidate-committee-id: list<string> # A unique identifier of the registered filer.
  --report-type: list<string> # Name of report where the underlying data comes from: - 10D Pre-Election - 10G Pre-General - 10P Pre-Primary - 10R Pre-Run-Off - 10S Pre-Special - 12C Pre-Convention - 12G Pre-General - 12P Pre-Primary - 12R Pre-Run-Off - 12S Pre-Special - 30D Post-Election - 30G Post-General - 30P Post-Primary - 30R Post-Run-Off - 30S Post-Special - 60D Post-Convention - M1 January Monthly - M10 October Monthly - M11 November Monthly - M12 December Monthly - M2 February Monthly - M3 March Monthly - M4 April Monthly - M5 May Monthly - M6 June Monthly - M7 July Monthly - M8 August Monthly - M9 September Monthly - MY Mid-Year Report - Q1 April Quarterly - Q2 July Quarterly - Q3 October Quarterly - TER Termination Report - YE Year-End - ADJ COMP ADJUST AMEND - CA COMPREHENSIVE AMEND - 90S Post Inaugural Supplement - 90D Post Inaugural - 48 48 Hour Notification - 24 24 Hour Notification - M7S July Monthly/Semi-Annual - MSA Monthly Semi-Annual (MY) - MYS Monthly Year End/Semi-Annual - Q2S July Quarterly/Semi-Annual - QSA Quarterly Semi-Annual (MY) - QYS Quarterly Year End/Semi-Annual - QYE Quarterly Semi-Annual (YE) - QMS Quarterly Mid-Year/ Semi-Annual - MSY Monthly Semi-Annual (YE)
  --report-year: list<int> # Forms with coverage date - year from the coverage ending date. Forms without coverage date - year from the receipt date.
  --status-num: list<string> # Status of the transactional report. -0- Transaction is entered into the system. But not verified. -1- Transaction is verified.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<amendment_indicator: string, beginning_image_number: string, candidate_committee_id: string, coverage_end_date: string, coverage_start_date: string, ending_image_number: string, form_type: string, receipt_date: string, report_type: string, report_year: int, status_num: int, sub_id: int, summary_data_complete_date: string, summary_data_verification_date: string, transaction_data_complete_date: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_coverage_end_date" $max_coverage_end_date "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "amendment_indicator" $amendment_indicator "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "min_transaction_data_complete_date" $min_transaction_data_complete_date "scalar") (serialize-qp "form_type" $form_type "multi") (serialize-qp "max_transaction_data_complete_date" $max_transaction_data_complete_date "scalar") (serialize-qp "beginning_image_number" $beginning_image_number "multi") (serialize-qp "page" $page "scalar") (serialize-qp "min_coverage_end_date" $min_coverage_end_date "scalar") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "candidate_committee_id" $candidate_committee_id "multi") (serialize-qp "report_type" $report_type "multi") (serialize-qp "report_year" $report_year "multi") (serialize-qp "status_num" $status_num "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/operations-log/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_coverage_end_date": $max_coverage_end_date, "sort_nulls_last": $sort_nulls_last, "amendment_indicator": $amendment_indicator, "sort_hide_null": $sort_hide_null, "max_receipt_date": $max_receipt_date, "per_page": $per_page, "min_transaction_data_complete_date": $min_transaction_data_complete_date, "form_type": $form_type, "max_transaction_data_complete_date": $max_transaction_data_complete_date, "beginning_image_number": $beginning_image_number, "page": $page, "min_coverage_end_date": $min_coverage_end_date, "sort": $qp_sort, "api_key": $api_key, "min_receipt_date": $min_receipt_date, "sort_null_only": $sort_null_only, "candidate_committee_id": $candidate_committee_id, "report_type": $report_type, "report_year": $report_year, "status_num": $status_num} | compact), body: null}
}

# Net receipts per candidate. Filter with `contributor_state='US'` for national totals
#
# GET /presidential/contributions/by_candidate/
export def "presidential-contributions-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contributor-state: list<string> # State of contributor
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -net_receipts)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, candidate_last_name: string, candidate_party_affiliation: string, contributor_state: string, election_year: int, net_receipts: float, rounded_net_receipts: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contributor_state" $contributor_state "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/presidential/contributions/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"contributor_state": $contributor_state, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_year": $election_year, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Contribution receipts by size per candidate. Filter by candidate_id, election_year and/or size
#
# GET /presidential/contributions/by_size/
export def "presidential-contributions-by-size get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office. -P00000001 All candidates -P00000002 Democrasts -P00000003 Republicans
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --size: list<int> # The total all contributions in the following ranges: ``` -0 $200 and under -200 $200.01 - $499.99 -500 $500 - $999.99 -1000 $1000 - $1999.99 -2000 $2000 + ``` Unitemized contributions are included in the `0` category.
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: size)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, contribution_receipt_amount: float, election_year: int, size: int, size_range_id: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "size" $size "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/presidential/contributions/by_size/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_year": $election_year, "api_key": $api_key, "size": $size, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Contribution receipts by state per candidate. Filter by candidate_id and/or election_year
#
# GET /presidential/contributions/by_state/
export def "presidential-contributions-by-state get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office. -P00000001 All candidates -P00000002 Democrasts -P00000003 Republicans
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -contribution_receipt_amount)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, contribution_receipt_amount: float, contribution_state: string, election_year: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/presidential/contributions/by_state/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_year": $election_year, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Coverage end date per candidate. Filter by candidate_id and/or election_year
#
# GET /presidential/coverage_end_date/
export def "presidential-coverage-end-date get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office. -P00000001 All candidates -P00000002 Democrasts -P00000003 Republicans
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: candidate_id)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, coverage_end_date: string, election_year: int>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/presidential/coverage_end_date/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_year": $election_year, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Financial summary per candidate. Filter by candidate_id and/or election_year
#
# GET /presidential/financial_summary/
export def "presidential-financial-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office. -P00000001 All candidates -P00000002 Democrasts -P00000003 Republicans
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-year: list<int> # Year of election
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -net_receipts)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_contributions_less_repayments: float, candidate_id: string, candidate_last_name: string, candidate_name: string, candidate_party_affiliation: string, cash_on_hand_end: float, committee_designation: string, committee_id: string, committee_name: string, committee_type: string, debts_owed_by_committee: float, disbursements_less_offsets: float, election_year: int, exempt_legal_accounting_disbursement: float, federal_funds: float, fundraising_disbursements: float, individual_contributions_less_refunds: float, net_receipts: float, offsets_to_operating_expenditures: float, operating_expenditures: float, other_disbursements: float, pac_contributions_less_refunds: float, party_contributions_less_refunds: float, repayments_loans_made_by_candidate: float, repayments_other_loans: float, rounded_net_receipts: float, total_contribution_refunds: float, total_loan_repayments_made: float, transfers_from_affiliated_committees: float, transfers_to_other_authorized_committees: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_year" $election_year "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/presidential/financial_summary/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "page": $page, "sort_hide_null": $sort_hide_null, "election_year": $election_year, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Use this endpoint to look up the RAD Analyst for a committee. The mission of the Reports Analysis Division (RAD) is to ensure that campaigns and political committees file timely and accurate reports that fully disclose their financial activities. RAD is responsible for reviewing statements and financial reports filed by political committees participating in federal elections, providing assistance and guidance to the committees to properly file their reports, and for taking appropriate action to ensure compliance with the Federal Election Campaign Act (FECA).
#
# GET /rad-analyst/
export def "rad-analyst get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-assignment-update-date: string # Filter results for assignment updates made after this date (format: date)
  --max-assignment-update-date: string # Filter results for assignment updates made before this date (format: date)
  --analyst-short-id: list<int> # Short ID of RAD analyst
  --email: list<string> # Email of RAD analyst
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --title: list<string> # Title of RAD analyst
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --name: list<string> # Name of RAD analyst
  --telephone-ext: list<int> # Telephone extension of RAD analyst
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --analyst-id: list<int> # ID of RAD analyst
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<analyst_id: float, analyst_short_id: float, assignment_update_date: string, committee_id: string, committee_name: string, email: string, first_name: string, last_name: string, rad_branch: string, telephone_ext: float, title: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_assignment_update_date" $min_assignment_update_date "scalar") (serialize-qp "max_assignment_update_date" $max_assignment_update_date "scalar") (serialize-qp "analyst_short_id" $analyst_short_id "multi") (serialize-qp "email" $email "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "title" $title "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "name" $name "multi") (serialize-qp "telephone_ext" $telephone_ext "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "analyst_id" $analyst_id "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rad-analyst/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"min_assignment_update_date": $min_assignment_update_date, "max_assignment_update_date": $max_assignment_update_date, "analyst_short_id": $analyst_short_id, "email": $email, "page": $page, "sort_nulls_last": $sort_nulls_last, "title": $title, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "name": $name, "telephone_ext": $telephone_ext, "api_key": $api_key, "analyst_id": $analyst_id, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# FEC election dates since 1995.
#
# GET /reporting-dates/
export def "reporting-dates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-update-date: string # The maximum date this record was last updated.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --max-due-date: string # The maximum date the report is due.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --min-create-date: string # The minimum date this record was added to the system.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --min-due-date: string # The minimum date the report is due.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-update-date: string # The minimum date this record was last updated.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --max-create-date: string # The maximum date this record was added to the system.(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -due_date)
  --report-year: list<int> # Forms with coverage date - year from the coverage ending date. Forms without coverage date - year from the receipt date.
  --report-type: list<string> # Name of report where the underlying data comes from: - 10D Pre-Election - 10G Pre-General - 10P Pre-Primary - 10R Pre-Run-Off - 10S Pre-Special - 12C Pre-Convention - 12G Pre-General - 12P Pre-Primary - 12R Pre-Run-Off - 12S Pre-Special - 30D Post-Election - 30G Post-General - 30P Post-Primary - 30R Post-Run-Off - 30S Post-Special - 60D Post-Convention - M1 January Monthly - M10 October Monthly - M11 November Monthly - M12 December Monthly - M2 February Monthly - M3 March Monthly - M4 April Monthly - M5 May Monthly - M6 June Monthly - M7 July Monthly - M8 August Monthly - M9 September Monthly - MY Mid-Year Report - Q1 April Quarterly - Q2 July Quarterly - Q3 October Quarterly - TER Termination Report - YE Year-End - ADJ COMP ADJUST AMEND - CA COMPREHENSIVE AMEND - 90S Post Inaugural Supplement - 90D Post Inaugural - 48 48 Hour Notification - 24 24 Hour Notification - M7S July Monthly/Semi-Annual - MSA Monthly Semi-Annual (MY) - MYS Monthly Year End/Semi-Annual - Q2S July Quarterly/Semi-Annual - QSA Quarterly Semi-Annual (MY) - QYS Quarterly Year End/Semi-Annual - QYE Quarterly Semi-Annual (YE) - QMS Quarterly Mid-Year/ Semi-Annual - MSY Monthly Semi-Annual (YE)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<create_date: string, due_date: string, report_type: string, report_type_full: string, report_year: int, update_date: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_update_date" $max_update_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "max_due_date" $max_due_date "scalar") (serialize-qp "min_create_date" $min_create_date "scalar") (serialize-qp "min_due_date" $min_due_date "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_update_date" $min_update_date "scalar") (serialize-qp "max_create_date" $max_create_date "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "report_year" $report_year "multi") (serialize-qp "report_type" $report_type "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting-dates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_update_date": $max_update_date, "page": $page, "max_due_date": $max_due_date, "min_create_date": $min_create_date, "min_due_date": $min_due_date, "sort_hide_null": $sort_hide_null, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "min_update_date": $min_update_date, "max_create_date": $max_create_date, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort": $qp_sort, "report_year": $report_year, "report_type": $report_type} | compact), body: null}
}

# Each report represents the summary information from Form 3, Form 3X and Form 3P. These reports have key statistics that illuminate the financial status of a given committee. Things like cash on hand, debts owed by committee, total receipts, and total disbursements are especially helpful for understanding a committee's financial dealings. By default, this endpoint includes both amended and final versions of each report. To restrict to only the final versions of each report, use `is_amended=false`; to retrieve only reports that have been amended, use `is_amended=true`. Several different reporting structures exist, depending on the type of organization that submits financial information. To see an example of these reporting requirements, look at the summary and detailed summary pages of Form 3, Form 3X, and Form 3P. DISCLAIMER: The field labels contained within this resource are subject to change. We are attempting to succinctly label these fields while conveying clear meaning to ensure accessibility for all users.
#
# GET /reports/{entity_type}/
export def "reports get" [
  entity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-debts-owed-amount: string # Filter for all amounts greater than a value.
  --max-debts-owed-expenditures: string # Filter for all amounts less than a value.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --year: list<int> # Forms with coverage date - year from the coverage ending date. Forms without coverage date - year from the receipt date.
  --max-cash-on-hand-end-period-amount: string # Filter for all amounts less than a value.
  --filer-type: string@filer-type-completer # The method used to file with the FEC, either electronic or on paper.
  --max-party-coordinated-expenditures: string # Filter for all amounts less than a value.
  --q-spender: list<string> # Keyword search for spender name or ID
  --max-receipt-date: string # Selects all items received by FEC before this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --max-independent-expenditures: string # Filter for all amounts less than a value.
  --min-party-coordinated-expenditures: string # Filter for all amounts greater than a value.
  --committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-total-contributions: string # Filter for all amounts greater than a value.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-cash-on-hand-end-period-amount: string # Filter for all amounts greater than a value.
  --min-receipt-date: string # Selects all items received by FEC after this date(MM/DD/YYYY or YYYY-MM-DD) (format: date)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --min-independent-expenditures: string # Filter for all amounts greater than a value.
  --q-filer: list<string> # Keyword search for filer name or ID
  --max-disbursements-amount: string # Filter for all amounts less than a value.
  --max-total-contributions: string # Filter for all amounts less than a value.
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --amendment-indicator: list<string> # Amendent types: -N new -A amendment -T terminated -C consolidated -M multi-candidate -S secondary NULL might be new or amendment. If amendment indicator is null and the filings is the first or first in a chain treat it as if it was a new. If it is not the first or first in a chain then treat the filing as an amendment.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --max-receipts-amount: string # Filter for all amounts less than a value.
  --is-amended: oneof<nothing, bool> # False indicates that a report is the most recent. True indicates that the report has been superseded by an amendment.
  --min-disbursements-amount: string # Filter for all amounts greater than a value.
  --min-receipts-amount: string # Filter for all amounts greater than a value.
  --candidate-id: string # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --beginning-image-number: list<string> # Unique identifier for the electronic or paper report. This number is used to construct PDF URLs to the original document.
  --qp-sort: list<string> # Provide a field to sort by. Use `-` for descending order. ex: `-case_no` (default: [-coverage_end_date])
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --report-type: list<string> # Report type; prefix with "-" to exclude. Name of report where the underlying data comes from: - 10D Pre-Election - 10G Pre-General - 10P Pre-Primary - 10R Pre-Run-Off - 10S Pre-Special - 12C Pre-Convention - 12G Pre-General - 12P Pre-Primary - 12R Pre-Run-Off - 12S Pre-Special - 30D Post-Election - 30G Post-General - 30P Post-Primary - 30R Post-Run-Off - 30S Post-Special - 60D Post-Convention - M1 January Monthly - M10 October Monthly - M11 November Monthly - M12 December Monthly - M2 February Monthly - M3 March Monthly - M4 April Monthly - M5 May Monthly - M6 June Monthly - M7 July Monthly - M8 August Monthly - M9 September Monthly - MY Mid-Year Report - Q1 April Quarterly - Q2 July Quarterly - Q3 October Quarterly - TER Termination Report - YE Year-End - ADJ COMP ADJUST AMEND - CA COMPREHENSIVE AMEND
  --most-recent: oneof<nothing, bool> # Report is either new or is the most-recently filed amendment
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<aggregate_amount_personal_contributions_general: float, aggregate_contributions_personal_funds_primary: float, all_loans_received_period: float, all_loans_received_ytd: float, all_other_loans_period: float, all_other_loans_ytd: float, allocated_federal_election_levin_share_period: float, amendment_chain: list, amendment_indicator: string, amendment_indicator_full: string, beginning_image_number: string, calendar_ytd: int, candidate_contribution_period: float, candidate_contribution_ytd: float, cash_on_hand_beginning_calendar_ytd: float, cash_on_hand_beginning_period: float, cash_on_hand_close_ytd: float, cash_on_hand_end_period: float, committee_id: string, committee_name: string, committee_type: string, coordinated_expenditures_by_party_committee_period: float, coordinated_expenditures_by_party_committee_ytd: float, coverage_end_date: string, coverage_start_date: string, csv_url: string, cycle: int, debts_owed_by_committee: float, debts_owed_to_committee: float, document_description: string, end_image_number: string, exempt_legal_accounting_disbursement_period: float, exempt_legal_accounting_disbursement_ytd: float, expenditure_subject_to_limits: float, fec_file_id: string, fec_url: string, fed_candidate_committee_contribution_refunds_ytd: float, fed_candidate_committee_contributions_period: float, fed_candidate_committee_contributions_ytd: float, fed_candidate_contribution_refunds_period: float, federal_funds_period: float, federal_funds_ytd: float, file_number: int, fundraising_disbursements_period: float, fundraising_disbursements_ytd: float, gross_receipt_authorized_committee_general: float, gross_receipt_authorized_committee_primary: float, gross_receipt_minus_personal_contribution_general: float, gross_receipt_minus_personal_contributions_primary: float, html_url: string, independent_contributions_period: float, independent_expenditures_period: float, independent_expenditures_ytd: float, individual_itemized_contributions_period: float, individual_itemized_contributions_ytd: float, individual_unitemized_contributions_period: float, individual_unitemized_contributions_ytd: float, is_amended: bool, items_on_hand_liquidated: float, loan_repayments_candidate_loans_period: float, loan_repayments_candidate_loans_ytd: float, loan_repayments_made_period: float, loan_repayments_made_ytd: float, loan_repayments_other_loans_period: float, loan_repayments_other_loans_ytd: float, loan_repayments_received_period: float, loan_repayments_received_ytd: float, loans_made_by_candidate_period: float, loans_made_by_candidate_ytd: float, loans_made_period: float, loans_made_ytd: float, loans_received_from_candidate_period: float, loans_received_from_candidate_ytd: float, means_filed: string, most_recent: bool, most_recent_file_number: float, net_contributions_cycle_to_date: float, net_contributions_period: float, net_contributions_ytd: float, net_operating_expenditures_cycle_to_date: float, net_operating_expenditures_period: float, net_operating_expenditures_ytd: float, non_allocated_fed_election_activity_period: float, non_allocated_fed_election_activity_ytd: float, nonfed_share_allocated_disbursements_period: float, offsets_to_fundraising_expenditures_period: float, offsets_to_fundraising_expenditures_ytd: float, offsets_to_legal_accounting_period: float, offsets_to_legal_accounting_ytd: float, offsets_to_operating_expenditures_period: float, offsets_to_operating_expenditures_ytd: float, operating_expenditures_period: float, operating_expenditures_ytd: float, other_disbursements_period: float, other_disbursements_ytd: float, other_fed_operating_expenditures_period: float, other_fed_operating_expenditures_ytd: float, other_fed_receipts_period: float, other_fed_receipts_ytd: float, other_loans_received_period: float, other_loans_received_ytd: float, other_political_committee_contributions_period: float, other_political_committee_contributions_ytd: float, other_receipts_period: float, other_receipts_ytd: float, pdf_url: string, political_party_committee_contributions_period: float, political_party_committee_contributions_ytd: float, previous_file_number: float, receipt_date: string, refunded_individual_contributions_period: float, refunded_individual_contributions_ytd: float, refunded_other_political_committee_contributions_period: float, refunded_other_political_committee_contributions_ytd: float, refunded_political_party_committee_contributions_period: float, refunded_political_party_committee_contributions_ytd: float, refunds_total_contributions_col_total_ytd: float, repayments_loans_made_by_candidate_period: float, repayments_loans_made_candidate_ytd: float, repayments_other_loans_period: float, repayments_other_loans_ytd: float, report_form: string, report_type: string, report_type_full: string, report_year: int, shared_fed_activity_nonfed_ytd: float, shared_fed_activity_period: float, shared_fed_activity_ytd: float, shared_fed_operating_expenditures_period: float, shared_fed_operating_expenditures_ytd: float, shared_nonfed_operating_expenditures_period: float, shared_nonfed_operating_expenditures_ytd: float, subtotal_period: float, subtotal_summary_page_period: float, subtotal_summary_period: float, subtotal_summary_ytd: float, total_contribution_refunds_col_total_period: float, total_contribution_refunds_period: float, total_contribution_refunds_ytd: float, total_contributions_column_total_period: float, total_contributions_period: float, total_contributions_ytd: float, total_disbursements_period: float, total_disbursements_ytd: float, total_fed_disbursements_period: float, total_fed_disbursements_ytd: float, total_fed_election_activity_period: float, total_fed_election_activity_ytd: float, total_fed_operating_expenditures_period: float, total_fed_operating_expenditures_ytd: float, total_fed_receipts_period: float, total_fed_receipts_ytd: float, total_individual_contributions_period: float, total_individual_contributions_ytd: float, total_loan_repayments_made_period: float, total_loan_repayments_made_ytd: float, total_loans_received_period: float, total_loans_received_ytd: float, total_nonfed_transfers_period: float, total_nonfed_transfers_ytd: float, total_offsets_to_operating_expenditures_period: float, total_offsets_to_operating_expenditures_ytd: float, total_operating_expenditures_period: float, total_operating_expenditures_ytd: float, total_period: float, total_receipts_period: float, total_receipts_ytd: float, total_ytd: float, transfers_from_affiliated_committee_period: float, transfers_from_affiliated_committee_ytd: float, transfers_from_affiliated_party_period: float, transfers_from_affiliated_party_ytd: float, transfers_from_nonfed_account_period: float, transfers_from_nonfed_account_ytd: float, transfers_from_nonfed_levin_period: float, transfers_from_nonfed_levin_ytd: float, transfers_from_other_authorized_committee_period: float, transfers_from_other_authorized_committee_ytd: float, transfers_to_affiliated_committee_period: float, transfers_to_affilitated_committees_ytd: float, transfers_to_other_authorized_committee_period: float, transfers_to_other_authorized_committee_ytd: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($entity_type | is-empty) { error make --unspanned { msg: "path parameter 'entity_type' must be non-empty" } }
  let qp = [(serialize-qp "min_debts_owed_amount" $min_debts_owed_amount "scalar") (serialize-qp "max_debts_owed_expenditures" $max_debts_owed_expenditures "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "year" $year "multi") (serialize-qp "max_cash_on_hand_end_period_amount" $max_cash_on_hand_end_period_amount "scalar") (serialize-qp "filer_type" $filer_type "scalar") (serialize-qp "max_party_coordinated_expenditures" $max_party_coordinated_expenditures "scalar") (serialize-qp "q_spender" $q_spender "multi") (serialize-qp "max_receipt_date" $max_receipt_date "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "max_independent_expenditures" $max_independent_expenditures "scalar") (serialize-qp "min_party_coordinated_expenditures" $min_party_coordinated_expenditures "scalar") (serialize-qp "committee_type" $committee_type "multi") (serialize-qp "page" $page "scalar") (serialize-qp "min_total_contributions" $min_total_contributions "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_cash_on_hand_end_period_amount" $min_cash_on_hand_end_period_amount "scalar") (serialize-qp "min_receipt_date" $min_receipt_date "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "min_independent_expenditures" $min_independent_expenditures "scalar") (serialize-qp "q_filer" $q_filer "multi") (serialize-qp "max_disbursements_amount" $max_disbursements_amount "scalar") (serialize-qp "max_total_contributions" $max_total_contributions "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "amendment_indicator" $amendment_indicator "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "max_receipts_amount" $max_receipts_amount "scalar") (serialize-qp "is_amended" $is_amended "scalar") (serialize-qp "min_disbursements_amount" $min_disbursements_amount "scalar") (serialize-qp "min_receipts_amount" $min_receipts_amount "scalar") (serialize-qp "candidate_id" $candidate_id "scalar") (serialize-qp "beginning_image_number" $beginning_image_number "multi") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "report_type" $report_type "multi") (serialize-qp "most_recent" $most_recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_type: (encode-path-segment $entity_type)} | format pattern "/reports/{entity_type}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"min_debts_owed_amount": $min_debts_owed_amount, "max_debts_owed_expenditures": $max_debts_owed_expenditures, "sort_hide_null": $sort_hide_null, "year": $year, "max_cash_on_hand_end_period_amount": $max_cash_on_hand_end_period_amount, "filer_type": $filer_type, "max_party_coordinated_expenditures": $max_party_coordinated_expenditures, "q_spender": $q_spender, "max_receipt_date": $max_receipt_date, "per_page": $per_page, "max_independent_expenditures": $max_independent_expenditures, "min_party_coordinated_expenditures": $min_party_coordinated_expenditures, "committee_type": $committee_type, "page": $page, "min_total_contributions": $min_total_contributions, "api_key": $api_key, "min_cash_on_hand_end_period_amount": $min_cash_on_hand_end_period_amount, "min_receipt_date": $min_receipt_date, "sort_null_only": $sort_null_only, "min_independent_expenditures": $min_independent_expenditures, "q_filer": $q_filer, "max_disbursements_amount": $max_disbursements_amount, "max_total_contributions": $max_total_contributions, "cycle": $cycle, "amendment_indicator": $amendment_indicator, "sort_nulls_last": $sort_nulls_last, "max_receipts_amount": $max_receipts_amount, "is_amended": $is_amended, "min_disbursements_amount": $min_disbursements_amount, "min_receipts_amount": $min_receipts_amount, "candidate_id": $candidate_id, "beginning_image_number": $beginning_image_number, "sort": $qp_sort, "committee_id": $committee_id, "report_type": $report_type, "most_recent": $most_recent} | compact), body: null}
}

# This description is for both ​`/schedules​/schedule_a​/` and ​ `/schedules​/schedule_a​/{sub_id}​/`. This endpoint provides itemized receipts. Schedule A records describe itemized receipts, including contributions from individuals. If you are interested in contributions from an individual, use the `/schedules/schedule_a/` endpoint. For a more complete description of all Schedule A records visit [About receipts data](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/about-receipts-data/). If you are interested in our "is_individual" methodology visit our [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology/). ​The `/schedules​/schedule_a​/` endpoint is not paginated by page number. This endpoint uses keyset pagination to improve query performance and these indices are required to properly page through this large dataset. To request the next page, you should append the values found in the `last_indexes` object from pagination to the URL of your last request as additional parameters. For example, when sorting by `contribution_receipt_date`, you might receive a page of results with the two scenarios of following pagination information: case #1: ``` pagination: { pages: 2152643, per_page: 20, count: 43052850, last_indexes: { last_index: "230880619", last_contribution_receipt_date: "2014-01-01" } } ``` case #2 (results which include contribution_receipt_date = NULL): ``` pagination: { pages: 2152644, per_page: 20, count: 43052850, last_indexes: { last_index: "230880639", sort_null_only: True } } ``` To fetch the next page of sorted results, append `last_index=230880619` and `last_contribution_receipt_date=2014-01-01` to the URL and when reaching `contribution_receipt_date=NULL`, append `last_index=230880639` and `sort_null_only=True`. We strongly advise paging through these results using sort indices. The default sort is acending by `contribution_receipt_date` (`deprecated`, will be descending). If you do not page using sort indices, some transactions may be unintentionally filtered out. Calls to ​`/schedules​/schedule_a​/` may return many records. For large result sets, the record counts found in the pagination object are approximate; you will need to page through the records until no records are returned. To avoid throwing the "out of range" exception on the last page, one recommandation is to use total count and `per_page` to control the traverse loop of results. ​The `/schedules​/schedule_a​/{sub_id}​/` endpoint returns a single transaction, but it does include a pagination object class. Please ignore the information in that object class.
#
# GET /schedules/schedule_a/
export def "schedules-schedule-a list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-load-date: string # Maximum load date (format: date)
  --max-amount: string # Filter for all amounts less than a value.
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --contributor-occupation: list<string> # Occupation of contributor, filers need to make an effort to gather this information
  --recipient-committee-designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --is-individual: oneof<nothing, bool> # Restrict to non-earmarked individual contributions where memo code is true. Filtering individuals is useful to make sure contributions are not double reported and in creating breakdowns of the amount of money coming from individuals.
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --contributor-type: list<string> # Filters individual or committee contributions based on line number
  --recipient-committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --contributor-zip: list<string> # Zip code of contributor
  --contributor-city: list<string> # City of contributor
  --last-index: int # Index of last result from previous page (format: int32)
  --last-contribution-receipt-amount: float # When sorting by `contribution_receipt_amount`, this is populated with the `contribution_receipt_amount` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: float)
  --contributor-id: list<string> # The FEC identifier should be represented here if the contributor is registered with the FEC.
  --recipient-committee-org-type: list<string> # The one-letter code for the kind for organization: - C corporation - L labor organization - M membership organization - T trade association - V cooperative - W corporation without capital stock
  --contributor-state: list<string> # State of contributor
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -contribution_receipt_date)
  --two-year-transaction-period: list<int> # This is a two-year period that is derived from the year a transaction took place in the Itemized Schedule A and Schedule B tables. In cases where we have the date of the transaction (contribution_receipt_date in schedules/schedule_a, disbursement_date in schedules/schedule_b) the two_year_transaction_period is named after the ending, even-numbered year. If we do not have the date of the transaction, we fall back to using the report year (report_year in both tables) instead, making the same cycle adjustment as necessary. If no transaction year is specified, the results default to the most current cycle.
  --min-date: string # Minimum date (format: date)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --contributor-employer: list<string> # Employer of contributor, filers need to make an effort to gather this information
  --min-load-date: string # Minimum load date (format: date)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --last-contribution-receipt-date: string # When sorting by `contribution_receipt_date`, this is populated with the `contribution_receipt_date` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: date)
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --contributor-name: list<string> # Name of contributor
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --min-amount: string # Filter for all amounts greater than a value.
  --max-date: string # Maximum date (format: date)
]: nothing -> record<pagination: record<count: int, last_indexes: string, pages: int, per_page: int>, results: table<amendment_indicator: string, amendment_indicator_desc: string, back_reference_schedule_name: string, back_reference_transaction_id: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_full: string, candidate_office_state: string, candidate_office_state_full: string, candidate_prefix: string, candidate_suffix: string, committee: record, committee_id: string, committee_name: string, conduit_committee_city: string, conduit_committee_id: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, contribution_receipt_amount: float, contribution_receipt_date: string, contributor: record, contributor_aggregate_ytd: float, contributor_city: string, contributor_employer: string, contributor_first_name: string, contributor_id: string, contributor_last_name: string, contributor_middle_name: string, contributor_name: string, contributor_occupation: string, contributor_prefix: string, contributor_state: string, contributor_street_1: string, contributor_street_2: string, contributor_suffix: string, contributor_zip: string, donor_committee_name: string, election_type: string, election_type_full: string, entity_type: string, entity_type_desc: string, fec_election_type_desc: string, fec_election_year: string, file_number: int, filing_form: string, image_number: string, increased_limit: string, is_individual: bool, line_number: string, line_number_label: string, link_id: int, load_date: string, memo_code: string, memo_code_full: string, memo_text: string, memoed_subtotal: bool, national_committee_nonfederal_account: string, original_sub_id: string, pdf_url: string, receipt_type: string, receipt_type_desc: string, receipt_type_full: string, recipient_committee_designation: string, recipient_committee_org_type: string, recipient_committee_type: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, sub_id: string, transaction_id: string, two_year_transaction_period: int, unused_contbr_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_load_date" $max_load_date "scalar") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "contributor_occupation" $contributor_occupation "multi") (serialize-qp "recipient_committee_designation" $recipient_committee_designation "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "is_individual" $is_individual "scalar") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "contributor_type" $contributor_type "multi") (serialize-qp "recipient_committee_type" $recipient_committee_type "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "contributor_zip" $contributor_zip "multi") (serialize-qp "contributor_city" $contributor_city "multi") (serialize-qp "last_index" $last_index "scalar") (serialize-qp "last_contribution_receipt_amount" $last_contribution_receipt_amount "scalar") (serialize-qp "contributor_id" $contributor_id "multi") (serialize-qp "recipient_committee_org_type" $recipient_committee_org_type "multi") (serialize-qp "contributor_state" $contributor_state "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "two_year_transaction_period" $two_year_transaction_period "multi") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "contributor_employer" $contributor_employer "multi") (serialize-qp "min_load_date" $min_load_date "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "last_contribution_receipt_date" $last_contribution_receipt_date "scalar") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "contributor_name" $contributor_name "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_load_date": $max_load_date, "max_amount": $max_amount, "max_image_number": $max_image_number, "contributor_occupation": $contributor_occupation, "recipient_committee_designation": $recipient_committee_designation, "sort_hide_null": $sort_hide_null, "is_individual": $is_individual, "line_number": $line_number, "contributor_type": $contributor_type, "recipient_committee_type": $recipient_committee_type, "per_page": $per_page, "contributor_zip": $contributor_zip, "contributor_city": $contributor_city, "last_index": $last_index, "last_contribution_receipt_amount": $last_contribution_receipt_amount, "contributor_id": $contributor_id, "recipient_committee_org_type": $recipient_committee_org_type, "contributor_state": $contributor_state, "sort": $qp_sort, "two_year_transaction_period": $two_year_transaction_period, "min_date": $min_date, "committee_id": $committee_id, "contributor_employer": $contributor_employer, "min_load_date": $min_load_date, "api_key": $api_key, "last_contribution_receipt_date": $last_contribution_receipt_date, "min_image_number": $min_image_number, "contributor_name": $contributor_name, "sort_null_only": $sort_null_only, "image_number": $image_number, "min_amount": $min_amount, "max_date": $max_date} | compact), body: null}
}

# This endpoint provides itemized individual contributions received by a committee, aggregated by the contributor’s employer name. If you are interested in our “is_individual” methodology, review the [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology). Unitemized individual contributions are not included.
#
# GET /schedules/schedule_a/by_employer/
export def "schedules-schedule-a-by-employer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer: list<string> # Employer of contributor as reported on the committee's filing
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<committee_id: string, count: int, cycle: int, employer: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "employer" $employer "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_employer/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"employer": $employer, "page": $page, "sort_nulls_last": $sort_nulls_last, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This endpoint provides itemized individual contributions received by a committee, aggregated by the contributor’s occupation. If you are interested in our “is_individual” methodology, review the [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology). Unitemized individual contributions are not included.
#
# GET /schedules/schedule_a/by_occupation/
export def "schedules-schedule-a-by-occupation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occupation: list<string> # Occupation of contributor as reported on the committee's filing
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<committee_id: string, count: int, cycle: int, occupation: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "occupation" $occupation "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_occupation/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"occupation": $occupation, "page": $page, "sort_nulls_last": $sort_nulls_last, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This endpoint provides individual contributions received by a committee, aggregated by size: ``` - $200 and under - $200.01 - $499.99 - $500 - $999.99 - $1000 - $1999.99 - $2000 + ``` The $200.00 and under category includes contributions of $200 or less combined with unitemized individual contributions.
#
# GET /schedules/schedule_a/by_size/
export def "schedules-schedule-a-by-size get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --size: list<int> # The total all contributions in the following ranges: ``` -0 $200 and under -200 $200.01 - $499.99 -500 $500 - $999.99 -1000 $1000 - $1999.99 -2000 $2000 + ``` Unitemized contributions are included in the `0` category.
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<committee_id: string, count: int, cycle: int, size: int, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "size" $size "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_size/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "page": $page, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "size": $size, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This endpoint provides itemized individual contributions received by a committee, aggregated by size of contribution and candidate. If you are interested in our “is_individual” methodology, review the [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology). Unitemized individual contributions are not included.
#
# GET /schedules/schedule_a/by_size/by_candidate/
export def "schedules-schedule-a-by-size-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, count: int, cycle: int, size: int, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_size/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "cycle": $cycle, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This endpoint provides itemized individual contributions received by a committee, aggregated by the contributor’s state. If you are interested in our “is_individual” methodology, review the [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology). Unitemized individual contributions are not included.
#
# GET /schedules/schedule_a/by_state/
export def "schedules-schedule-a-by-state get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hide-null: oneof<nothing, bool> # Exclude values with missing state (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --state: list<string> # State of contributor
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -total)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<committee_id: string, count: int, cycle: int, state: string, state_full: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hide_null" $hide_null "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "state" $state "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_state/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hide_null": $hide_null, "page": $page, "cycle": $cycle, "state": $state, "sort_hide_null": $sort_hide_null, "sort_nulls_last": $sort_nulls_last, "committee_id": $committee_id, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This endpoint provides itemized individual contributions received by a committee, aggregated by contributor’s state and candidate. If you are interested in our “is_individual” methodology, review the [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology). Unitemized individual contributions are not included.
#
# GET /schedules/schedule_a/by_state/by_candidate/
export def "schedules-schedule-a-by-state-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, count: int, cycle: int, state: string, state_full: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_state/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "cycle": $cycle, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Itemized individual contributions aggregated by contributor’s state, candidate, committee type and cycle. If you are interested in our “is_individual” methodology, review the [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology). Unitemized individual contributions are not included.
#
# GET /schedules/schedule_a/by_state/by_candidate/totals/
export def "schedules-schedule-a-by-state-by-candidate-totals get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, count: int, cycle: int, state: string, state_full: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_state/by_candidate/totals/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "cycle": $cycle, "page": $page, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This endpoint provides itemized individual contributions received by a committee, aggregated by contributor’s state, committee type and cycle. If you are interested in our “is_individual” methodology, review the [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology). Unitemized individual contributions are not included.
#
# GET /schedules/schedule_a/by_state/totals/
export def "schedules-schedule-a-by-state-totals get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account - all All Committee Types - all_candidates All Candidate Committee Types (H, S, P) - all_pacs All PAC Committee Types (N, O, Q, V, W)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --state: list<string> # US state or territory
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: cycle)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<committee_type: string, committee_type_full: string, count: int, cycle: int, state: string, state_full: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "committee_type" $committee_type "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "page" $page "scalar") (serialize-qp "state" $state "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_state/totals/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"committee_type": $committee_type, "cycle": $cycle, "page": $page, "state": $state, "sort_hide_null": $sort_hide_null, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# This endpoint provides itemized individual contributions received by a committee, aggregated by the contributor’s ZIP code. If you are interested in our “is_individual” methodology, review the [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology). Unitemized individual contributions are not included.
#
# GET /schedules/schedule_a/by_zip/
export def "schedules-schedule-a-by-zip get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --zip: list<string> # Zip code of contributor
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --state: list<string> # State of contributor
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<committee_id: string, count: int, cycle: int, state: string, state_full: string, total: float, zip: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "zip" $zip "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "state" $state "multi") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/by_zip/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "cycle": $cycle, "zip": $zip, "sort_hide_null": $sort_hide_null, "state": $state, "committee_id": $committee_id, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Efiling endpoints provide real-time campaign finance data received from electronic filers. Efiling endpoints only contain the most recent four months of data and don't contain the processed and coded data that you can find on other endpoints.
#
# GET /schedules/schedule_a/efile/
export def "schedules-schedule-a-efile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-amount: string # Filter for all amounts less than a value.
  --contributor-occupation: list<string> # Occupation of contributor, filers need to make an effort to gather this information
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --contributor-city: list<string> # City of contributor
  --contributor-state: list<string> # State of contributor
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -contribution_receipt_date)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --min-date: string # Minimum date (format: date)
  --contributor-employer: list<string> # Employer of contributor, filers need to make an effort to gather this information
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --contributor-name: list<string> # Name of contributor
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --min-amount: string # Filter for all amounts greater than a value.
  --max-date: string # Maximum date (format: date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<amendment_indicator: string, back_reference_schedule_name: string, back_reference_transaction_id: string, beginning_image_number: string, committee: record, committee_id: string, conduit_committee_city: string, conduit_committee_id: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, contribution_receipt_amount: float, contribution_receipt_date: string, contributor_aggregate_ytd: float, contributor_city: string, contributor_employer: string, contributor_first_name: string, contributor_last_name: string, contributor_middle_name: string, contributor_name: string, contributor_occupation: string, contributor_prefix: string, contributor_state: string, contributor_suffix: string, contributor_zip: string, csv_url: string, cycle: int, entity_type: string, fec_election_type_desc: string, fec_url: string, file_number: int, filing: record, image_number: string, line_number: string, load_timestamp: string, memo_code: string, memo_text: string, pdf_url: string, pgo: string, related_line_number: int, report_type: string, transaction_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "contributor_occupation" $contributor_occupation "multi") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "contributor_city" $contributor_city "multi") (serialize-qp "contributor_state" $contributor_state "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "contributor_employer" $contributor_employer "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "contributor_name" $contributor_name "multi") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_a/efile/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_amount": $max_amount, "contributor_occupation": $contributor_occupation, "max_image_number": $max_image_number, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "line_number": $line_number, "per_page": $per_page, "contributor_city": $contributor_city, "contributor_state": $contributor_state, "page": $page, "sort": $qp_sort, "committee_id": $committee_id, "min_date": $min_date, "contributor_employer": $contributor_employer, "api_key": $api_key, "contributor_name": $contributor_name, "min_image_number": $min_image_number, "sort_null_only": $sort_null_only, "image_number": $image_number, "min_amount": $min_amount, "max_date": $max_date} | compact), body: null}
}

# This description is for both ​`/schedules​/schedule_a​/` and ​ `/schedules​/schedule_a​/{sub_id}​/`. This endpoint provides itemized receipts. Schedule A records describe itemized receipts, including contributions from individuals. If you are interested in contributions from an individual, use the `/schedules/schedule_a/` endpoint. For a more complete description of all Schedule A records visit [About receipts data](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/about-receipts-data/). If you are interested in our "is_individual" methodology visit our [methodology page](https://www.fec.gov/campaign-finance-data/about-campaign-finance-data/methodology/). ​The `/schedules​/schedule_a​/` endpoint is not paginated by page number. This endpoint uses keyset pagination to improve query performance and these indices are required to properly page through this large dataset. To request the next page, you should append the values found in the `last_indexes` object from pagination to the URL of your last request as additional parameters. For example, when sorting by `contribution_receipt_date`, you might receive a page of results with the two scenarios of following pagination information: case #1: ``` pagination: { pages: 2152643, per_page: 20, count: 43052850, last_indexes: { last_index: "230880619", last_contribution_receipt_date: "2014-01-01" } } ``` case #2 (results which include contribution_receipt_date = NULL): ``` pagination: { pages: 2152644, per_page: 20, count: 43052850, last_indexes: { last_index: "230880639", sort_null_only: True } } ``` To fetch the next page of sorted results, append `last_index=230880619` and `last_contribution_receipt_date=2014-01-01` to the URL and when reaching `contribution_receipt_date=NULL`, append `last_index=230880639` and `sort_null_only=True`. We strongly advise paging through these results using sort indices. The default sort is acending by `contribution_receipt_date` (`deprecated`, will be descending). If you do not page using sort indices, some transactions may be unintentionally filtered out. Calls to ​`/schedules​/schedule_a​/` may return many records. For large result sets, the record counts found in the pagination object are approximate; you will need to page through the records until no records are returned. To avoid throwing the "out of range" exception on the last page, one recommandation is to use total count and `per_page` to control the traverse loop of results. ​The `/schedules​/schedule_a​/{sub_id}​/` endpoint returns a single transaction, but it does include a pagination object class. Please ignore the information in that object class.
#
# GET /schedules/schedule_a/{sub_id}/
export def "schedules-schedule-a get" [
  sub_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-load-date: string # Maximum load date (format: date)
  --max-amount: string # Filter for all amounts less than a value.
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --contributor-occupation: list<string> # Occupation of contributor, filers need to make an effort to gather this information
  --recipient-committee-designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --is-individual: oneof<nothing, bool> # Restrict to non-earmarked individual contributions where memo code is true. Filtering individuals is useful to make sure contributions are not double reported and in creating breakdowns of the amount of money coming from individuals.
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --contributor-type: list<string> # Filters individual or committee contributions based on line number
  --recipient-committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --contributor-zip: list<string> # Zip code of contributor
  --contributor-city: list<string> # City of contributor
  --last-index: int # Index of last result from previous page (format: int32)
  --last-contribution-receipt-amount: float # When sorting by `contribution_receipt_amount`, this is populated with the `contribution_receipt_amount` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: float)
  --contributor-id: list<string> # The FEC identifier should be represented here if the contributor is registered with the FEC.
  --recipient-committee-org-type: list<string> # The one-letter code for the kind for organization: - C corporation - L labor organization - M membership organization - T trade association - V cooperative - W corporation without capital stock
  --contributor-state: list<string> # State of contributor
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -contribution_receipt_date)
  --two-year-transaction-period: list<int> # This is a two-year period that is derived from the year a transaction took place in the Itemized Schedule A and Schedule B tables. In cases where we have the date of the transaction (contribution_receipt_date in schedules/schedule_a, disbursement_date in schedules/schedule_b) the two_year_transaction_period is named after the ending, even-numbered year. If we do not have the date of the transaction, we fall back to using the report year (report_year in both tables) instead, making the same cycle adjustment as necessary. If no transaction year is specified, the results default to the most current cycle.
  --min-date: string # Minimum date (format: date)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --contributor-employer: list<string> # Employer of contributor, filers need to make an effort to gather this information
  --min-load-date: string # Minimum load date (format: date)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --last-contribution-receipt-date: string # When sorting by `contribution_receipt_date`, this is populated with the `contribution_receipt_date` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: date)
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --contributor-name: list<string> # Name of contributor
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --min-amount: string # Filter for all amounts greater than a value.
  --max-date: string # Maximum date (format: date)
]: nothing -> record<pagination: record<count: int, last_indexes: string, pages: int, per_page: int>, results: table<amendment_indicator: string, amendment_indicator_desc: string, back_reference_schedule_name: string, back_reference_transaction_id: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_full: string, candidate_office_state: string, candidate_office_state_full: string, candidate_prefix: string, candidate_suffix: string, committee: record, committee_id: string, committee_name: string, conduit_committee_city: string, conduit_committee_id: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, contribution_receipt_amount: float, contribution_receipt_date: string, contributor: record, contributor_aggregate_ytd: float, contributor_city: string, contributor_employer: string, contributor_first_name: string, contributor_id: string, contributor_last_name: string, contributor_middle_name: string, contributor_name: string, contributor_occupation: string, contributor_prefix: string, contributor_state: string, contributor_street_1: string, contributor_street_2: string, contributor_suffix: string, contributor_zip: string, donor_committee_name: string, election_type: string, election_type_full: string, entity_type: string, entity_type_desc: string, fec_election_type_desc: string, fec_election_year: string, file_number: int, filing_form: string, image_number: string, increased_limit: string, is_individual: bool, line_number: string, line_number_label: string, link_id: int, load_date: string, memo_code: string, memo_code_full: string, memo_text: string, memoed_subtotal: bool, national_committee_nonfederal_account: string, original_sub_id: string, pdf_url: string, receipt_type: string, receipt_type_desc: string, receipt_type_full: string, recipient_committee_designation: string, recipient_committee_org_type: string, recipient_committee_type: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, sub_id: string, transaction_id: string, two_year_transaction_period: int, unused_contbr_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($sub_id | is-empty) { error make --unspanned { msg: "path parameter 'sub_id' must be non-empty" } }
  let qp = [(serialize-qp "max_load_date" $max_load_date "scalar") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "contributor_occupation" $contributor_occupation "multi") (serialize-qp "recipient_committee_designation" $recipient_committee_designation "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "is_individual" $is_individual "scalar") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "contributor_type" $contributor_type "multi") (serialize-qp "recipient_committee_type" $recipient_committee_type "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "contributor_zip" $contributor_zip "multi") (serialize-qp "contributor_city" $contributor_city "multi") (serialize-qp "last_index" $last_index "scalar") (serialize-qp "last_contribution_receipt_amount" $last_contribution_receipt_amount "scalar") (serialize-qp "contributor_id" $contributor_id "multi") (serialize-qp "recipient_committee_org_type" $recipient_committee_org_type "multi") (serialize-qp "contributor_state" $contributor_state "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "two_year_transaction_period" $two_year_transaction_period "multi") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "contributor_employer" $contributor_employer "multi") (serialize-qp "min_load_date" $min_load_date "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "last_contribution_receipt_date" $last_contribution_receipt_date "scalar") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "contributor_name" $contributor_name "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sub_id: (encode-path-segment $sub_id)} | format pattern "/schedules/schedule_a/{sub_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_load_date": $max_load_date, "max_amount": $max_amount, "max_image_number": $max_image_number, "contributor_occupation": $contributor_occupation, "recipient_committee_designation": $recipient_committee_designation, "sort_hide_null": $sort_hide_null, "is_individual": $is_individual, "line_number": $line_number, "contributor_type": $contributor_type, "recipient_committee_type": $recipient_committee_type, "per_page": $per_page, "contributor_zip": $contributor_zip, "contributor_city": $contributor_city, "last_index": $last_index, "last_contribution_receipt_amount": $last_contribution_receipt_amount, "contributor_id": $contributor_id, "recipient_committee_org_type": $recipient_committee_org_type, "contributor_state": $contributor_state, "sort": $qp_sort, "two_year_transaction_period": $two_year_transaction_period, "min_date": $min_date, "committee_id": $committee_id, "contributor_employer": $contributor_employer, "min_load_date": $min_load_date, "api_key": $api_key, "last_contribution_receipt_date": $last_contribution_receipt_date, "min_image_number": $min_image_number, "contributor_name": $contributor_name, "sort_null_only": $sort_null_only, "image_number": $image_number, "min_amount": $min_amount, "max_date": $max_date} | compact), body: null}
}

# Schedule B filings describe itemized disbursements. This data explains how committees and other filers spend their money. These figures are reported as part of forms F3, F3X and F3P. The data is divided in two-year periods, called `two_year_transaction_period`, which is derived from the `report_year` submitted of the corresponding form. If no value is supplied, the results will default to the most recent two-year period that is named after the ending, even-numbered year. Due to the large quantity of Schedule B filings, this endpoint is not paginated by page number. Instead, you can request the next page of results by adding the values in the `last_indexes` object from `pagination` to the URL of your last request. For example, when sorting by `disbursement_date`, you might receive a page of results with the following pagination information: ``` pagination: { pages: 965191, per_page: 20, count: 19303814, last_indexes: { last_index: "230906248", last_disbursement_date: "2014-07-04" } } ``` To fetch the next page of sorted results, append `last_index=230906248` and `last_disbursement_date=2014-07-04` to the URL. We strongly advise paging through these results by using the sort indices (defaults to sort by disbursement date, e.g. `last_disbursement_date`), otherwise some resources may be unintentionally filtered out. This resource uses keyset pagination to improve query performance and these indices are required to properly page through this large dataset. Note: because the Schedule B data includes many records, counts for large result sets are approximate; you will want to page through the records until no records are returned.
#
# GET /schedules/schedule_b/
export def "schedules-schedule-b list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disbursement-description: list<string> # Description of disbursement
  --max-amount: string # Filter for all amounts less than a value.
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --last-disbursement-date: string # When sorting by `disbursement_date`, this is populated with the `disbursement_date` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: date)
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --spender-committee-designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --last-disbursement-amount: float # When sorting by `disbursement_amount`, this is populated with the `disbursement_amount` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: float)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --last-index: int # Index of last result from previous page (format: int32)
  --spender-committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -disbursement_date)
  --two-year-transaction-period: list<int> # This is a two-year period that is derived from the year a transaction took place in the Itemized Schedule A and Schedule B tables. In cases where we have the date of the transaction (contribution_receipt_date in schedules/schedule_a, disbursement_date in schedules/schedule_b) the two_year_transaction_period is named after the ending, even-numbered year. If we do not have the date of the transaction, we fall back to using the report year (report_year in both tables) instead, making the same cycle adjustment as necessary. If no transaction year is specified, the results default to the most current cycle.
  --min-date: string # Minimum date (format: date)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --disbursement-purpose-category: list<string> # Disbursement purpose category
  --recipient-name: list<string> # Name of the entity receiving the disbursement
  --recipient-state: list<string> # State of recipient
  --recipient-city: list<string> # City of recipient
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --spender-committee-org-type: list<string> # The one-letter code for the kind for organization: - C corporation - L labor organization - M membership organization - T trade association - V cooperative - W corporation without capital stock
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --recipient-committee-id: list<string> # The FEC identifier should be represented here if the contributor is registered with the FEC.
  --min-amount: string # Filter for all amounts greater than a value.
  --max-date: string # Maximum date (format: date)
]: nothing -> record<pagination: record<count: int, last_indexes: string, pages: int, per_page: int>, results: table<amendment_indicator: string, amendment_indicator_desc: string, back_reference_schedule_id: string, back_reference_transaction_id: string, beneficiary_committee_name: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_description: string, candidate_office_district: string, candidate_office_state: string, candidate_office_state_full: string, candidate_prefix: string, candidate_suffix: string, category_code: string, category_code_full: string, comm_dt: string, committee: record, committee_id: string, conduit_committee_city: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, disbursement_amount: float, disbursement_date: string, disbursement_description: string, disbursement_purpose_category: string, disbursement_type: string, disbursement_type_description: string, election_type: string, election_type_full: string, entity_type: string, entity_type_desc: string, fec_election_type_desc: string, fec_election_year: string, file_number: int, filing_form: string, image_number: string, line_number: string, line_number_label: string, link_id: int, load_date: string, memo_code: string, memo_code_full: string, memo_text: string, memoed_subtotal: bool, national_committee_nonfederal_account: string, original_sub_id: string, payee_employer: string, payee_first_name: string, payee_last_name: string, payee_middle_name: string, payee_occupation: string, payee_prefix: string, payee_suffix: string, pdf_url: string, recipient_city: string, recipient_committee: record, recipient_committee_id: string, recipient_name: string, recipient_state: string, recipient_zip: string, ref_disp_excess_flg: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, semi_annual_bundled_refund: float, spender_committee_designation: string, spender_committee_org_type: string, spender_committee_type: string, sub_id: string, transaction_id: string, two_year_transaction_period: int, unused_recipient_committee_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disbursement_description" $disbursement_description "multi") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "last_disbursement_date" $last_disbursement_date "scalar") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "spender_committee_designation" $spender_committee_designation "multi") (serialize-qp "last_disbursement_amount" $last_disbursement_amount "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "last_index" $last_index "scalar") (serialize-qp "spender_committee_type" $spender_committee_type "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "two_year_transaction_period" $two_year_transaction_period "multi") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "disbursement_purpose_category" $disbursement_purpose_category "multi") (serialize-qp "recipient_name" $recipient_name "multi") (serialize-qp "recipient_state" $recipient_state "multi") (serialize-qp "recipient_city" $recipient_city "multi") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "spender_committee_org_type" $spender_committee_org_type "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "recipient_committee_id" $recipient_committee_id "multi") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_b/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"disbursement_description": $disbursement_description, "max_amount": $max_amount, "max_image_number": $max_image_number, "image_number": $image_number, "sort_hide_null": $sort_hide_null, "last_disbursement_date": $last_disbursement_date, "line_number": $line_number, "spender_committee_designation": $spender_committee_designation, "last_disbursement_amount": $last_disbursement_amount, "per_page": $per_page, "last_index": $last_index, "spender_committee_type": $spender_committee_type, "sort": $qp_sort, "two_year_transaction_period": $two_year_transaction_period, "min_date": $min_date, "committee_id": $committee_id, "api_key": $api_key, "disbursement_purpose_category": $disbursement_purpose_category, "recipient_name": $recipient_name, "recipient_state": $recipient_state, "recipient_city": $recipient_city, "min_image_number": $min_image_number, "spender_committee_org_type": $spender_committee_org_type, "sort_null_only": $sort_null_only, "recipient_committee_id": $recipient_committee_id, "min_amount": $min_amount, "max_date": $max_date} | compact), body: null}
}

# Schedule B disbursements aggregated by disbursement purpose category. To avoid double counting, memoed items are not included. Purpose is a combination of transaction codes, category codes and disbursement description. Inspect the `disbursement_purpose` sql function within the migrations for more details.
#
# GET /schedules/schedule_b/by_purpose/
export def "schedules-schedule-b-by-purpose get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --purpose: list<string> # Disbursement purpose category
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<committee_id: string, count: int, cycle: int, memo_count: int, memo_total: float, purpose: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "purpose" $purpose "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_b/by_purpose/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"purpose": $purpose, "sort_nulls_last": $sort_nulls_last, "page": $page, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Schedule B disbursements aggregated by recipient name. To avoid double counting, memoed items are not included.
#
# GET /schedules/schedule_b/by_recipient/
export def "schedules-schedule-b-by-recipient get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --recipient-name: list<string> # Name of the entity receiving the disbursement
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, last_indexes: string, pages: int, per_page: int>, results: table<committee_id: string, committee_total_disbursements: float, count: int, cycle: int, memo_count: int, memo_total: float, recipient_disbursement_percent: float, recipient_name: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "recipient_name" $recipient_name "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_b/by_recipient/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "page": $page, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "recipient_name": $recipient_name, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Schedule B disbursements aggregated by recipient committee ID, if applicable. To avoid double counting, memoed items are not included.
#
# GET /schedules/schedule_b/by_recipient_id/
export def "schedules-schedule-b-by-recipient-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --recipient-id: list<string> # The FEC identifier should be represented here if the entity receiving the disbursement is registered with the FEC.
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<committee_id: string, committee_name: string, count: int, cycle: int, memo_count: int, memo_total: float, recipient_id: string, recipient_name: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "recipient_id" $recipient_id "multi") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_b/by_recipient_id/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "page": $page, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "recipient_id": $recipient_id, "sort": $qp_sort} | compact), body: null}
}

# Efiling endpoints provide real-time campaign finance data received from electronic filers. Efiling endpoints only contain the most recent four months of data and don't contain the processed and coded data that you can find on other endpoints.
#
# GET /schedules/schedule_b/efile/
export def "schedules-schedule-b-efile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disbursement-description: list<string> # Description of disbursement
  --max-amount: string # Filter for all amounts less than a value.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -disbursement_date)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --min-date: string # When sorting by `disbursement_date`, this is populated with the `disbursement_date` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: date)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --recipient-state: list<string> # State of recipient
  --recipient-city: list<string> # City of recipient
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --min-amount: string # Filter for all amounts less than a value.
  --max-date: string # When sorting by `disbursement_date`, this is populated with the `disbursement_date` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<amendment_indicator: string, back_reference_schedule_name: string, back_reference_transaction_id: string, beginning_image_number: string, beneficiary_committee_name: string, candidate_office: string, candidate_office_district: string, committee: record, committee_id: string, csv_url: string, disbursement_amount: float, disbursement_date: string, disbursement_description: string, disbursement_type: string, entity_type: string, fec_url: string, file_number: int, filing: record, image_number: string, is_notice: bool, line_number: string, load_timestamp: string, memo_code: string, memo_text: string, payee_name: string, pdf_url: string, recipient_city: string, recipient_name: string, recipient_prefix: string, recipient_state: string, recipient_suffix: string, recipient_zip: string, related_line_number: int, report_type: string, semi_annual_bundled_refund: int, transaction_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disbursement_description" $disbursement_description "multi") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "recipient_state" $recipient_state "multi") (serialize-qp "recipient_city" $recipient_city "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_b/efile/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"disbursement_description": $disbursement_description, "max_amount": $max_amount, "page": $page, "sort_nulls_last": $sort_nulls_last, "sort": $qp_sort, "sort_hide_null": $sort_hide_null, "committee_id": $committee_id, "min_date": $min_date, "api_key": $api_key, "recipient_state": $recipient_state, "recipient_city": $recipient_city, "sort_null_only": $sort_null_only, "per_page": $per_page, "image_number": $image_number, "min_amount": $min_amount, "max_date": $max_date} | compact), body: null}
}

# Schedule B filings describe itemized disbursements. This data explains how committees and other filers spend their money. These figures are reported as part of forms F3, F3X and F3P. The data is divided in two-year periods, called `two_year_transaction_period`, which is derived from the `report_year` submitted of the corresponding form. If no value is supplied, the results will default to the most recent two-year period that is named after the ending, even-numbered year. Due to the large quantity of Schedule B filings, this endpoint is not paginated by page number. Instead, you can request the next page of results by adding the values in the `last_indexes` object from `pagination` to the URL of your last request. For example, when sorting by `disbursement_date`, you might receive a page of results with the following pagination information: ``` pagination: { pages: 965191, per_page: 20, count: 19303814, last_indexes: { last_index: "230906248", last_disbursement_date: "2014-07-04" } } ``` To fetch the next page of sorted results, append `last_index=230906248` and `last_disbursement_date=2014-07-04` to the URL. We strongly advise paging through these results by using the sort indices (defaults to sort by disbursement date, e.g. `last_disbursement_date`), otherwise some resources may be unintentionally filtered out. This resource uses keyset pagination to improve query performance and these indices are required to properly page through this large dataset. Note: because the Schedule B data includes many records, counts for large result sets are approximate; you will want to page through the records until no records are returned.
#
# GET /schedules/schedule_b/{sub_id}/
export def "schedules-schedule-b get" [
  sub_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disbursement-description: list<string> # Description of disbursement
  --max-amount: string # Filter for all amounts less than a value.
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --last-disbursement-date: string # When sorting by `disbursement_date`, this is populated with the `disbursement_date` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: date)
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --spender-committee-designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --last-disbursement-amount: float # When sorting by `disbursement_amount`, this is populated with the `disbursement_amount` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: float)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --last-index: int # Index of last result from previous page (format: int32)
  --spender-committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -disbursement_date)
  --two-year-transaction-period: list<int> # This is a two-year period that is derived from the year a transaction took place in the Itemized Schedule A and Schedule B tables. In cases where we have the date of the transaction (contribution_receipt_date in schedules/schedule_a, disbursement_date in schedules/schedule_b) the two_year_transaction_period is named after the ending, even-numbered year. If we do not have the date of the transaction, we fall back to using the report year (report_year in both tables) instead, making the same cycle adjustment as necessary. If no transaction year is specified, the results default to the most current cycle.
  --min-date: string # Minimum date (format: date)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --disbursement-purpose-category: list<string> # Disbursement purpose category
  --recipient-name: list<string> # Name of the entity receiving the disbursement
  --recipient-state: list<string> # State of recipient
  --recipient-city: list<string> # City of recipient
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --spender-committee-org-type: list<string> # The one-letter code for the kind for organization: - C corporation - L labor organization - M membership organization - T trade association - V cooperative - W corporation without capital stock
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --recipient-committee-id: list<string> # The FEC identifier should be represented here if the contributor is registered with the FEC.
  --min-amount: string # Filter for all amounts greater than a value.
  --max-date: string # Maximum date (format: date)
]: nothing -> record<pagination: record<count: int, last_indexes: string, pages: int, per_page: int>, results: table<amendment_indicator: string, amendment_indicator_desc: string, back_reference_schedule_id: string, back_reference_transaction_id: string, beneficiary_committee_name: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_description: string, candidate_office_district: string, candidate_office_state: string, candidate_office_state_full: string, candidate_prefix: string, candidate_suffix: string, category_code: string, category_code_full: string, comm_dt: string, committee: record, committee_id: string, conduit_committee_city: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, disbursement_amount: float, disbursement_date: string, disbursement_description: string, disbursement_purpose_category: string, disbursement_type: string, disbursement_type_description: string, election_type: string, election_type_full: string, entity_type: string, entity_type_desc: string, fec_election_type_desc: string, fec_election_year: string, file_number: int, filing_form: string, image_number: string, line_number: string, line_number_label: string, link_id: int, load_date: string, memo_code: string, memo_code_full: string, memo_text: string, memoed_subtotal: bool, national_committee_nonfederal_account: string, original_sub_id: string, payee_employer: string, payee_first_name: string, payee_last_name: string, payee_middle_name: string, payee_occupation: string, payee_prefix: string, payee_suffix: string, pdf_url: string, recipient_city: string, recipient_committee: record, recipient_committee_id: string, recipient_name: string, recipient_state: string, recipient_zip: string, ref_disp_excess_flg: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, semi_annual_bundled_refund: float, spender_committee_designation: string, spender_committee_org_type: string, spender_committee_type: string, sub_id: string, transaction_id: string, two_year_transaction_period: int, unused_recipient_committee_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($sub_id | is-empty) { error make --unspanned { msg: "path parameter 'sub_id' must be non-empty" } }
  let qp = [(serialize-qp "disbursement_description" $disbursement_description "multi") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "last_disbursement_date" $last_disbursement_date "scalar") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "spender_committee_designation" $spender_committee_designation "multi") (serialize-qp "last_disbursement_amount" $last_disbursement_amount "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "last_index" $last_index "scalar") (serialize-qp "spender_committee_type" $spender_committee_type "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "two_year_transaction_period" $two_year_transaction_period "multi") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "disbursement_purpose_category" $disbursement_purpose_category "multi") (serialize-qp "recipient_name" $recipient_name "multi") (serialize-qp "recipient_state" $recipient_state "multi") (serialize-qp "recipient_city" $recipient_city "multi") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "spender_committee_org_type" $spender_committee_org_type "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "recipient_committee_id" $recipient_committee_id "multi") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sub_id: (encode-path-segment $sub_id)} | format pattern "/schedules/schedule_b/{sub_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"disbursement_description": $disbursement_description, "max_amount": $max_amount, "max_image_number": $max_image_number, "image_number": $image_number, "sort_hide_null": $sort_hide_null, "last_disbursement_date": $last_disbursement_date, "line_number": $line_number, "spender_committee_designation": $spender_committee_designation, "last_disbursement_amount": $last_disbursement_amount, "per_page": $per_page, "last_index": $last_index, "spender_committee_type": $spender_committee_type, "sort": $qp_sort, "two_year_transaction_period": $two_year_transaction_period, "min_date": $min_date, "committee_id": $committee_id, "api_key": $api_key, "disbursement_purpose_category": $disbursement_purpose_category, "recipient_name": $recipient_name, "recipient_state": $recipient_state, "recipient_city": $recipient_city, "min_image_number": $min_image_number, "spender_committee_org_type": $spender_committee_org_type, "sort_null_only": $sort_null_only, "recipient_committee_id": $recipient_committee_id, "min_amount": $min_amount, "max_date": $max_date} | compact), body: null}
}

# Schedule C shows all loans, endorsements and loan guarantees a committee receives or makes. The committee continues to report the loan until it is repaid.
#
# GET /schedules/schedule_c/
export def "schedules-schedule-c list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-incurred-date: string # Minimum incurred date (format: date)
  --candidate-name: list<string> # Name of candidate running for office
  --max-amount: string # Filter for all amounts less than a value.
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: true)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --max-incurred-date: string # Maximum incurred date (format: date)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --last-index: int # Index of last result from previous page (format: int32)
  --loan-source-name: list<string> # Source of the loan (i.e., bank loan, brokerage account, credit card, home equity line of credit, other line of credit, or personal funds of the candidate
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -incurred_date)
  --max-payment-to-date: int # Maximum payment to date (format: int32)
  --min-payment-to-date: int # Minimum payment to date (format: int32)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --min-amount: string # Filter for all amounts greater than a value.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<action_code: string, action_code_full: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_full: string, candidate_office_state: string, candidate_office_state_full: string, candidate_prefix: string, candidate_suffix: string, committee: record, committee_id: string, cycle: int, due_date_terms: string, election_type: string, election_type_full: string, entity_type: string, entity_type_full: string, fec_committee_id: string, fec_election_type_full: string, fec_election_type_year: string, file_number: int, filing_form: string, image_number: string, incurred_date: string, interest_rate_terms: string, line_number: string, link_id: int, load_date: string, loan_balance: float, loan_source_city: string, loan_source_first_name: string, loan_source_last_name: string, loan_source_middle_name: string, loan_source_name: string, loan_source_prefix: string, loan_source_state: string, loan_source_street_1: string, loan_source_street_2: string, loan_source_suffix: string, loan_source_zip: int, memo_code: string, memo_text: string, original_loan_amount: float, original_sub_id: int, payment_to_date: float, pdf_url: string, personally_funded: string, report_type: string, report_year: int, schedule_a_line_number: int, schedule_type: string, schedule_type_full: string, secured_ind: string, sub_id: string, transaction_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_incurred_date" $min_incurred_date "scalar") (serialize-qp "candidate_name" $candidate_name "multi") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "max_incurred_date" $max_incurred_date "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "last_index" $last_index "scalar") (serialize-qp "loan_source_name" $loan_source_name "multi") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max_payment_to_date" $max_payment_to_date "scalar") (serialize-qp "min_payment_to_date" $min_payment_to_date "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "min_amount" $min_amount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_c/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"min_incurred_date": $min_incurred_date, "candidate_name": $candidate_name, "max_amount": $max_amount, "max_image_number": $max_image_number, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "line_number": $line_number, "max_incurred_date": $max_incurred_date, "per_page": $per_page, "last_index": $last_index, "loan_source_name": $loan_source_name, "page": $page, "sort": $qp_sort, "max_payment_to_date": $max_payment_to_date, "min_payment_to_date": $min_payment_to_date, "committee_id": $committee_id, "api_key": $api_key, "min_image_number": $min_image_number, "sort_null_only": $sort_null_only, "image_number": $image_number, "min_amount": $min_amount} | compact), body: null}
}

# Schedule C shows all loans, endorsements and loan guarantees a committee receives or makes. The committee continues to report the loan until it is repaid.
#
# GET /schedules/schedule_c/{sub_id}/
export def "schedules-schedule-c get" [
  sub_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<action_code: string, action_code_full: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_full: string, candidate_office_state: string, candidate_office_state_full: string, candidate_prefix: string, candidate_suffix: string, committee: record, committee_id: string, cycle: int, due_date_terms: string, election_type: string, election_type_full: string, entity_type: string, entity_type_full: string, fec_committee_id: string, fec_election_type_full: string, fec_election_type_year: string, file_number: int, filing_form: string, image_number: string, incurred_date: string, interest_rate_terms: string, line_number: string, link_id: int, load_date: string, loan_balance: float, loan_source_city: string, loan_source_first_name: string, loan_source_last_name: string, loan_source_middle_name: string, loan_source_name: string, loan_source_prefix: string, loan_source_state: string, loan_source_street_1: string, loan_source_street_2: string, loan_source_suffix: string, loan_source_zip: int, memo_code: string, memo_text: string, original_loan_amount: float, original_sub_id: int, payment_to_date: float, pdf_url: string, personally_funded: string, report_type: string, report_year: int, schedule_a_line_number: int, schedule_type: string, schedule_type_full: string, secured_ind: string, sub_id: string, transaction_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($sub_id | is-empty) { error make --unspanned { msg: "path parameter 'sub_id' must be non-empty" } }
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sub_id: (encode-path-segment $sub_id)} | format pattern "/schedules/schedule_c/{sub_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "api_key": $api_key, "page": $page} | compact), body: null}
}

# Schedule D, it shows debts and obligations owed to or by the committee that are required to be disclosed.
#
# GET /schedules/schedule_d/
export def "schedules-schedule-d list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --creditor-debtor-name: list<string>
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --max-amount-outstanding-beginning: float # format: float
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --min-payment-period: float # format: float
  --max-amount-incurred: float # format: float
  --nature-of-debt: string
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --max-amount-outstanding-close: float # format: float
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-date: string # Minimum load date (format: date)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --min-amount-outstanding-close: float # format: float
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --max-payment-period: float # format: float
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --min-amount-incurred: float # format: float
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: load_date)
  --min-amount-outstanding-beginning: float # format: float
  --max-date: string # Maximum load date (format: date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<action_code: string, action_code_full: string, amount_incurred_period: float, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_state: string, candidate_office_state_full: string, committee: record, committee_id: string, committee_name: string, conduit_committee_city: string, conduit_committee_id: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, creditor_debtor_city: string, creditor_debtor_first_name: string, creditor_debtor_id: string, creditor_debtor_last_name: string, creditor_debtor_middle_name: string, creditor_debtor_name: string, creditor_debtor_prefix: string, creditor_debtor_state: string, creditor_debtor_street1: string, creditor_debtor_street2: string, creditor_debtor_suffix: string, election_cycle: int, entity_type: string, file_number: int, filing_form: string, image_number: string, line_number: string, link_id: int, load_date: string, nature_of_debt: string, original_sub_id: int, outstanding_balance_beginning_of_period: float, outstanding_balance_close_of_period: float, payment_period: float, pdf_url: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, sub_id: string, transaction_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creditor_debtor_name" $creditor_debtor_name "multi") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "max_amount_outstanding_beginning" $max_amount_outstanding_beginning "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "min_payment_period" $min_payment_period "scalar") (serialize-qp "max_amount_incurred" $max_amount_incurred "scalar") (serialize-qp "nature_of_debt" $nature_of_debt "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "max_amount_outstanding_close" $max_amount_outstanding_close "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "min_amount_outstanding_close" $min_amount_outstanding_close "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "max_payment_period" $max_payment_period "scalar") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "min_amount_incurred" $min_amount_incurred "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "min_amount_outstanding_beginning" $min_amount_outstanding_beginning "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_d/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"creditor_debtor_name": $creditor_debtor_name, "max_image_number": $max_image_number, "sort_nulls_last": $sort_nulls_last, "max_amount_outstanding_beginning": $max_amount_outstanding_beginning, "sort_hide_null": $sort_hide_null, "min_payment_period": $min_payment_period, "max_amount_incurred": $max_amount_incurred, "nature_of_debt": $nature_of_debt, "per_page": $per_page, "max_amount_outstanding_close": $max_amount_outstanding_close, "candidate_id": $candidate_id, "page": $page, "min_date": $min_date, "committee_id": $committee_id, "min_amount_outstanding_close": $min_amount_outstanding_close, "api_key": $api_key, "max_payment_period": $max_payment_period, "min_image_number": $min_image_number, "min_amount_incurred": $min_amount_incurred, "sort_null_only": $sort_null_only, "image_number": $image_number, "sort": $qp_sort, "min_amount_outstanding_beginning": $min_amount_outstanding_beginning, "max_date": $max_date} | compact), body: null}
}

# Schedule D, it shows debts and obligations owed to or by the committee that are required to be disclosed.
#
# GET /schedules/schedule_d/{sub_id}/
export def "schedules-schedule-d get" [
  sub_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: load_date)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<action_code: string, action_code_full: string, amount_incurred_period: float, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_state: string, candidate_office_state_full: string, committee: record, committee_id: string, committee_name: string, conduit_committee_city: string, conduit_committee_id: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, creditor_debtor_city: string, creditor_debtor_first_name: string, creditor_debtor_id: string, creditor_debtor_last_name: string, creditor_debtor_middle_name: string, creditor_debtor_name: string, creditor_debtor_prefix: string, creditor_debtor_state: string, creditor_debtor_street1: string, creditor_debtor_street2: string, creditor_debtor_suffix: string, election_cycle: int, entity_type: string, file_number: int, filing_form: string, image_number: string, line_number: string, link_id: int, load_date: string, nature_of_debt: string, original_sub_id: int, outstanding_balance_beginning_of_period: float, outstanding_balance_close_of_period: float, payment_period: float, pdf_url: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, sub_id: string, transaction_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($sub_id | is-empty) { error make --unspanned { msg: "path parameter 'sub_id' must be non-empty" } }
  let qp = [(serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sub_id: (encode-path-segment $sub_id)} | format pattern "/schedules/schedule_d/{sub_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "api_key": $api_key, "page": $page} | compact), body: null}
}

# Schedule E covers the line item expenditures for independent expenditures. For example, if a super PAC bought ads on TV to oppose a federal candidate, each ad purchase would be recorded here with the expenditure amount, name and id of the candidate, and whether the ad supported or opposed the candidate. An independent expenditure is an expenditure for a communication "expressly advocating the election or defeat of a clearly identified candidate that is not made in cooperation, consultation, or concert with, or at the request or suggestion of, a candidate, a candidate’s authorized committee, or their agents, or a political party or its agents." Aggregates by candidate do not include 24 and 48 hour reports. This ensures we don't double count expenditures and the totals are more accurate. You can still find the information from 24 and 48 hour reports in `/schedule/schedule_e/`. Due to the large quantity of Schedule E filings, this endpoint is not paginated by page number. Instead, you can request the next page of results by adding the values in the `last_indexes` object from `pagination` to the URL of your last request. For example, when sorting by `expenditure_amount`, you might receive a page of results with the following pagination information: ``` "pagination": { "count": 152623, "last_indexes": { "last_index": "3023037", "last_expenditure_amount": -17348.5 }, "per_page": 20, "pages": 7632 } } ``` To fetch the next page of sorted results, append `last_index=3023037` and `last_expenditure_amount=` to the URL. We strongly advise paging through these results by using the sort indices (defaults to sort by disbursement date, e.g. `last_disbursement_date`), otherwise some resources may be unintentionally filtered out. This resource uses keyset pagination to improve query performance and these indices are required to properly page through this large dataset. Note: because the Schedule E data includes many records, counts for large result sets are approximate; you will want to page through the records until no records are returned.
#
# GET /schedules/schedule_e/
export def "schedules-schedule-e get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-dissemination-date: string # Selects all items distributed by this committee before this date (format: date)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --payee-name: list<string> # Name of the entity that received the payment.
  --q-spender: list<string> # Keyword search for spender name or ID
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --last-index: int # Index of last result from previous page (format: int32)
  --min-dissemination-date: string # Selects all items distributed by this committee after this date (format: date)
  --candidate-office-state: list<string> # US state or territory
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --filing-form: list<string> # The form where the underlying data comes from, for example, Form 1 would appear as F1: - F1 Statement of Organization - F1M Notification of Multicandidate Status - F2 Statement of Candidacy - F3 Report of Receipts and Disbursements for an Authorized Committee - F3P Report of Receipts and Disbursements by an Authorized Committee of a Candidate for The Office of President or Vice President - F3L Report of Contributions Bundled by Lobbyists/Registrants and Lobbyist/Registrant PACs - F3X Report of Receipts and Disbursements for other than an Authorized Committee - F4 Report of Receipts and Disbursements for a Committee or Organization Supporting a Nomination Convention - F5 Report of Independent Expenditures Made and Contributions Received - F6 48 Hour Notice of Contributions/Loans Received - F7 Report of Communication Costs by Corporations and Membership Organizations - F8 Debt Settlement Plan - F9 24 Hour Notice of Disbursements for Electioneering Communications - F13 Report of Donations Accepted for Inaugural Committee - F99 Miscellaneous Text - FRQ Request for Additional Information
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --max-amount: string # Filter for all amounts less than a value.
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --min-filing-date: string # Selects all filings received after this date (format: date)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --support-oppose-indicator: list<string> # Explains if the money was spent in order to support or oppose a candidate or candidates. (Coded S or O for support or oppose.) This indicator applies to independent expenditures and communication costs.
  --candidate-office: list<string> # Federal office candidate runs for: H, S or P
  --is-notice: list<bool> # Record filed as 24- or 48-hour notice.
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --last-expenditure-amount: float # When sorting by `expenditure_amount`, this is populated with the `expenditure_amount` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: float)
  --last-expenditure-date: string # When sorting by `expenditure_date`, this is populated with the `expenditure_date` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page. (format: date)
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --last-office-total-ytd: float # When sorting by `office_total_ytd`, this is populated with the `office_total_ytd` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page.' (format: float)
  --last-support-oppose-indicator: string # When sorting by `support_oppose_indicator`, this is populated with the `support_oppose_indicator` of the last result. However, you will need to pass the index of that last result to `last_index` to get the next page.'
  --min-date: string # Minimum date (format: date)
  --candidate-party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --max-filing-date: string # Selects all filings received before this date (format: date)
  --candidate-office-district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --min-amount: string # Filter for all amounts greater than a value.
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -expenditure_date)
  --max-date: string # Maximum date (format: date)
  --most-recent: oneof<nothing, bool> # The report associated with the transaction is either new or is the most-recently filed amendment. Undetermined version (`null`) is always included.
]: nothing -> record<pagination: record<count: int, last_indexes: string, pages: int, per_page: int>, results: table<action_code: string, action_code_full: string, amendment_indicator: string, amendment_number: int, back_reference_schedule_name: string, back_reference_transaction_id: string, candidate: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_state: string, candidate_party: string, candidate_prefix: string, candidate_suffix: string, category_code: string, category_code_full: string, committee: record, committee_id: string, conduit_committee_city: string, conduit_committee_id: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, dissemination_date: string, election_type: string, election_type_full: string, expenditure_amount: float, expenditure_date: string, expenditure_description: string, file_number: int, filer_first_name: string, filer_last_name: string, filer_middle_name: string, filer_prefix: string, filer_suffix: string, filing_date: string, filing_form: string, image_number: string, independent_sign_date: string, independent_sign_name: string, is_notice: bool, line_number: string, link_id: int, memo_code: string, memo_code_full: string, memo_text: string, memoed_subtotal: bool, most_recent: bool, notary_commission_expiration_date: string, notary_sign_date: string, notary_sign_name: string, office_total_ytd: float, original_sub_id: string, payee_city: string, payee_first_name: string, payee_last_name: string, payee_middle_name: string, payee_name: string, payee_prefix: string, payee_state: string, payee_street_1: string, payee_street_2: string, payee_suffix: string, payee_zip: string, pdf_url: string, previous_file_number: int, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, sub_id: string, support_oppose_indicator: string, transaction_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_dissemination_date" $max_dissemination_date "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "payee_name" $payee_name "multi") (serialize-qp "q_spender" $q_spender "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "last_index" $last_index "scalar") (serialize-qp "min_dissemination_date" $min_dissemination_date "scalar") (serialize-qp "candidate_office_state" $candidate_office_state "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "filing_form" $filing_form "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "min_filing_date" $min_filing_date "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "support_oppose_indicator" $support_oppose_indicator "multi") (serialize-qp "candidate_office" $candidate_office "multi") (serialize-qp "is_notice" $is_notice "multi") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "last_expenditure_amount" $last_expenditure_amount "scalar") (serialize-qp "last_expenditure_date" $last_expenditure_date "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "last_office_total_ytd" $last_office_total_ytd "scalar") (serialize-qp "last_support_oppose_indicator" $last_support_oppose_indicator "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "candidate_party" $candidate_party "multi") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "max_filing_date" $max_filing_date "scalar") (serialize-qp "candidate_office_district" $candidate_office_district "multi") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max_date" $max_date "scalar") (serialize-qp "most_recent" $most_recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_e/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_dissemination_date": $max_dissemination_date, "sort_hide_null": $sort_hide_null, "payee_name": $payee_name, "q_spender": $q_spender, "per_page": $per_page, "last_index": $last_index, "min_dissemination_date": $min_dissemination_date, "candidate_office_state": $candidate_office_state, "api_key": $api_key, "filing_form": $filing_form, "sort_null_only": $sort_null_only, "max_amount": $max_amount, "max_image_number": $max_image_number, "min_filing_date": $min_filing_date, "cycle": $cycle, "sort_nulls_last": $sort_nulls_last, "support_oppose_indicator": $support_oppose_indicator, "candidate_office": $candidate_office, "is_notice": $is_notice, "line_number": $line_number, "last_expenditure_amount": $last_expenditure_amount, "last_expenditure_date": $last_expenditure_date, "candidate_id": $candidate_id, "last_office_total_ytd": $last_office_total_ytd, "last_support_oppose_indicator": $last_support_oppose_indicator, "min_date": $min_date, "candidate_party": $candidate_party, "committee_id": $committee_id, "min_image_number": $min_image_number, "max_filing_date": $max_filing_date, "candidate_office_district": $candidate_office_district, "min_amount": $min_amount, "image_number": $image_number, "sort": $qp_sort, "max_date": $max_date, "most_recent": $most_recent} | compact), body: null}
}

# Schedule E receipts aggregated by recipient candidate. To avoid double counting, memoed items are not included.
#
# GET /schedules/schedule_e/by_candidate/
export def "schedules-schedule-e-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --office: string@office-completer-1 # Federal office candidate runs for: H, S or P
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --district: string # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --state: string # US state or territory where a candidate runs for office
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --support-oppose: string@support-oppose-completer # Support or opposition
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, candidate_name: string, committee_id: string, committee_name: string, count: int, cycle: int, support_oppose_indicator: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "office" $office "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "cycle" $cycle "multi") (serialize-qp "district" $district "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "support_oppose" $support_oppose "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_e/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"office": $office, "candidate_id": $candidate_id, "cycle": $cycle, "district": $district, "state": $state, "page": $page, "support_oppose": $support_oppose, "election_full": $election_full, "committee_id": $committee_id, "sort_hide_null": $sort_hide_null, "sort_nulls_last": $sort_nulls_last, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Efiling endpoints provide real-time campaign finance data received from electronic filers. Efiling endpoints only contain the most recent four months of data and don't contain the processed and coded data that you can find on other endpoints.
#
# GET /schedules/schedule_e/efile/
export def "schedules-schedule-e-efile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --spender-name: list<string> # The name of the committee. If a committee changes its name, the most recent name will be shown. Committee names are not unique. Use committee_id for looking up records.
  --min-expenditure-date: string # Selects all items expended by this committee after this date (format: date)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --max-dissemination-date: string # Selects all items distributed by this committee before this date (format: date)
  --support-oppose-indicator: list<string> # Explains if the money was spent in order to support or oppose a candidate or candidates. (Coded S or O for support or oppose.) This indicator applies to independent expenditures and communication costs.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --candidate-office: string@candidate-office-completer # Federal office candidate runs for: H, S or P
  --is-notice: oneof<nothing, bool> # Record filed as 24- or 48-hour notice.
  --payee-name: list<string> # Name of the entity that received the payment.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --candidate-search: list<string> # Search for candidates by candiate id or candidate first or last name
  --max-expenditure-amount: int # Selects all items expended by this committee less than this amount (format: int32)
  --min-dissemination-date: string # Selects all items distributed by this committee after this date (format: date)
  --min-filed-date: string # Timestamp of electronic or paper record that FEC received (format: date)
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --candidate-office-state: list<string> # US state or territory where a candidate runs for office
  --max-filed-date: string # Timestamp of electronic or paper record that FEC received (format: date)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-expenditure-amount: int # Selects all items expended by this committee greater than this amount (format: int32)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --candidate-party: list<string> # Three-letter code for the party affiliated with a candidate or committee. For example, DEM for Democratic Party and REP for Republican Party.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --max-expenditure-date: string # Selects all items expended by this committee before this date (format: date)
  --filing-form: list<string> # The form where the underlying data comes from, for example, Form 1 would appear as F1: - F1 Statement of Organization - F1M Notification of Multicandidate Status - F2 Statement of Candidacy - F3 Report of Receipts and Disbursements for an Authorized Committee - F3P Report of Receipts and Disbursements by an Authorized Committee of a Candidate for The Office of President or Vice President - F3L Report of Contributions Bundled by Lobbyists/Registrants and Lobbyist/Registrant PACs - F3X Report of Receipts and Disbursements for other than an Authorized Committee - F4 Report of Receipts and Disbursements for a Committee or Organization Supporting a Nomination Convention - F5 Report of Independent Expenditures Made and Contributions Received - F6 48 Hour Notice of Contributions/Loans Received - F7 Report of Communication Costs by Corporations and Membership Organizations - F8 Debt Settlement Plan - F9 24 Hour Notice of Disbursements for Electioneering Communications - F13 Report of Donations Accepted for Inaugural Committee - F99 Miscellaneous Text - FRQ Request for Additional Information
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --candidate-office-district: list<string> # Two-digit US House distirict of the office the candidate is running for. Presidential, Senate and House at-large candidates will have District 00.
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -expenditure_date)
  --most-recent: oneof<nothing, bool> # The report associated with the transaction is either new or is the most-recently filed amendment. Undetermined version (`null`) is always included.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<amendment_indicator: string, back_reference_schedule_name: string, back_reference_transaction_id: string, beginning_image_number: string, candidate_first_name: string, candidate_id: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_state: string, candidate_party: string, candidate_prefix: string, candidate_suffix: string, category_code: string, committee: record, committee_id: string, csv_url: string, dissemination_date: string, entity_type: string, expenditure_amount: int, expenditure_date: string, expenditure_description: string, fec_url: string, file_number: int, filer_first_name: string, filer_last_name: string, filer_middle_name: string, filer_prefix: string, filer_suffix: string, filing: record, filing_form: string, image_number: string, is_notice: bool, line_number: string, load_timestamp: string, memo_code: string, memo_text: string, most_recent: bool, notary_sign_date: string, office_total_ytd: float, payee_city: string, payee_first_name: string, payee_last_name: string, payee_middle_name: string, payee_name: string, payee_prefix: string, payee_state: string, payee_street_1: string, payee_street_2: string, payee_suffix: string, payee_zip: string, pdf_url: string, related_line_number: int, report_type: string, support_oppose_indicator: string, transaction_id: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spender_name" $spender_name "multi") (serialize-qp "min_expenditure_date" $min_expenditure_date "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "max_dissemination_date" $max_dissemination_date "scalar") (serialize-qp "support_oppose_indicator" $support_oppose_indicator "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "candidate_office" $candidate_office "scalar") (serialize-qp "is_notice" $is_notice "scalar") (serialize-qp "payee_name" $payee_name "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "candidate_search" $candidate_search "multi") (serialize-qp "max_expenditure_amount" $max_expenditure_amount "scalar") (serialize-qp "min_dissemination_date" $min_dissemination_date "scalar") (serialize-qp "min_filed_date" $min_filed_date "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "candidate_office_state" $candidate_office_state "multi") (serialize-qp "max_filed_date" $max_filed_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "min_expenditure_amount" $min_expenditure_amount "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "candidate_party" $candidate_party "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "max_expenditure_date" $max_expenditure_date "scalar") (serialize-qp "filing_form" $filing_form "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "candidate_office_district" $candidate_office_district "multi") (serialize-qp "image_number" $image_number "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "most_recent" $most_recent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_e/efile/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"spender_name": $spender_name, "min_expenditure_date": $min_expenditure_date, "sort_nulls_last": $sort_nulls_last, "max_dissemination_date": $max_dissemination_date, "support_oppose_indicator": $support_oppose_indicator, "sort_hide_null": $sort_hide_null, "candidate_office": $candidate_office, "is_notice": $is_notice, "payee_name": $payee_name, "per_page": $per_page, "candidate_search": $candidate_search, "max_expenditure_amount": $max_expenditure_amount, "min_dissemination_date": $min_dissemination_date, "min_filed_date": $min_filed_date, "candidate_id": $candidate_id, "candidate_office_state": $candidate_office_state, "max_filed_date": $max_filed_date, "page": $page, "min_expenditure_amount": $min_expenditure_amount, "committee_id": $committee_id, "candidate_party": $candidate_party, "api_key": $api_key, "max_expenditure_date": $max_expenditure_date, "filing_form": $filing_form, "sort_null_only": $sort_null_only, "candidate_office_district": $candidate_office_district, "image_number": $image_number, "sort": $qp_sort, "most_recent": $most_recent} | compact), body: null}
}

# Total independent expenditure on supported or opposed candidates by cycle or candidate election year.
#
# GET /schedules/schedule_e/totals/by_candidate/
export def "schedules-schedule-e-totals-by-candidate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --election-full: oneof<nothing, bool> # `True` indicates that full election period of a candidate. `False` indicates that two year election cycle. (default: true)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<candidate_id: string, cycle: int, support_oppose_indicator: string, total: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "election_full" $election_full "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_e/totals/by_candidate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"candidate_id": $candidate_id, "sort_nulls_last": $sort_nulls_last, "page": $page, "cycle": $cycle, "sort_hide_null": $sort_hide_null, "election_full": $election_full, "api_key": $api_key, "sort_null_only": $sort_null_only, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Schedule F, it shows all special expenditures a national or state party committee makes in connection with the general election campaigns of federal candidates. These coordinated party expenditures do not count against the contribution limits but are subject to other limits, these limits are detailed in Chapter 7 of the FEC Campaign Guide for Political Party Committees.
#
# GET /schedules/schedule_f/
export def "schedules-schedule-f list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-amount: string # Filter for all amounts less than a value.
  --max-image-number: string # Maxium image number of the page where the schedule item is reported
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --line-number: string # Filter for form and line number using the following format: `FORM-LINENUMBER`. For example an argument such as `F3X-16` would filter down to all entries from form `F3X` line number `16`.
  --payee-name: list<string>
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office.
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --min-date: string # Minimum date (format: date)
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --min-amount: string # Filter for all amounts greater than a value.
  --min-image-number: string # Minium image number of the page where the schedule item is reported
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --image-number: list<string> # An unique identifier for each page where the electronic or paper filing is reported.
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: expenditure_date)
  --max-date: string # Maximum date (format: date)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<action_code: string, action_code_full: string, aggregate_general_election_expenditure: string, back_reference_schedule_name: string, back_reference_transaction_id: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_full: string, candidate_office_state: string, candidate_office_state_full: string, candidate_prefix: string, candidate_suffix: string, catolog_code: string, catolog_code_full: string, committee: record, committee_designated_coordinated_expenditure_indicator: string, committee_id: string, committee_name: string, conduit_committee_city: string, conduit_committee_id: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, designated_committee_id: string, designated_committee_name: string, election_cycle: int, entity_type: string, entity_type_desc: string, expenditure_amount: int, expenditure_date: string, expenditure_purpose_full: string, expenditure_type: string, expenditure_type_full: string, file_number: int, filing_form: string, image_number: string, line_number: string, link_id: int, load_date: string, memo_code: string, memo_code_full: string, memo_text: string, original_sub_id: int, payee_first_name: string, payee_last_name: string, payee_middle_name: string, payee_name: string, pdf_url: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, sub_id: string, subordinate_committee: record, subordinate_committee_id: string, transaction_id: string, unlimited_spending_flag: string, unlimited_spending_flag_full: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "max_image_number" $max_image_number "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "line_number" $line_number "scalar") (serialize-qp "payee_name" $payee_name "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "candidate_id" $candidate_id "multi") (serialize-qp "page" $page "scalar") (serialize-qp "min_date" $min_date "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "min_image_number" $min_image_number "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "image_number" $image_number "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max_date" $max_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules/schedule_f/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_amount": $max_amount, "max_image_number": $max_image_number, "cycle": $cycle, "sort_nulls_last": $sort_nulls_last, "sort_hide_null": $sort_hide_null, "line_number": $line_number, "payee_name": $payee_name, "per_page": $per_page, "candidate_id": $candidate_id, "page": $page, "min_date": $min_date, "committee_id": $committee_id, "api_key": $api_key, "min_amount": $min_amount, "min_image_number": $min_image_number, "sort_null_only": $sort_null_only, "image_number": $image_number, "sort": $qp_sort, "max_date": $max_date} | compact), body: null}
}

# Schedule F, it shows all special expenditures a national or state party committee makes in connection with the general election campaigns of federal candidates. These coordinated party expenditures do not count against the contribution limits but are subject to other limits, these limits are detailed in Chapter 7 of the FEC Campaign Guide for Political Party Committees.
#
# GET /schedules/schedule_f/{sub_id}/
export def "schedules-schedule-f get" [
  sub_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<action_code: string, action_code_full: string, aggregate_general_election_expenditure: string, back_reference_schedule_name: string, back_reference_transaction_id: string, candidate_first_name: string, candidate_id: string, candidate_last_name: string, candidate_middle_name: string, candidate_name: string, candidate_office: string, candidate_office_district: string, candidate_office_full: string, candidate_office_state: string, candidate_office_state_full: string, candidate_prefix: string, candidate_suffix: string, catolog_code: string, catolog_code_full: string, committee: record, committee_designated_coordinated_expenditure_indicator: string, committee_id: string, committee_name: string, conduit_committee_city: string, conduit_committee_id: string, conduit_committee_name: string, conduit_committee_state: string, conduit_committee_street1: string, conduit_committee_street2: string, conduit_committee_zip: int, designated_committee_id: string, designated_committee_name: string, election_cycle: int, entity_type: string, entity_type_desc: string, expenditure_amount: int, expenditure_date: string, expenditure_purpose_full: string, expenditure_type: string, expenditure_type_full: string, file_number: int, filing_form: string, image_number: string, line_number: string, link_id: int, load_date: string, memo_code: string, memo_code_full: string, memo_text: string, original_sub_id: int, payee_first_name: string, payee_last_name: string, payee_middle_name: string, payee_name: string, pdf_url: string, report_type: string, report_year: int, schedule_type: string, schedule_type_full: string, sub_id: string, subordinate_committee: record, subordinate_committee_id: string, transaction_id: string, unlimited_spending_flag: string, unlimited_spending_flag_full: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($sub_id | is-empty) { error make --unspanned { msg: "path parameter 'sub_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sub_id: (encode-path-segment $sub_id)} | format pattern "/schedules/schedule_f/{sub_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"per_page": $per_page, "api_key": $api_key, "page": $page} | compact), body: null}
}

# State laws and procedures govern elections for state or local offices as well as how candidates appear on election ballots. Contact the appropriate state election office for more information.
#
# GET /state-election-office/
export def "state-election-office get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --state: string # Enter a state (Ex: AK, TX, VA etc..) to find the local election offices contact information.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<address_line1: string, address_line2: string, city: string, email: string, fax_number: string, mailing_address1: string, mailing_address2: string, mailing_city: string, mailing_state: string, mailing_zipcode: string, office_name: string, office_type: string, primary_phone_number: string, secondary_phone_number: string, state: string, state_full_name: string, website_url1: string, website_url2: string, zip_code: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/state-election-office/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort_null_only": $sort_null_only, "sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "state": $state, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "api_key": $api_key, "page": $page} | compact), body: null}
}

# Provides cumulative receipt totals by entity type, over a two year cycle. Totals are adjusted to avoid double counting. This is [the sql](https://github.com/fecgov/openFEC/blob/develop/data/migrations/V41__large_aggregates.sql) that creates these calculations.
#
# GET /totals/by_entity/
export def "totals-by-entity get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cycle: int # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year. (format: int32)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: end_date)
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<cumulative_candidate_disbursements: float, cumulative_candidate_receipts: float, cumulative_pac_disbursements: float, cumulative_pac_receipts: float, cumulative_party_disbursements: float, cumulative_party_receipts: float, cycle: int, end_date: string>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cycle" $cycle "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/totals/by_entity/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cycle": $cycle, "sort_nulls_last": $sort_nulls_last, "per_page": $per_page, "sort_null_only": $sort_null_only, "sort_hide_null": $sort_hide_null, "sort": $qp_sort, "api_key": $api_key, "page": $page} | compact), body: null}
}

# This endpoint provides information about a committee's Form 3, Form 3X, or Form 3P financial reports, which are aggregated by two-year period. We refer to two-year periods as a `cycle`. The cycle is named after the even-numbered year and includes the year before it. To obtain totals from 2013 and 2014, you would use 2014. In odd-numbered years, the current cycle is the next year — for example, in 2015, the current cycle is 2016. For presidential and Senate candidates, multiple two-year cycles exist between elections.
#
# GET /totals/{entity_type}/
export def "totals get" [
  entity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-apikeyheaderauth: string # Auth token for ApiKeyHeaderAuth (X-Api-Key)
  --token-apikeyqueryauth: string # Auth token for ApiKeyQueryAuth (api_key)
  --token-apikey: string # Auth token for apiKey (api_key)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-first-f1-date: string # Filter for committees whose first Form 1 was received on or before this date. (format: date)
  --min-receipts: string # Filter for all amounts greater than a value.
  --cycle: list<int> # Filter records to only those that were applicable to a given two-year period.The cycle begins with an odd year and is named for its ending, even year.
  --filing-frequency: list<string> # The one-letter code of the filing frequency: - A Administratively terminated - D Debt - M Monthly filer - Q Quarterly filer - T Terminated - W Waived
  --max-receipts: string # Filter for all amounts less than a value.
  --sort-hide-null: oneof<nothing, bool> # Hide null values on sorted column(s). (default: false)
  --sort-nulls-last: oneof<nothing, bool> # Toggle that sorts null values last (default: false)
  --min-last-debts-owed-by-committee: string # Filter for all amounts greater than a value.
  --max-last-cash-on-hand-end-period: string # Filter for all amounts less than a value.
  --treasurer-name: list<string> # Name of the Committee's treasurer. If multiple treasurers for the committee, the most recent treasurer will be shown.
  --sponsor-candidate-id: list<string> # A unique identifier assigned to each candidate registered with the FEC. If a person runs for several offices, that person will have separate candidate IDs for each office. This is a filter for Leadership PAC sponsor.
  --per-page: int # The number of results returned per page. Defaults to 20. (format: int32, default: 20)
  --max-disbursements: string # Filter for all amounts less than a value.
  --committee-state: list<string> # US state or territory
  --committee-type: list<string> # The one-letter type code of the organization: - C communication cost - D delegate - E electioneering communication - H House - I independent expenditure filer (not a committee) - N PAC - nonqualified - O independent expenditure-only (super PACs) - P presidential - Q PAC - qualified - S Senate - U single candidate independent expenditure - V PAC with non-contribution account, nonqualified - W PAC with non-contribution account, qualified - X party, nonqualified - Y party, qualified - Z national party non-federal account
  --page: int # For paginating through results, starting at page 1 (format: int32, default: 1)
  --max-last-debts-owed-by-committee: string # Filter for all amounts less than a value.
  --committee-id: list<string> # A unique identifier assigned to each committee or filer registered with the FEC. In general committee id's begin with the letter C which is followed by eight digits.
  --api-key: string # API key for https://api.data.gov. Get one at https://api.data.gov/signup. (default: DEMO_KEY)
  --committee-designation: list<string> # The one-letter designation code of the organization: - A authorized by a candidate - J joint fundraising committee - P principal campaign committee of a candidate - U unauthorized - B lobbyist/registrant PAC - D leadership PAC
  --sort-null-only: oneof<nothing, bool> # Toggle that filters out all rows having sort column that is non-null (default: false)
  --min-first-f1-date: string # Filter for committees whose first Form 1 was received on or after this date. (format: date)
  --organization-type: list<string> # The one-letter code for the kind for organization: - C corporation - L labor organization - M membership organization - T trade association - V cooperative - W corporation without capital stock
  --qp-sort: string # Provide a field to sort by. Use `-` for descending order. (default: -cycle)
  --min-disbursements: string # Filter for all amounts greater than a value.
  --min-last-cash-on-hand-end-period: string # Filter for all amounts greater than a value.
]: nothing -> record<pagination: record<count: int, page: int, pages: int, per_page: int>, results: table<all_loans_received: float, all_other_loans: float, allocated_federal_election_levin_share: float, candidate_contribution: float, cash_on_hand_beginning_period: float, committee_designation: string, committee_designation_full: string, committee_id: string, committee_name: string, committee_state: string, committee_type: string, committee_type_full: string, contribution_refunds: float, contributions: float, contributions_ie_and_party_expenditures_made_percent: float, convention_exp: float, coordinated_expenditures_by_party_committee: float, coverage_end_date: string, coverage_start_date: string, cycle: int, disbursements: float, exempt_legal_accounting_disbursement: float, exp_prior_years_subject_limits: float, exp_subject_limits: float, fed_candidate_committee_contributions: float, fed_candidate_contribution_refunds: float, fed_disbursements: float, fed_election_activity: float, fed_operating_expenditures: float, fed_receipts: float, federal_funds: float, filing_frequency: string, filing_frequency_full: string, first_f1_date: string, first_file_date: string, fundraising_disbursements: float, independent_expenditures: float, individual_contributions: float, individual_contributions_percent: float, individual_itemized_contributions: float, individual_unitemized_contributions: float, itemized_convention_exp: float, itemized_other_disb: float, itemized_other_income: float, itemized_other_refunds: float, itemized_refunds_relating_convention_exp: float, last_beginning_image_number: string, last_cash_on_hand_end_period: float, last_debts_owed_by_committee: float, last_debts_owed_to_committee: float, last_report_type_full: string, last_report_year: int, loan_repayments: float, loan_repayments_candidate_loans: float, loan_repayments_made: float, loan_repayments_other_loans: float, loan_repayments_received: float, loans: float, loans_and_loan_repayments_made: float, loans_and_loan_repayments_received: float, loans_made: float, loans_made_by_candidate: float, loans_received: float, loans_received_from_candidate: float, net_contributions: float, net_operating_expenditures: float, non_allocated_fed_election_activity: float, offsets_to_fundraising_expenditures: float, offsets_to_legal_accounting: float, offsets_to_operating_expenditures: float, operating_expenditures: float, operating_expenditures_percent: float, organization_type: string, organization_type_full: string, other_disbursements: float, other_fed_operating_expenditures: float, other_fed_receipts: float, other_loans_received: float, other_political_committee_contributions: float, other_receipts: float, other_refunds: float, party_and_other_committee_contributions_percent: float, party_full: string, pdf_url: string, political_party_committee_contributions: float, receipts: float, refunded_individual_contributions: float, refunded_other_political_committee_contributions: float, refunded_political_party_committee_contributions: float, refunds_relating_convention_exp: float, repayments_loans_made_by_candidate: float, repayments_other_loans: float, report_form: string, shared_fed_activity: float, shared_fed_activity_nonfed: float, shared_fed_operating_expenditures: float, shared_nonfed_operating_expenditures: float, total_exp_subject_limits: float, total_independent_contributions: float, total_independent_expenditures: float, total_offsets_to_operating_expenditures: float, total_transfers: float, transaction_coverage_date: string, transfers_from_affiliated_committee: float, transfers_from_affiliated_party: float, transfers_from_nonfed_account: float, transfers_from_nonfed_levin: float, transfers_from_other_authorized_committee: float, transfers_to_affiliated_committee: float, transfers_to_other_authorized_committee: float, treasurer_name: string, unitemized_convention_exp: float, unitemized_other_disb: float, unitemized_other_income: float, unitemized_other_refunds: float, unitemized_refunds_relating_convention_exp: float>> {
  let auth = (merge-auth [(build-auth ($token_apikeyheaderauth | default ($env | get -o OPENFEC_APIKEYHEADERAUTH_TOKEN | default "")) "x-api-key") (build-auth ($token_apikeyqueryauth | default ($env | get -o OPENFEC_APIKEYQUERYAUTH_TOKEN | default "")) "query-api_key") (build-auth ($token_apikey | default ($env | get -o OPENFEC_APIKEY_TOKEN | default "")) "query-api_key")])
  let base = ($base_url | default $BASE_URL)
  if ($entity_type | is-empty) { error make --unspanned { msg: "path parameter 'entity_type' must be non-empty" } }
  let qp = [(serialize-qp "max_first_f1_date" $max_first_f1_date "scalar") (serialize-qp "min_receipts" $min_receipts "scalar") (serialize-qp "cycle" $cycle "multi") (serialize-qp "filing_frequency" $filing_frequency "multi") (serialize-qp "max_receipts" $max_receipts "scalar") (serialize-qp "sort_hide_null" $sort_hide_null "scalar") (serialize-qp "sort_nulls_last" $sort_nulls_last "scalar") (serialize-qp "min_last_debts_owed_by_committee" $min_last_debts_owed_by_committee "scalar") (serialize-qp "max_last_cash_on_hand_end_period" $max_last_cash_on_hand_end_period "scalar") (serialize-qp "treasurer_name" $treasurer_name "multi") (serialize-qp "sponsor_candidate_id" $sponsor_candidate_id "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "max_disbursements" $max_disbursements "scalar") (serialize-qp "committee_state" $committee_state "multi") (serialize-qp "committee_type" $committee_type "multi") (serialize-qp "page" $page "scalar") (serialize-qp "max_last_debts_owed_by_committee" $max_last_debts_owed_by_committee "scalar") (serialize-qp "committee_id" $committee_id "multi") (serialize-qp "api_key" $api_key "scalar") (serialize-qp "committee_designation" $committee_designation "multi") (serialize-qp "sort_null_only" $sort_null_only "scalar") (serialize-qp "min_first_f1_date" $min_first_f1_date "scalar") (serialize-qp "organization_type" $organization_type "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "min_disbursements" $min_disbursements "scalar") (serialize-qp "min_last_cash_on_hand_end_period" $min_last_cash_on_hand_end_period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_type: (encode-path-segment $entity_type)} | format pattern "/totals/{entity_type}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max_first_f1_date": $max_first_f1_date, "min_receipts": $min_receipts, "cycle": $cycle, "filing_frequency": $filing_frequency, "max_receipts": $max_receipts, "sort_hide_null": $sort_hide_null, "sort_nulls_last": $sort_nulls_last, "min_last_debts_owed_by_committee": $min_last_debts_owed_by_committee, "max_last_cash_on_hand_end_period": $max_last_cash_on_hand_end_period, "treasurer_name": $treasurer_name, "sponsor_candidate_id": $sponsor_candidate_id, "per_page": $per_page, "max_disbursements": $max_disbursements, "committee_state": $committee_state, "committee_type": $committee_type, "page": $page, "max_last_debts_owed_by_committee": $max_last_debts_owed_by_committee, "committee_id": $committee_id, "api_key": $api_key, "committee_designation": $committee_designation, "sort_null_only": $sort_null_only, "min_first_f1_date": $min_first_f1_date, "organization_type": $organization_type, "sort": $qp_sort, "min_disbursements": $min_disbursements, "min_last_cash_on_hand_end_period": $min_last_cash_on_hand_end_period} | compact), body: null}
}
