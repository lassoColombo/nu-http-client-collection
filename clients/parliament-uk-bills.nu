# Auto-generated client for Bills API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/bills/v1/openapi.json
# Auth: --token flag or $env.BILLS_API_TOKEN

const BASE_URL = "https://bills-api.parliament.uk"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BILLS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://bills-api.parliament.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def category-completer [] { ["Hybrid" "Private" "Public"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def current-house-completer [] { ["All" "Commons" "Lords" "Unassigned"] }
def originating-house-completer [] { ["All" "Commons" "Lords"] }
def sort-order-completer [] { ["DateUpdatedAscending" "DateUpdatedDescending" "TitleAscending" "TitleDescending"] }
def decision-completer [] { ["Agreed" "All" "Disagreed" "NoDecision" "NotMoved" "Withdrawn"] }
def house-completer [] { ["All" "Commons" "Lords" "Unassigned"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bill-types get" } } | get name | first)
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

# Returns a list of Bill types.
#
# GET /api/v1/BillTypes
export def "bill-types get" [
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
  --category: string@category-completer
  --skip: int # format: int32
  --take: int # format: int32
]: nothing -> record<items: table<category: string, description: string, id: int, name: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "Skip" $skip "scalar") (serialize-qp "Take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/BillTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Category": $category, "Skip": $skip, "Take": $take} | compact), body: null}
}

# Returns a list of Bills.
#
# GET /api/v1/Bills
# operationId: GetBills
export def "bills list" [
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
  --search-term: string
  --session: int # format: int32
  --current-house: string@current-house-completer
  --originating-house: string@originating-house-completer
  --member-id: int # format: int32
  --department-id: int # format: int32
  --bill-stage: list<int>
  --bill-stages-excluded: list<int>
  --is-defeated: oneof<nothing, bool>
  --is-withdrawn: oneof<nothing, bool>
  --bill-type: list<int>
  --sort-order: string@sort-order-completer
  --bill-ids: list<int>
  --skip: int # format: int32
  --take: int # format: int32
]: nothing -> record<items: table<billId: int, billTypeId: int, billWithdrawn: string, currentHouse: string, currentStage: record, includedSessionIds: list, introducedSessionId: int, isAct: bool, isDefeated: bool, lastUpdate: string, originatingHouse: string, shortTitle: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SearchTerm" $search_term "scalar") (serialize-qp "Session" $session "scalar") (serialize-qp "CurrentHouse" $current_house "scalar") (serialize-qp "OriginatingHouse" $originating_house "scalar") (serialize-qp "MemberId" $member_id "scalar") (serialize-qp "DepartmentId" $department_id "scalar") (serialize-qp "BillStage" $bill_stage "multi") (serialize-qp "BillStagesExcluded" $bill_stages_excluded "multi") (serialize-qp "IsDefeated" $is_defeated "scalar") (serialize-qp "IsWithdrawn" $is_withdrawn "scalar") (serialize-qp "BillType" $bill_type "multi") (serialize-qp "SortOrder" $sort_order "scalar") (serialize-qp "BillIds" $bill_ids "multi") (serialize-qp "Skip" $skip "scalar") (serialize-qp "Take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Bills" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SearchTerm": $search_term, "Session": $session, "CurrentHouse": $current_house, "OriginatingHouse": $originating_house, "MemberId": $member_id, "DepartmentId": $department_id, "BillStage": $bill_stage, "BillStagesExcluded": $bill_stages_excluded, "IsDefeated": $is_defeated, "IsWithdrawn": $is_withdrawn, "BillType": $bill_type, "SortOrder": $sort_order, "BillIds": $bill_ids, "Skip": $skip, "Take": $take} | compact), body: null}
}

# Return a Bill.
#
# GET /api/v1/Bills/{billId}
# operationId: GetBill
export def "bills get" [
  bill_id: int
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
]: nothing -> record<agent: record<address: string, email: string, name: string, phoneNo: string, website: string>, billId: int, billTypeId: int, billWithdrawn: string, currentHouse: string, currentStage: record<abbreviation: string, description: string, house: string, id: int, sessionId: int, sortOrder: int, stageId: int, stageSittings: list<record>>, includedSessionIds: list<int>, introducedSessionId: int, isAct: bool, isDefeated: bool, lastUpdate: string, longTitle: string, originatingHouse: string, petitionInformation: string, petitioningPeriod: string, promoters: table<organisationName: string, organisationUrl: string>, shortTitle: string, sponsors: table<member: record, organisation: record, sortOrder: int>, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let full_url = (build-url $base ({bill_id: (encode-path-segment $bill_id)} | format pattern "/api/v1/Bills/{bill_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of news articles for a Bill.
#
# GET /api/v1/Bills/{billId}/NewsArticles
# operationId: GetNewsArticles
export def "bills-news-articles get" [
  bill_id: int
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
  --skip: int # format: int32
  --take: int # format: int32
]: nothing -> record<items: table<content: string, displayDate: string, id: int, title: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let qp = [(serialize-qp "Skip" $skip "scalar") (serialize-qp "Take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bill_id: (encode-path-segment $bill_id)} | format pattern "/api/v1/Bills/{bill_id}/NewsArticles") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Skip": $skip, "Take": $take} | compact), body: null}
}

# Return a list of Bill publications.
#
# GET /api/v1/Bills/{billId}/Publications
# operationId: GetBillPublication
export def "bills-publications get" [
  bill_id: int
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
]: nothing -> record<billId: int, publications: table<displayDate: string, files: list, house: string, id: int, links: list, publicationType: record, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let full_url = (build-url $base ({bill_id: (encode-path-segment $bill_id)} | format pattern "/api/v1/Bills/{bill_id}/Publications"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns all Bill stages.
#
# GET /api/v1/Bills/{billId}/Stages
export def "bills-stages get" [
  bill_id: int
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
  --skip: int # format: int32
  --take: int # format: int32
]: nothing -> record<items: table<abbreviation: string, description: string, house: string, id: int, sessionId: int, sortOrder: int, stageId: int, stageSittings: list>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let qp = [(serialize-qp "Skip" $skip "scalar") (serialize-qp "Take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bill_id: (encode-path-segment $bill_id)} | format pattern "/api/v1/Bills/{bill_id}/Stages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Skip": $skip, "Take": $take} | compact), body: null}
}

# Returns a Bill stage.
#
# GET /api/v1/Bills/{billId}/Stages/{billStageId}
# operationId: GetBillStageDetails
export def "bills-stages get-details" [
  bill_id: int
  bill_stage_id: int
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
]: nothing -> record<abbreviation: string, committee: record<category: string, house: string, id: int, name: string, url: string>, description: string, house: string, id: int, lastUpdate: string, nextStageBillStageId: int, previousStageBillStageId: int, sessionId: int, sortOrder: int, stageId: int, stageSittings: table<billId: int, billStageId: int, date: string, id: int, stageId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  if ($bill_stage_id | is-empty) { error make --unspanned { msg: "path parameter 'billStageId' must be non-empty" } }
  let full_url = (build-url $base ({bill_id: (encode-path-segment $bill_id), bill_stage_id: (encode-path-segment $bill_stage_id)} | format pattern "/api/v1/Bills/{bill_id}/Stages/{bill_stage_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of amendments.
#
# GET /api/v1/Bills/{billId}/Stages/{billStageId}/Amendments
# operationId: GetAmendments
export def "bills-stages-amendments list" [
  bill_id: int
  bill_stage_id: int
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
  --search-term: string
  --decision: string@decision-completer
  --member-id: int # format: int32
  --skip: int # format: int32
  --take: int # format: int32
]: nothing -> record<items: table<amendmentId: int, amendmentPosition: string, amendmentType: string, billId: int, billStageId: int, clause: int, decision: string, lineNumber: int, marshalledListText: string, pageNumber: int, schedule: int, sponsors: list, summaryText: list>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  if ($bill_stage_id | is-empty) { error make --unspanned { msg: "path parameter 'billStageId' must be non-empty" } }
  let qp = [(serialize-qp "SearchTerm" $search_term "scalar") (serialize-qp "Decision" $decision "scalar") (serialize-qp "MemberId" $member_id "scalar") (serialize-qp "Skip" $skip "scalar") (serialize-qp "Take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bill_id: (encode-path-segment $bill_id), bill_stage_id: (encode-path-segment $bill_stage_id)} | format pattern "/api/v1/Bills/{bill_id}/Stages/{bill_stage_id}/Amendments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SearchTerm": $search_term, "Decision": $decision, "MemberId": $member_id, "Skip": $skip, "Take": $take} | compact), body: null}
}

# Returns an amendment.
#
# GET /api/v1/Bills/{billId}/Stages/{billStageId}/Amendments/{amendmentId}
# operationId: GetAmendment
export def "bills-stages-amendments get" [
  bill_id: int
  bill_stage_id: int
  amendment_id: int
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
]: nothing -> record<amendmentId: int, amendmentLines: table<hangingIndentation: string, imageType: string, indentation: int, isImage: bool, text: string>, amendmentNote: string, amendmentPosition: string, amendmentType: string, billId: int, billStageId: int, clause: int, decision: string, explanatoryText: string, explanatoryTextPrefix: string, lineNumber: int, marshalledListText: string, pageNumber: int, schedule: int, sponsors: table<house: string, isLead: bool, memberFrom: string, memberId: int, memberPage: string, memberPhoto: string, name: string, party: string, partyColour: string, sortOrder: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  if ($bill_stage_id | is-empty) { error make --unspanned { msg: "path parameter 'billStageId' must be non-empty" } }
  if ($amendment_id | is-empty) { error make --unspanned { msg: "path parameter 'amendmentId' must be non-empty" } }
  let full_url = (build-url $base ({bill_id: (encode-path-segment $bill_id), bill_stage_id: (encode-path-segment $bill_stage_id), amendment_id: (encode-path-segment $amendment_id)} | format pattern "/api/v1/Bills/{bill_id}/Stages/{bill_stage_id}/Amendments/{amendment_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return a list of Bill stage publications.
#
# GET /api/v1/Bills/{billId}/Stages/{stageId}/Publications
export def "bills-stages-publications get" [
  bill_id: int
  stage_id: int
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
]: nothing -> record<billStageId: int, publications: table<displayDate: string, files: list, id: int, links: list, publicationType: record, title: string>, sittings: table<publications: list, sittingId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  if ($stage_id | is-empty) { error make --unspanned { msg: "path parameter 'stageId' must be non-empty" } }
  let full_url = (build-url $base ({bill_id: (encode-path-segment $bill_id), stage_id: (encode-path-segment $stage_id)} | format pattern "/api/v1/Bills/{bill_id}/Stages/{stage_id}/Publications"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of publication types.
#
# GET /api/v1/PublicationTypes
export def "publication-types get" [
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
  --skip: int # format: int32
  --take: int # format: int32
]: nothing -> record<items: table<description: string, id: int, name: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Skip" $skip "scalar") (serialize-qp "Take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/PublicationTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Skip": $skip, "Take": $take} | compact), body: null}
}

# Return information on a document.
#
# GET /api/v1/Publications/{publicationId}/Documents/{documentId}
export def "publications-documents get" [
  publication_id: int
  document_id: int
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
]: nothing -> record<contentLength: int, contentType: string, filename: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($publication_id | is-empty) { error make --unspanned { msg: "path parameter 'publicationId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({publication_id: (encode-path-segment $publication_id), document_id: (encode-path-segment $document_id)} | format pattern "/api/v1/Publications/{publication_id}/Documents/{document_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return a document.
#
# GET /api/v1/Publications/{publicationId}/Documents/{documentId}/Download
export def "publications-documents-download get" [
  publication_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($publication_id | is-empty) { error make --unspanned { msg: "path parameter 'publicationId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({publication_id: (encode-path-segment $publication_id), document_id: (encode-path-segment $document_id)} | format pattern "/api/v1/Publications/{publication_id}/Documents/{document_id}/Download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns an Rss feed of a certain Bill.
#
# GET /api/v1/Rss/Bills/{id}.rss
export def "rss-bills get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/Rss/Bills/{id}.rss"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns an Rss feed of all Bills.
#
# GET /api/v1/Rss/allbills.rss
export def "rss-allbills-rss get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Rss/allbills.rss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns an Rss feed of private Bills.
#
# GET /api/v1/Rss/privatebills.rss
export def "rss-privatebills-rss get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Rss/privatebills.rss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns an Rss feed of public Bills.
#
# GET /api/v1/Rss/publicbills.rss
export def "rss-publicbills-rss get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Rss/publicbills.rss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of Sittings.
#
# GET /api/v1/Sittings
# operationId: GetSittings
export def "sittings get" [
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
  --house: string@house-completer
  --date-from: string # format: date-time
  --date-to: string # format: date-time
  --skip: int # format: int32
  --take: int # format: int32
]: nothing -> record<items: table<billId: int, billStageId: int, date: string, id: int, stageId: int>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "House" $house "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "Skip" $skip "scalar") (serialize-qp "Take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Sittings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"House": $house, "DateFrom": $date_from, "DateTo": $date_to, "Skip": $skip, "Take": $take} | compact), body: null}
}

# Returns a list of Bill stages.
#
# GET /api/v1/Stages
export def "stages get" [
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
  --skip: int # format: int32
  --take: int # format: int32
]: nothing -> record<items: table<house: string, id: int, name: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Skip" $skip "scalar") (serialize-qp "Take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Stages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Skip": $skip, "Take": $take} | compact), body: null}
}
