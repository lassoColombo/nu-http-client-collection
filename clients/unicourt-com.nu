# Auto-generated client for UniCourt Enterprise APIs v1.0.0
# Source: https://api.apis.guru/v2/specs/unicourt.com/1.0.0/openapi.json
# Auth: --token flag or $env.UNICOURT_ENTERPRISE_APIS_TOKEN

const BASE_URL = "https://enterpriseapi.unicourt.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o UNICOURT_ENTERPRISE_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://enterpriseapi.unicourt.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["COMPLETE" "FAILURE" "IN_PROGRESS"] }
def sort-by-completer [] { ["latest to oldest" "oldest to latest"] }
def party-classification-type-completer [] { ["COMPANY" "INDIVIDUAL" "OTHER"] }
def group-by-completer [] { ["Monthly" "Quarterly" "Weekly" "Yearly"] }
def sort-completer [] { ["filedDate" "relevancy"] }
def order-completer [] { ["asc" "desc"] }
def sort-completer-1 [] { ["name"] }
def sort-completer-2 [] { ["state"] }
def case-status-completer [] { ["closed" "open"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "attorney get" } } | get name | first)
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

# Gets details for a requested Attorney ID.
#
# GET /attorney/{attorneyId}
# operationId: getAttorneyById
export def "attorney get" [
  attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyId: string, attorneyLawFirmArray: table<attorneyLawFirmId: string, firstFetchDate: string, isVisible: bool, lastFetchDate: string, name: string, object: string>, attorneyType: record<attorneyTypeId: string, createdDate: string, name: string, object: string>, barNumber: string, contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: list<record>, totalCount: int, totalPages: int>, partyRoleGroupIdArray: list<string>, partyRoleIdArray: list<string>, possibleNormAttorneyArray: table<associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, confidenceScore: float, normAttorneyAPI: string, normAttorneyId: string, normAttorneyName: string, object: string, scoreConstituents: record>, possibleNormLawFirmArray: table<associatedNormAttorneyAPI: string, associatedNormJudgeAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, confidenceScore: float, normLawFirmAPI: string, normLawFirmId: string, normLawFirmName: string, object: string, scoreConstituents: record, sourceDetails: record>, sourceAttorneyType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($attorney_id | is-empty) { error make --unspanned { msg: "path parameter 'attorneyId' must be non-empty" } }
  let full_url = (build-url $base ({attorney_id: (encode-path-segment $attorney_id)} | format pattern "/attorney/{attorney_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets Associated Party details for a requested Attorney ID.
#
# GET /attorney/{attorneyId}/associatedParties
# operationId: getAttorneyAssociatedParties
export def "attorney-associated-parties get" [
  attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: table<attorneyId: string, isVisible: bool, object: string, partyAttorneyAssociationId: string, partyId: string>, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($attorney_id | is-empty) { error make --unspanned { msg: "path parameter 'attorneyId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attorney_id: (encode-path-segment $attorney_id)} | format pattern "/attorney/{attorney_id}/associatedParties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}

# Specify the billing cycle to know the API usage.
#
# GET /billingCycleUsage/{billingCycle}
# operationId: getBillingUsageByBillingCycle
export def "billing-cycle-usage get" [
  billing_cycle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiCallsBillable: record<count: int, lastUpdated: string>, apiCallsCredited: record<count: int, lastUpdated: string>, apiCallsMade: record<count: int, lastUpdated: string>, apiUsage: record, billingCycle: record<endDate: string, startDate: string>, days: record, object: string, totalCasesTracked: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($billing_cycle | is-empty) { error make --unspanned { msg: "path parameter 'billingCycle' must be non-empty" } }
  let full_url = (build-url $base ({billing_cycle: (encode-path-segment $billing_cycle)} | format pattern "/billingCycleUsage/{billing_cycle}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the previous 12 billing cycles.
#
# GET /billingCycles
# operationId: getBillingCycles
export def "billing-cycles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billingCycleArray: list<string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billingCycles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of callback types with count for a requested Date.
#
# GET /callbacks
# operationId: getCallbacks
export def "callbacks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date for which fetch the callback type list. By default, the date will be set to current date. (format: date-time)
  --status: string@status-completer # Status of the callbacks. Default status will fetch all callbacks.
]: nothing -> record<caseDocumentOrderCallbacks: record<count: int, link: string>, caseExportCallbacks: record<count: int, link: string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/callbacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date": $date, "status": $status} | compact), body: null}
}

# Gets case information for a requested Case ID.
#
# GET /case/{caseId}
# operationId: getCase
export def "case get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneys: record<attorneyArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list<string>, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: table<causeOfAction: record, causeOfActionAdditionalDataArray: list, object: string>, chargeArray: table<charge: record, chargeAdditionalDataArray: list, chargeDegree: record, chargeSeverity: record, object: string>, court: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list<record>, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list<record>, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list<record>, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list<record>, sourceChargeArray: list<record>, sourceCourt: string, sourcePageData: list<record>>, sourceDataStatus: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets Attorneys for a requested Case ID.
#
# GET /case/{caseId}/attorneys
# operationId: getCaseAttorneys
export def "case-attorneys get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-visible: oneof<nothing, bool> # Retrieve attorneys in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<attorneyArray: table<attorneyId: string, attorneyLawFirmArray: list, attorneyType: record, barNumber: string, contact: record, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record, partyRoleGroupIdArray: list, partyRoleIdArray: list, possibleNormAttorneyArray: list, possibleNormLawFirmArray: list, sourceAttorneyType: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "isVisible" $is_visible "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/attorneys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isVisible": $is_visible, "pageNumber": $page_number} | compact), body: null}
}

# Gets Docket Entries for a requested Case ID.
#
# GET /case/{caseId}/docketEntries
# operationId: getCaseDocketEntries
export def "case-docket-entries get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --docket-number: int # Retrieve the docket entry witih the specified docket number in the case with the specified caseId value.
  --sort-by: string@sort-by-completer # Sort the retrieved docket entries in ascending order or descending order of date.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<docketEntryArray: table<boundary: string, docketBadge: string, docketEntryDate: string, docketEntryPrimaryDocuments: record, docketEntrySecondaryDocuments: record, docketNumber: int, lastFetchDate: string, object: string, referencedDocketNumberArray: list, sortOrder: int, text: string, textStructured: record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "docketNumber" $docket_number "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/docketEntries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"docketNumber": $docket_number, "sortBy": $sort_by, "pageNumber": $page_number} | compact), body: null}
}

# Gets Primary Documents of Docket Entries.
#
# GET /case/{caseId}/docketEntries/primaryDocuments
# operationId: getPrimaryDocumentsForDocketEntries
export def "case-docket-entries-primary-documents get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --docket-number: int # Retrieve the primary documents associated with the specified docket number in the case with the specified caseId value.
  --in-library: oneof<nothing, bool> # Retrieve the primary documents in the with the specified inLibrary flag in the case with the specified caseId value. (allows empty value)
  --after-first-fetch-date: string # Retrieve all primary documents in the case with the specified caseId value that were first fetched by UniCourt on the specified date or within the specified date. (nullable, format: date-time)
  --library-date: string # Retrieve all primary documents in the case with the specified caseId value that were added to the Crowdsourced Library on the specified date or within the specified date. (nullable, format: date-time)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "docketNumber" $docket_number "scalar") (serialize-qp "inLibrary" $in_library "scalar") (serialize-qp "afterFirstFetchDate" $after_first_fetch_date "scalar") (serialize-qp "libraryDate" $library_date "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/docketEntries/primaryDocuments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"docketNumber": $docket_number, "inLibrary": $in_library, "afterFirstFetchDate": $after_first_fetch_date, "libraryDate": $library_date, "pageNumber": $page_number} | compact), body: null}
}

# Gets Secondary Documents of Docket Entries.
#
# GET /case/{caseId}/docketEntries/secondaryDocuments
# operationId: getSecondaryDocumentsForDocketEntries
export def "case-docket-entries-secondary-documents get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --docket-number: int # Retrieve the secondary documents associated with the specified docket number in the case with the specified caseId value.
  --in-library: oneof<nothing, bool> # Retrieve the secondary documents in the with the specified inLibrary flag in the case with the specified caseId value. (allows empty value)
  --after-first-fetch-date: string # Retrieve all secondary documents in the case with the specified caseId value that were first fetched by UniCourt on the specified date or within the specified date. (nullable, format: date-time)
  --library-date: string # Retrieve all secondary documents in the case with the specified caseId value that were added to the Crowdsourced Library on the specified date or within the specified date. (nullable, format: date-time)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "docketNumber" $docket_number "scalar") (serialize-qp "inLibrary" $in_library "scalar") (serialize-qp "afterFirstFetchDate" $after_first_fetch_date "scalar") (serialize-qp "libraryDate" $library_date "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/docketEntries/secondaryDocuments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"docketNumber": $docket_number, "inLibrary": $in_library, "afterFirstFetchDate": $after_first_fetch_date, "libraryDate": $library_date, "pageNumber": $page_number} | compact), body: null}
}

# Gets Documents for a requested Case ID.
#
# GET /case/{caseId}/documents
# operationId: getCaseDocuments
export def "case-documents get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --in-library: oneof<nothing, bool> # Filter all the documents those are added to the UniCourt library. (allows empty value)
  --after-first-fetch-date: string # Get all the documents which were added to the case on or after a specific date. (nullable, format: date-time)
  --library-date: string # Sort all the documents based on the date when the document was added to the UniCourt Library. (nullable, format: date-time)
  --first-fetch-date: string # Sort all the documents based on the date it was fetched from the source site. (nullable, format: date-time)
  --sort-by: string@sort-by-completer # Sort documents with document order.
  --page-number: int # The page for which the result should be retrieved.
]: nothing -> record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "inLibrary" $in_library "scalar") (serialize-qp "afterFirstFetchDate" $after_first_fetch_date "scalar") (serialize-qp "libraryDate" $library_date "scalar") (serialize-qp "firstFetchDate" $first_fetch_date "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"inLibrary": $in_library, "afterFirstFetchDate": $after_first_fetch_date, "libraryDate": $library_date, "firstFetchDate": $first_fetch_date, "sortBy": $sort_by, "pageNumber": $page_number} | compact), body: null}
}

# Gets Hearings for a requested Case ID.
#
# GET /case/{caseId}/hearings
# operationId: getCaseHearings
export def "case-hearings get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer # Specify the sort order of hearings in the case with the specified caseId.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. (e.g. 1)
]: nothing -> record<hearingArray: table<firstFetchDate: string, hearingDate: string, hearingDescription: string, hearingStructured: record, lastFetchDate: string, location: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/hearings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sortBy": $sort_by, "pageNumber": $page_number} | compact), body: null}
}

# Gets Judges for a requested Case ID.
#
# GET /case/{caseId}/judges
# operationId: getCaseJudges
export def "case-judges get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-visible: oneof<nothing, bool> # Retrieve attorneys judges in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<judgeArray: table<contact: record, firstFetchDate: string, firstName: string, isVisible: bool, judgeId: string, judgeType: record, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, possibleNormJudgeArray: list, sourceJudgeType: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "isVisible" $is_visible "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/judges") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isVisible": $is_visible, "pageNumber": $page_number} | compact), body: null}
}

# Gets Parties for a requested Case ID.
#
# GET /case/{caseId}/parties
# operationId: getCaseParties
export def "case-parties get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-visible: oneof<nothing, bool> # Retrieve parties in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
  --party-role-id: string # Retrieve all parties with the specified partyRoleId value in the case with the specified caseId value. (allows empty value)
  --party-role-group-id: string # Retrieve all parties with the specified partyRoleGroupId value in the case with the specified caseId value. (allows empty value)
  --attorney-representation-type-id: string # Retrieve all parties with the specified attorneyRepresentationTypeId value in the case with the specified caseId value. (allows empty value)
  --party-classification-type: string@party-classification-type-completer # Retrieve all parties with the specified partyClassificationType value in the case with the specified caseId value. (allows empty value)
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyArray: table<attorneyRepresentationType: record, contact: record, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record, partyClassificationType: string, partyId: string, partyRole: record, possibleNormPartyArray: list, sourcePartyRole: string>, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "isVisible" $is_visible "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "partyRoleId" $party_role_id "scalar") (serialize-qp "partyRoleGroupId" $party_role_group_id "scalar") (serialize-qp "attorneyRepresentationTypeId" $attorney_representation_type_id "scalar") (serialize-qp "partyClassificationType" $party_classification_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/parties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isVisible": $is_visible, "pageNumber": $page_number, "partyRoleId": $party_role_id, "partyRoleGroupId": $party_role_group_id, "attorneyRepresentationTypeId": $attorney_representation_type_id, "partyClassificationType": $party_classification_type} | compact), body: null}
}

# Gets Related Cases for a requested Case ID.
#
# GET /case/{caseId}/relatedCases
# operationId: getCaseRelatedCases
export def "case-related-cases get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: table<additionalSourceData: record, caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseRelationshipType: record, isVisible: bool, object: string, sourceCaseRelationshipType: string>, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/case/{case_id}/relatedCases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Area Of Law.
#
# GET /caseCountAnalyticsByAreaOfLaw
# operationId: getCaseCountAnalyticsByAreaOfLaw
export def "case-count-analytics-by-area-of-law get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<areaOfLaw: record, caseCount: int, caseSearchAPI: string, object: string>, totalAreaOfLawCount: int, totalCaseCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByAreaOfLaw" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Case Class.
#
# GET /caseCountAnalyticsByCaseClass
# operationId: getCaseCountAnalyticsByCaseClass
export def "case-count-analytics-by-case-class get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseClass: record, caseCount: int, caseSearchAPI: string, object: string>, totalCaseClassCount: int, totalCaseCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCaseClass" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Case Filed Date.
#
# GET /caseCountAnalyticsByCaseFiledDate
# operationId: getCaseCountAnalyticsByCaseFiledDate
export def "case-count-analytics-by-case-filed-date get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
  --group-by: string@group-by-completer # GroupBy
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, groupedBy: string, monthInt: int, monthString: string, object: string, quarter: string, weekOfMonth: int, weekOfYear: int, year: int>, totalCaseCount: int, totalCaseFiledDateCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCaseFiledDate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "groupBy": $group_by} | compact), body: null}
}

# Case Count Analytics by Case Type.
#
# GET /caseCountAnalyticsByCaseType
# operationId: getCaseCountAnalyticsByCaseType
export def "case-count-analytics-by-case-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, caseType: record, object: string>, totalCaseCount: int, totalCaseTypeCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCaseType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Case Type Group.
#
# GET /caseCountAnalyticsByCaseTypeGroup
# operationId: getCaseCountAnalyticsByCaseTypeGroup
export def "case-count-analytics-by-case-type-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, caseTypeGroup: record, object: string>, totalCaseCount: int, totalCaseTypeGroupCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCaseTypeGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Court.
#
# GET /caseCountAnalyticsByCourt
# operationId: getCaseCountAnalyticsByCourt
export def "case-count-analytics-by-court get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, court: record, object: string>, totalCaseCount: int, totalCourtCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCourt" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Court Location.
#
# GET /caseCountAnalyticsByCourtLocation
# operationId: getCaseCountAnalyticsByCourtLocation
export def "case-count-analytics-by-court-location get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, court: record, courtLocation: record, object: string>, totalCaseCount: int, totalCourtLocationCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCourtLocation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Court System.
#
# GET /caseCountAnalyticsByCourtSystem
# operationId: getCaseCountAnalyticsByCourtSystem
export def "case-count-analytics-by-court-system get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, courtSystem: record, object: string>, totalCaseCount: int, totalCourtSystemCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCourtSystem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by CourtType.
#
# GET /caseCountAnalyticsByCourtType
# operationId: getCaseCountAnalyticsByCourtType
export def "case-count-analytics-by-court-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, courtType: record, object: string>, totalCaseCount: int, totalCourtTypeCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCourtType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Jurisdiction Geo.
#
# GET /caseCountAnalyticsByJurisdictionGeo
# operationId: getCaseCountAnalyticsByJurisdictionGeo
export def "case-count-analytics-by-jurisdiction-geo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, jurisdictionGeo: record, object: string>, totalCaseCount: int, totalJurisdictionGeoCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByJurisdictionGeo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Attorney.
#
# GET /caseCountAnalyticsByNormAttorney
# operationId: getCaseCountAnalyticsByNormAttorney
export def "case-count-analytics-by-norm-attorney get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normAttorneyId: string, normAttorneyName: string, object: string>, totalCaseCount: int, totalNormAttorneyCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByNormAttorney" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Judge.
#
# GET /caseCountAnalyticsByNormJudge
# operationId: getCaseCountAnalyticsByNormJudge
export def "case-count-analytics-by-norm-judge get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normJudgeId: string, normJudgeName: string, object: string>, totalCaseCount: int, totalNormJudgeCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByNormJudge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Norm Law Firm.
#
# GET /caseCountAnalyticsByNormLawFirm
# operationId: getCaseCountAnalyticsByNormLawFirm
export def "case-count-analytics-by-norm-law-firm get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normLawFirmId: string, normLawFirmName: string, object: string>, totalCaseCount: int, totalNormLawFirmCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByNormLawFirm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Party.
#
# GET /caseCountAnalyticsByNormParty
# operationId: getCaseCountAnalyticsByNormParty
export def "case-count-analytics-by-norm-party get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normPartyId: string, normPartyName: string, object: string>, totalCaseCount: int, totalNormPartyCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByNormParty" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Party Role.
#
# GET /caseCountAnalyticsByPartyRole
# operationId: getCaseCountAnalyticsByPartyRole
export def "case-count-analytics-by-party-role get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, object: string, partyRole: record>, totalCaseCount: int, totalPages: int, totalPartyRoleCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByPartyRole" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Party Role Group.
#
# GET /caseCountAnalyticsByPartyRoleGroup
# operationId: getCaseCountAnalyticsByPartyRoleGroup
export def "case-count-analytics-by-party-role-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, object: string, partyRoleGroup: record>, totalCaseCount: int, totalPages: int, totalPartyRoleGroupCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByPartyRoleGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Gets details for a requested Document ID.
#
# GET /caseDocument/{caseDocumentId}
# operationId: getDocumentById
export def "case-document get" [
  case_document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_document_id | is-empty) { error make --unspanned { msg: "path parameter 'caseDocumentId' must be non-empty" } }
  let full_url = (build-url $base ({case_document_id: (encode-path-segment $case_document_id)} | format pattern "/caseDocument/{case_document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets downloadable URL for a requested Document ID.
#
# GET /caseDocumentDownload/{caseDocumentId}
# operationId: getCaseDocumentDownloadById
export def "case-document-download get" [
  case_document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-preview-document: oneof<nothing, bool> # If the document you want to download is a preview of a document. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_document_id | is-empty) { error make --unspanned { msg: "path parameter 'caseDocumentId' must be non-empty" } }
  let qp = [(serialize-qp "isPreviewDocument" $is_preview_document "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_document_id: (encode-path-segment $case_document_id)} | format pattern "/caseDocumentDownload/{case_document_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"isPreviewDocument": $is_preview_document} | compact), body: null}
}

# Add Case Document Order for requested Document Ids.
#
# PUT /caseDocumentOrder
# operationId: orderCaseDocument
# --pacerOptions shape: {pacerClientCode?: string, pacerUserId: string}
export def "case-document-order update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  case_document_id: string # Document ID which you want to order. (e.g. CDOCcre989d654fa05)
  --is-preview-only: oneof<nothing, bool> # Flag value to determine if the document order is a preview order or no. (e.g. true)
  --pacer-options: record # **Applicable for PACER cases.** — shape: {pacerClientCode?: string, pacerUserId: string}
]: any -> record<callbackGeneratedDate: string, caseDocument: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/caseDocumentOrder")
  let req_body = {"caseDocumentId": $case_document_id, "isPreviewOnly": $is_preview_only, "pacerOptions": $pacer_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Case Document Order Callback list for a requested Date.
#
# GET /caseDocumentOrder/callbacks
# operationId: getCaseDocumentOrderCallbacks
export def "case-document-order-callbacks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date for which fetch the Case Document Order Callback list. By default, the date will be set to current date. (format: date-time)
  --status: string@status-completer # Status of Document Order callbacks. Default status will fetch all callbacks.
  --page-number: int # Page to fetch the Case Document Order Callback list. - Minimum: 1 (default: 1)
]: nothing -> record<callbackArray: table<callbackGeneratedDate: string, caseDocument: record, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record, file: record, object: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseDocumentOrder/callbacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date": $date, "status": $status, "pageNumber": $page_number} | compact), body: null}
}

# Get Case Document Order Callback for a requested Case Document Order Callback Id.
#
# GET /caseDocumentOrder/callbacks/{caseDocumentOrderCallbackId}
# operationId: getCaseDocumentOrderCallbackById
export def "case-document-order-callbacks get" [
  case_document_order_callback_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callbackGeneratedDate: string, caseDocument: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_document_order_callback_id | is-empty) { error make --unspanned { msg: "path parameter 'caseDocumentOrderCallbackId' must be non-empty" } }
  let full_url = (build-url $base ({case_document_order_callback_id: (encode-path-segment $case_document_order_callback_id)} | format pattern "/caseDocumentOrder/callbacks/{case_document_order_callback_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Case Export Callback list for a requested Date.
#
# GET /caseExport/callbacks
# operationId: getCaseExportCallbacks
export def "case-export-callbacks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for which callbacks are to be retrieved. (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --status: string@status-completer # The status code of the callbacks to be retrieved.
  --page-number: int # The page number of the callbacks to be retrieved. - Minimum: 1 (default: 1, e.g. 1)
]: nothing -> record<callbackArray: table<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record, file: record, object: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseExport/callbacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date": $date, "status": $status, "pageNumber": $page_number} | compact), body: null}
}

# Get Case Export Callback for a requested Case Export Callback Id.
#
# GET /caseExport/callbacks/{caseExportCallbackId}
# operationId: getCaseExportCallbackById
export def "case-export-callbacks get" [
  case_export_callback_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_export_callback_id | is-empty) { error make --unspanned { msg: "path parameter 'caseExportCallbackId' must be non-empty" } }
  let full_url = (build-url $base ({case_export_callback_id: (encode-path-segment $case_export_callback_id)} | format pattern "/caseExport/callbacks/{case_export_callback_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets case exported for a requested Case ID.
#
# GET /caseExport/{caseId}
# operationId: exportCase
export def "case-export export" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/caseExport/{case_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Case search.
#
# GET /caseSearch
# operationId: searchCases
export def "case-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query parameter for keyword expressions.
  --qp-sort: string@sort-completer # Query parameter specifying how results are to be sorted. Results can be sorted according to filedDate or relevancy. (default: filedDate, e.g. filedDate)
  --order: string@order-completer # Query parameter specifying whether search result are sorted in ascending or descending order. (default: desc, e.g. desc)
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<caseSearchId: string, caseSearchResultArray: table<caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseStatus: record, caseType: record, court: record, courtLocation: record, filedDate: string, firstFetchDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, matchedObjectArray: list, object: string, participantsLastFetchDate: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseSearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort, "order": $order, "pageNumber": $page_number} | compact), body: null}
}

# Case search results for a given caseSearchId.
#
# GET /caseSearch/{caseSearchId}
# operationId: searchCasesById
export def "case-search list-1" [
  case_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<caseSearchId: string, caseSearchResultArray: table<caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseStatus: record, caseType: record, court: record, courtLocation: record, filedDate: string, firstFetchDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, matchedObjectArray: list, object: string, participantsLastFetchDate: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_search_id | is-empty) { error make --unspanned { msg: "path parameter 'caseSearchId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_search_id: (encode-path-segment $case_search_id)} | format pattern "/caseSearch/{case_search_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}

# Add Case Track for the requested Case Id.
#
# PUT /caseTrack
# operationId: trackCase
# --caseTrackParams shape: {caseId: string, pacerOptions?: record}
# --schedule shape: {days: list<int>, type: "daily"|"weekly"|"monthly"}
export def "case-track update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  case_track_params: record # shape: {caseId: string, pacerOptions?: record}
  schedule: record # shape: {days: list<int>, type: "daily"|"weekly"|"monthly"}
]: any -> record<message: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/caseTrack")
  let req_body = {"caseTrackParams": $case_track_params, "schedule": $schedule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove Case Track for a specific Case Id.
#
# DELETE /caseTrack/{caseId}
# operationId: removeCaseTrackById
export def "case-track delete" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/caseTrack/{case_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Case Track for a requested Case Id.
#
# GET /caseTrack/{caseId}
# operationId: getCaseTrackById
export def "case-track get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, lastFetchDate: string, lastFetchDateWithUpdates: string, lastTrackedDetails: record<lastTrackDate: string, lastTrackException: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, schedule: record<days: list<int>, object: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/caseTrack/{case_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Case Track list.
#
# GET /caseTracks
# operationId: getCaseTracks
export def "case-tracks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-fetch-date: string # The lastFetchDate value of the tracked case. The date value should be entered in the format YYYY-MM-DDTHH:MM:SS+ZZ:zz. (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --last-fetch-date-with-updates: string # The date on which changes were last found in the case information. (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --page-number: int # The page number of the results to be retrieved. - Minimum: 1 (e.g. 1)
]: nothing -> record<caseTrackPreviewArray: table<caseAPI: string, caseId: string, lastFetchDate: string, lastFetchDateWithUpdates: string, lastTrackedDetails: record, object: string, pacerOptions: record, schedule: record>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lastFetchDate" $last_fetch_date "scalar") (serialize-qp "lastFetchDateWithUpdates" $last_fetch_date_with_updates "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseTracks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lastFetchDate": $last_fetch_date, "lastFetchDateWithUpdates": $last_fetch_date_with_updates, "pageNumber": $page_number} | compact), body: null}
}

# Add Case Update for the requested Case Id.
#
# PUT /caseUpdate
# operationId: updateCase
# --pacerOptions shape: {additionalPageArray?: list, fetchParticipantsIfOlderThanDays?: int, pacerClientCode?: string, pacerUserId: string, refreshType?: "fetchNewDocketEntries"|"fetchAllDocketEntries"}
export def "case-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  case_id: string # UniCourt's Case Id for update. (e.g. CASEhq9d8b72d0800c)
  --pacer-options: record # Applicable for PACER cases. — shape: {additionalPageArray?: list, fetchParticipantsIfOlderThanDays?: int, pacerClientCode?: string, pacerUserId: string, refreshType?: "fetchNewDocketEntries"|"fetchAllDocketEntries"}
]: any -> record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, requestedDate: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/caseUpdate")
  let req_body = {"caseId": $case_id, "pacerOptions": $pacer_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Case Updates for a requested CaseId.
#
# GET /caseUpdate/{caseId}
# operationId: getCaseUpdateByCaseId
export def "case-update get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, requestedDate: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'caseId' must be non-empty" } }
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/caseUpdate/{case_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Case Update list for a requested Date.
#
# GET /caseUpdates
# operationId: getCaseUpdates
export def "case-updates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --case-id: string # The caseId value of the case for which updates should be retrieved.
  --requested-date: string # The date for which case updates are to be retrieved. (format: date-time)
  --status: string@status-completer # Status of the case updates to be retrieved.
  --page-number: int # The page number of the callbacks to be retrieved. - Minimum: 1 (default: 1, e.g. 1)
]: nothing -> record<caseUpdatePreviewArray: table<caseAPI: string, caseId: string, exception: record, object: string, pacerOptions: record, requestedDate: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "caseId" $case_id "scalar") (serialize-qp "requestedDate" $requested_date "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseUpdates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"caseId": $case_id, "requestedDate": $requested_date, "status": $status, "pageNumber": $page_number} | compact), body: null}
}

# Gets Court Coverage of all courts of specific type.
#
# GET /courtCoverage/{courtId}
# operationId: getCourtCoverage
export def "court-coverage get" [
  court_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseClassCoverageArray: table<caseClass: record, caseCount: int, caseDocumentInLibraryCount: int, caseDocumentInLibraryInLastThirtyDaysCount: int, casesInLastThirtyDaysCount: int, courtServiceStatusAPI: string, freeCaseDocumentCount: int, freeCaseDocumentsInLastThirtyDaysCount: int, object: string, paidCaseDocumentCount: int, paidCaseDocumentsInLastThirtyDaysCount: int>, court: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, lastUpdateCountDate: string, object: string, totalCaseCount: int, totalCaseDocumentInLibraryCount: int, totalCaseDocumentInLibraryInLastThirtyDaysCount: int, totalCasesInLastThirtyDaysCount: int, totalFreeCaseDocumentCount: int, totalFreeCaseDocumentsInLastThirtyDaysCount: int, totalPaidCaseDocumentCount: int, totalPaidCaseDocumentsInLastThirtyDaysCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_id | is-empty) { error make --unspanned { msg: "path parameter 'courtId' must be non-empty" } }
  let full_url = (build-url $base ({court_id: (encode-path-segment $court_id)} | format pattern "/courtCoverage/{court_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get API usage for a requested Date.
#
# GET /dailyUsage/{date}
# operationId: getDailyUsageByDate
export def "daily-usage get" [
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiCallsBillable: record<count: int, lastUpdated: string>, apiCallsCredited: record<count: int, lastUpdated: string>, apiCallsMade: record<count: int, lastUpdated: string>, apiUsage: record, object: string, usageEndTime: string, usageStartTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({date: (encode-path-segment $date)} | format pattern "/dailyUsage/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate new token to access API.
#
# POST /generateNewToken
# operationId: generateNewToken
export def "generate-new-token generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  client_secret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> record<accessToken: string, object: string, tokenId: string, tokenType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/generateNewToken")
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# API to invalidate all access tokens.
#
# PUT /invalidateAllTokens
# operationId: invalidateAllTokens
export def "invalidate-all-tokens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  client_secret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> record<message: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invalidateAllTokens")
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# API to invalidate the access token.
#
# PUT /invalidateToken
# operationId: invalidateToken
export def "invalidate-token update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  client_secret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
  token_id: string # The Token ID of token being invalidated (e.g. TKID384a057WFC3Dp3)
]: any -> record<message: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invalidateToken")
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret, "tokenId": $token_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets details for a requested Judge ID.
#
# GET /judge/{judgeId}
# operationId: getJudgeById
export def "judge get" [
  judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, judgeId: string, judgeType: record<createdDate: string, judgeTypeId: string, name: string, object: string>, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, possibleNormJudgeArray: table<associatedNormAttorneysAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormJudgeAPI: string, confidenceScore: float, normJudgeAPI: string, normJudgeId: string, normJudgeName: string, object: string, scoreConstituents: record>, sourceJudgeType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($judge_id | is-empty) { error make --unspanned { msg: "path parameter 'judgeId' must be non-empty" } }
  let full_url = (build-url $base ({judge_id: (encode-path-segment $judge_id)} | format pattern "/judge/{judge_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# API to list all the access tokens Id.
#
# PUT /listAllTokenIds
# operationId: listAllTokenIds
export def "list-all-token-ids list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  client_secret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> record<AccessTokenIdArray: table<issueAddress: string, issuedDate: string, object: string, tokenId: string>, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/listAllTokenIds")
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AreaOfLaw Object.
#
# GET /masterData/areaOfLaw
# operationId: getAreasOfLaw
export def "master-data-area-of-law list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<areaOfLawArray: table<areaOfLawId: string, caseClass: string, caseClassId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/areaOfLaw" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# AreaOfLaw Object for the given AreaOfLaw Id.
#
# GET /masterData/areaOfLaw/{areaOfLawId}
# operationId: getAreaOfLaw
export def "master-data-area-of-law get" [
  area_of_law_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<areaOfLawId: string, caseClass: string, caseClassId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($area_of_law_id | is-empty) { error make --unspanned { msg: "path parameter 'areaOfLawId' must be non-empty" } }
  let full_url = (build-url $base ({area_of_law_id: (encode-path-segment $area_of_law_id)} | format pattern "/masterData/areaOfLaw/{area_of_law_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Attorney Representation Type Object.
#
# GET /masterData/attorneyRepresentationType
# operationId: getAttorneyRepresentationTypes
export def "master-data-attorney-representation-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<attorneyRepresentationTypeArray: table<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/attorneyRepresentationType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Attorney Representation Type Object for the given attorneyRepresentationTypeId.
#
# GET /masterData/attorneyRepresentationType/{attorneyRepresentationTypeId}
# operationId: getAttorneyRepresentationType
export def "master-data-attorney-representation-type get" [
  attorney_representation_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($attorney_representation_type_id | is-empty) { error make --unspanned { msg: "path parameter 'attorneyRepresentationTypeId' must be non-empty" } }
  let full_url = (build-url $base ({attorney_representation_type_id: (encode-path-segment $attorney_representation_type_id)} | format pattern "/masterData/attorneyRepresentationType/{attorney_representation_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Attorney Type Object.
#
# GET /masterData/attorneyType
# operationId: getAttorneyTypes
export def "master-data-attorney-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<attorneyTypeArray: table<attorneyTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/attorneyType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Attorney Type Object for given Attorney Type Id.
#
# GET /masterData/attorneyType/{attorneyTypeId}
# operationId: getAttorneyType
export def "master-data-attorney-type get" [
  attorney_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($attorney_type_id | is-empty) { error make --unspanned { msg: "path parameter 'attorneyTypeId' must be non-empty" } }
  let full_url = (build-url $base ({attorney_type_id: (encode-path-segment $attorney_type_id)} | format pattern "/masterData/attorneyType/{attorney_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Case Class Object.
#
# GET /masterData/caseClass
# operationId: getCasesClass
export def "master-data-case-class list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseClassArray: table<caseClassId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseClass" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Case Class Object for the given Case Class Id.
#
# GET /masterData/caseClass/{caseClassId}
# operationId: getCaseClass
export def "master-data-case-class get" [
  case_class_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseClassId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_class_id | is-empty) { error make --unspanned { msg: "path parameter 'caseClassId' must be non-empty" } }
  let full_url = (build-url $base ({case_class_id: (encode-path-segment $case_class_id)} | format pattern "/masterData/caseClass/{case_class_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Case Relationship Type Object.
#
# GET /masterData/caseRelationshipType
# operationId: getCaseRelationshipTypes
export def "master-data-case-relationship-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseRelationshipTypeArray: table<caseRelationshipTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseRelationshipType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Case Relationship Type Object for the given caseRelationshipTypeId.
#
# GET /masterData/caseRelationshipType/{caseRelationshipTypeId}
# operationId: getCaseRelationshipType
export def "master-data-case-relationship-type get" [
  case_relationship_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseRelationshipTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_relationship_type_id | is-empty) { error make --unspanned { msg: "path parameter 'caseRelationshipTypeId' must be non-empty" } }
  let full_url = (build-url $base ({case_relationship_type_id: (encode-path-segment $case_relationship_type_id)} | format pattern "/masterData/caseRelationshipType/{case_relationship_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Case Status Object.
#
# GET /masterData/caseStatus
# operationId: getCasesStatus
export def "master-data-case-status list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseStatusArray: table<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Returns the caseStatus information for the given caseStatusId.
#
# GET /masterData/caseStatus/{caseStatusId}
# operationId: getCaseStatus
export def "master-data-case-status get" [
  case_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseClassArray: list<string>, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_status_id | is-empty) { error make --unspanned { msg: "path parameter 'caseStatusId' must be non-empty" } }
  let full_url = (build-url $base ({case_status_id: (encode-path-segment $case_status_id)} | format pattern "/masterData/caseStatus/{case_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Case Status Group Object.
#
# GET /masterData/caseStatusGroup
# operationId: getCaseStatusGroups
export def "master-data-case-status-group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseStatusGroupArray: table<caseStatusGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseStatusGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Returns the caseStatusGroup information for the given caseStatusGroupId.
#
# GET /masterData/caseStatusGroup/{caseStatusGroupId}
# operationId: getCaseStatusGroup
export def "master-data-case-status-group get" [
  case_status_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseStatusGroupId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_status_group_id | is-empty) { error make --unspanned { msg: "path parameter 'caseStatusGroupId' must be non-empty" } }
  let full_url = (build-url $base ({case_status_group_id: (encode-path-segment $case_status_group_id)} | format pattern "/masterData/caseStatusGroup/{case_status_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Case Type Object.
#
# GET /masterData/caseType
# operationId: getCaseTypes
export def "master-data-case-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseTypeArray: table<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# CaseType Object for given Case Type Id.
#
# GET /masterData/caseType/{caseTypeId}
# operationId: getCaseType
export def "master-data-case-type get" [
  case_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_type_id | is-empty) { error make --unspanned { msg: "path parameter 'caseTypeId' must be non-empty" } }
  let full_url = (build-url $base ({case_type_id: (encode-path-segment $case_type_id)} | format pattern "/masterData/caseType/{case_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# CaseTypeGroup Object.
#
# GET /masterData/caseTypeGroup
# operationId: getCaseTypeGroups
export def "master-data-case-type-group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseTypeGroupArray: table<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseTypeGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# CaseType Group for the given CaseType Group Id.
#
# GET /masterData/caseTypeGroup/{caseTypeGroupId}
# operationId: getCaseTypeGroup
export def "master-data-case-type-group get" [
  case_type_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroupId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_type_group_id | is-empty) { error make --unspanned { msg: "path parameter 'caseTypeGroupId' must be non-empty" } }
  let full_url = (build-url $base ({case_type_group_id: (encode-path-segment $case_type_group_id)} | format pattern "/masterData/caseTypeGroup/{case_type_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# CauseOfAction Object.
#
# GET /masterData/causeOfAction
# operationId: getCausesOfAction
export def "master-data-cause-of-action list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<causeOfActionArray: table<causeOfActionGroup: string, causeOfActionGroupId: string, causeOfActionId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/causeOfAction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# CauseOfAction Object for the given causeOfActionId.
#
# GET /masterData/causeOfAction/{causeOfActionId}
# operationId: getCauseOfAction
export def "master-data-cause-of-action get" [
  cause_of_action_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<causeOfActionGroup: string, causeOfActionGroupId: string, causeOfActionId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cause_of_action_id | is-empty) { error make --unspanned { msg: "path parameter 'causeOfActionId' must be non-empty" } }
  let full_url = (build-url $base ({cause_of_action_id: (encode-path-segment $cause_of_action_id)} | format pattern "/masterData/causeOfAction/{cause_of_action_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# CauseOfActionAdditionaData Object.
#
# GET /masterData/causeOfActionAdditionalData
# operationId: getCausesOfActionAdditionalData
export def "master-data-cause-of-action-additional-data list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<causeOfActionAdditionalDataArray: table<causeOfActionAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/causeOfActionAdditionalData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# CauseOfActionAdditionalData Object for the given causeOfActionAdditionalDataId.
#
# GET /masterData/causeOfActionAdditionalData/{causeOfActionAdditionalDataId}
# operationId: getCauseOfActionAdditionalData
export def "master-data-cause-of-action-additional-data get" [
  cause_of_action_additional_data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<causeOfActionAdditionalDataId: string, createdDate: string, object: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cause_of_action_additional_data_id | is-empty) { error make --unspanned { msg: "path parameter 'causeOfActionAdditionalDataId' must be non-empty" } }
  let full_url = (build-url $base ({cause_of_action_additional_data_id: (encode-path-segment $cause_of_action_additional_data_id)} | format pattern "/masterData/causeOfActionAdditionalData/{cause_of_action_additional_data_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# CauseOfActionGroup Object.
#
# GET /masterData/causeOfActionGroup
# operationId: getCausesOfActionGroup
export def "master-data-cause-of-action-group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<causeOfActionGroupArray: table<causeOfActionGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/causeOfActionGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# CauseOfActionGroup Object for the given causeOfActionGroupId.
#
# GET /masterData/causeOfActionGroup/{causeOfActionGroupId}
# operationId: getCauseOfActionGroup
export def "master-data-cause-of-action-group get" [
  cause_of_action_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<causeOfActionGroupId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cause_of_action_group_id | is-empty) { error make --unspanned { msg: "path parameter 'causeOfActionGroupId' must be non-empty" } }
  let full_url = (build-url $base ({cause_of_action_group_id: (encode-path-segment $cause_of_action_group_id)} | format pattern "/masterData/causeOfActionGroup/{cause_of_action_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Charge Object.
#
# GET /masterData/charge
# operationId: getCharges
export def "master-data-charge list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeArray: table<chargeGroup: string, chargeGroupId: string, chargeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/charge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Charge Object for the given chargeId.
#
# GET /masterData/charge/{chargeId}
# operationId: getCharge
export def "master-data-charge get" [
  charge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeGroup: string, chargeGroupId: string, chargeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($charge_id | is-empty) { error make --unspanned { msg: "path parameter 'chargeId' must be non-empty" } }
  let full_url = (build-url $base ({charge_id: (encode-path-segment $charge_id)} | format pattern "/masterData/charge/{charge_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Charge Additional Data Object.
#
# GET /masterData/chargeAdditionalData
# operationId: getChargesAdditionalData
export def "master-data-charge-additional-data list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeAdditionalDataArray: table<chargeAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/chargeAdditionalData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Charge Additional Data Object for the given chargeAdditionalDataId.
#
# GET /masterData/chargeAdditionalData/{chargeAdditionalDataId}
# operationId: getChargeAdditionalData
export def "master-data-charge-additional-data get" [
  charge_additional_data_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeAdditionalDataId: string, createdDate: string, object: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($charge_additional_data_id | is-empty) { error make --unspanned { msg: "path parameter 'chargeAdditionalDataId' must be non-empty" } }
  let full_url = (build-url $base ({charge_additional_data_id: (encode-path-segment $charge_additional_data_id)} | format pattern "/masterData/chargeAdditionalData/{charge_additional_data_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# ChargeDegree Object.
#
# GET /masterData/chargeDegree
# operationId: getChargesDegree
export def "master-data-charge-degree list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeDegreeArray: table<chargeDegreeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/chargeDegree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# ChargeDegree Object for the given chargeDegreeId.
#
# GET /masterData/chargeDegree/{chargeDegreeId}
# operationId: getChargeDegree
export def "master-data-charge-degree get" [
  charge_degree_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeDegreeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($charge_degree_id | is-empty) { error make --unspanned { msg: "path parameter 'chargeDegreeId' must be non-empty" } }
  let full_url = (build-url $base ({charge_degree_id: (encode-path-segment $charge_degree_id)} | format pattern "/masterData/chargeDegree/{charge_degree_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Charge Group Object.
#
# GET /masterData/chargeGroup
# operationId: getChargeGroups
export def "master-data-charge-group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeGroupArray: table<chargeGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/chargeGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Charge Group Object for the given chargeGroupId.
#
# GET /masterData/chargeGroup/{chargeGroupId}
# operationId: getChargeGroup
export def "master-data-charge-group get" [
  charge_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeGroupId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($charge_group_id | is-empty) { error make --unspanned { msg: "path parameter 'chargeGroupId' must be non-empty" } }
  let full_url = (build-url $base ({charge_group_id: (encode-path-segment $charge_group_id)} | format pattern "/masterData/chargeGroup/{charge_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# ChargeSeverity Object.
#
# GET /masterData/chargeSeverity
# operationId: getChargesSeverity
export def "master-data-charge-severity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeSeverityArray: table<chargeSeverityId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/chargeSeverity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# ChargeSeverity Object for the given chargeSeverityId.
#
# GET /masterData/chargeSeverity/{chargeSeverityId}
# operationId: getChargeSeverity
export def "master-data-charge-severity get" [
  charge_severity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeSeverityId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($charge_severity_id | is-empty) { error make --unspanned { msg: "path parameter 'chargeSeverityId' must be non-empty" } }
  let full_url = (build-url $base ({charge_severity_id: (encode-path-segment $charge_severity_id)} | format pattern "/masterData/chargeSeverity/{charge_severity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Court Objects.
#
# GET /masterData/court
# operationId: getCourts
export def "master-data-court list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/court" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Court Object for given courtId.
#
# GET /masterData/court/{courtId}
# operationId: getCourt
export def "master-data-court get" [
  court_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_id | is-empty) { error make --unspanned { msg: "path parameter 'courtId' must be non-empty" } }
  let full_url = (build-url $base ({court_id: (encode-path-segment $court_id)} | format pattern "/masterData/court/{court_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Appeal Court Objects for given courtId.
#
# GET /masterData/court/{courtId}/appealCourts
# operationId: getAppealCourtsForCourt
export def "master-data-court-appeal-courts get" [
  court_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_id | is-empty) { error make --unspanned { msg: "path parameter 'courtId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({court_id: (encode-path-segment $court_id)} | format pattern "/masterData/court/{court_id}/appealCourts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Associated Court Location for given courtId.
#
# GET /masterData/court/{courtId}/courtLocations
# operationId: getCourtLocationsForCourt
export def "master-data-court-court-locations get" [
  court_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtLocationArray: table<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_id | is-empty) { error make --unspanned { msg: "path parameter 'courtId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({court_id: (encode-path-segment $court_id)} | format pattern "/masterData/court/{court_id}/courtLocations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Jurisdiction Geo Objects for given courtId.
#
# GET /masterData/court/{courtId}/jurisdictionGeo
# operationId: getJurisdictionGeoForCourt
export def "master-data-court-jurisdiction-geo get" [
  court_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-2 # Sort field. (default: state, e.g. state)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<jurisdictionGeoArray: table<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_id | is-empty) { error make --unspanned { msg: "path parameter 'courtId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({court_id: (encode-path-segment $court_id)} | format pattern "/masterData/court/{court_id}/jurisdictionGeo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Courthouse Object.
#
# GET /masterData/courtLocation
# operationId: getCourtLocations
export def "master-data-court-location list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtLocationArray: table<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/courtLocation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Courthouse Object for given Court Location Id.
#
# GET /masterData/courtLocation/{courtLocationId}
# operationId: getCourtLocation
export def "master-data-court-location get" [
  court_location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_location_id | is-empty) { error make --unspanned { msg: "path parameter 'courtLocationId' must be non-empty" } }
  let full_url = (build-url $base ({court_location_id: (encode-path-segment $court_location_id)} | format pattern "/masterData/courtLocation/{court_location_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Associated Court for given Court Location.
#
# GET /masterData/courtLocation/{courtLocationId}/courts
# operationId: getCourtsForCourtLocation
export def "master-data-court-location-courts get" [
  court_location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_location_id | is-empty) { error make --unspanned { msg: "path parameter 'courtLocationId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({court_location_id: (encode-path-segment $court_location_id)} | format pattern "/masterData/courtLocation/{court_location_id}/courts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Court Service Status Object.
#
# GET /masterData/courtServiceStatus
# operationId: getCourtsServiceStatus
export def "master-data-court-service-status list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtServiceStatusArray: table<caseClassIdArray: list, caseDocumentOrderServiceStatus: record, caseTrackServiceStatus: record, caseUpdateServiceStatus: record, courtIdArray: list, courtLocationIdArray: list, courtServiceStatusId: string, object: string, serviceStatusAsOn: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/courtServiceStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Court Service Status Object for the given courtServiceStatusId.
#
# GET /masterData/courtServiceStatus/{courtServiceStatusId}
# operationId: getCourtServiceStatus
export def "master-data-court-service-status get" [
  court_service_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseClassIdArray: list<string>, caseDocumentOrderServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, caseTrackServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, caseUpdateServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, courtIdArray: list<string>, courtLocationIdArray: list<string>, courtServiceStatusId: string, object: string, serviceStatusAsOn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_service_status_id | is-empty) { error make --unspanned { msg: "path parameter 'courtServiceStatusId' must be non-empty" } }
  let full_url = (build-url $base ({court_service_status_id: (encode-path-segment $court_service_status_id)} | format pattern "/masterData/courtServiceStatus/{court_service_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Court System Objects.
#
# GET /masterData/courtSystem
# operationId: getCourtSystems
export def "master-data-court-system list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtSystemArray: table<courtSystemId: string, courtType: string, courtTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/courtSystem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Court System Object for given courtSystemId.
#
# GET /masterData/courtSystem/{courtSystemId}
# operationId: getCourtSystem
export def "master-data-court-system get" [
  court_system_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<courtSystemId: string, courtType: string, courtTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_system_id | is-empty) { error make --unspanned { msg: "path parameter 'courtSystemId' must be non-empty" } }
  let full_url = (build-url $base ({court_system_id: (encode-path-segment $court_system_id)} | format pattern "/masterData/courtSystem/{court_system_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Court Type Objects.
#
# GET /masterData/courtType
# operationId: getCourtTypes
export def "master-data-court-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtTypeArray: table<courtTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/courtType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Court Type Object for given courtTypeId.
#
# GET /masterData/courtType/{courtTypeId}
# operationId: getCourtType
export def "master-data-court-type get" [
  court_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<courtTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($court_type_id | is-empty) { error make --unspanned { msg: "path parameter 'courtTypeId' must be non-empty" } }
  let full_url = (build-url $base ({court_type_id: (encode-path-segment $court_type_id)} | format pattern "/masterData/courtType/{court_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Judge Type Object.
#
# GET /masterData/judgeType
# operationId: getJudgeTypes
export def "master-data-judge-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<judgeTypeArray: table<createdDate: string, judgeTypeId: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/judgeType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Judge Type Object for the given judgeTypeId.
#
# GET /masterData/judgeType/{judgeTypeId}
# operationId: getJudgeType
export def "master-data-judge-type get" [
  judge_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: string, judgeTypeId: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($judge_type_id | is-empty) { error make --unspanned { msg: "path parameter 'judgeTypeId' must be non-empty" } }
  let full_url = (build-url $base ({judge_type_id: (encode-path-segment $judge_type_id)} | format pattern "/masterData/judgeType/{judge_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Jurisdiction Geo Object.
#
# GET /masterData/jurisdictionGeo
# operationId: getJurisdictionsGeo
export def "master-data-jurisdiction-geo list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-2 # Sort field. (default: state, e.g. state)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<jurisdictionGeoArray: table<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/jurisdictionGeo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Jurisdiction Geo Object for given Jurisdiction Geo Id.
#
# GET /masterData/jurisdictionGeo/{jurisdictionGeoId}
# operationId: getJurisdictionGeo
export def "master-data-jurisdiction-geo get" [
  jurisdiction_geo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jurisdiction_geo_id | is-empty) { error make --unspanned { msg: "path parameter 'jurisdictionGeoId' must be non-empty" } }
  let full_url = (build-url $base ({jurisdiction_geo_id: (encode-path-segment $jurisdiction_geo_id)} | format pattern "/masterData/jurisdictionGeo/{jurisdiction_geo_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Associated Court for given Jurisdiction Geo.
#
# GET /masterData/jurisdictionGeo/{jurisdictionGeoId}/courts
# operationId: getCourtsForJurisdictionGeo
export def "master-data-jurisdiction-geo-courts get" [
  jurisdiction_geo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($jurisdiction_geo_id | is-empty) { error make --unspanned { msg: "path parameter 'jurisdictionGeoId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({jurisdiction_geo_id: (encode-path-segment $jurisdiction_geo_id)} | format pattern "/masterData/jurisdictionGeo/{jurisdiction_geo_id}/courts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Party Role Object.
#
# GET /masterData/partyRole
# operationId: getPartyRoles
export def "master-data-party-role list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyRoleArray: table<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/partyRole" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Party Role Object.
#
# GET /masterData/partyRole/{partyRoleId}
# operationId: getPartyRole
export def "master-data-party-role get" [
  party_role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_role_id | is-empty) { error make --unspanned { msg: "path parameter 'partyRoleId' must be non-empty" } }
  let full_url = (build-url $base ({party_role_id: (encode-path-segment $party_role_id)} | format pattern "/masterData/partyRole/{party_role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Party Role Group Object.
#
# GET /masterData/partyRoleGroup
# operationId: getPartyRoleGroups
export def "master-data-party-role-group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1 - maximum: 100 (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyRoleGroupArray: table<createdDate: string, description: string, name: string, object: string, partyRoleGroupId: string>, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/partyRoleGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number, "sort": $qp_sort, "order": $order} | compact), body: null}
}

# Party Role Group Object.
#
# GET /masterData/partyRoleGroup/{partyRoleGroupId}
# operationId: getPartyRoleGroup
export def "master-data-party-role-group get" [
  party_role_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: string, description: string, name: string, object: string, partyRoleGroupId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_role_group_id | is-empty) { error make --unspanned { msg: "path parameter 'partyRoleGroupId' must be non-empty" } }
  let full_url = (build-url $base ({party_role_group_id: (encode-path-segment $party_role_group_id)} | format pattern "/masterData/partyRoleGroup/{party_role_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Norm Attorney Details.
#
# GET /normAttorney/{normAttorneyId}
# operationId: getNormAttorneyById
export def "norm-attorney get" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyAnalyticsAPI: record<associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normAttorneyAPI: string, object: string>, barRecordArray: table<admittedDate: string, barNumber: string, barSourceData: record, barSourceType: string, contact: record, firstFetchDate: string, inactivationDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, stateCode: string, status: string>, caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, firstName: string, hasAssociatedPublicData: bool, lastName: string, middleName: string, name: string, normAttorneyId: string, object: string, similarNormAttorneyArray: table<barRecordPreviewArray: list, name: string, normAttorneyAPI: string, normAttorneyId: string, normAttorneySimilarityScore: float, object: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_attorney_id | is-empty) { error make --unspanned { msg: "path parameter 'normAttorneyId' must be non-empty" } }
  let full_url = (build-url $base ({norm_attorney_id: (encode-path-segment $norm_attorney_id)} | format pattern "/normAttorney/{norm_attorney_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Judges faced by the Attorney.
#
# GET /normAttorney/{normAttorneyId}/associatedNormJudges
# operationId: getNormJudgesAssociatedWithNormAttorney
export def "norm-attorney-associated-norm-judges get" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_attorney_id | is-empty) { error make --unspanned { msg: "path parameter 'normAttorneyId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_attorney_id: (encode-path-segment $norm_attorney_id)} | format pattern "/normAttorney/{norm_attorney_id}/associatedNormJudges") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Law Firms the attorney has worked for.
#
# GET /normAttorney/{normAttorneyId}/associatedNormLawFirms
# operationId: getNormLawFirmsAssociatedWithNormAttorney
export def "norm-attorney-associated-norm-law-firms get" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_attorney_id | is-empty) { error make --unspanned { msg: "path parameter 'normAttorneyId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_attorney_id: (encode-path-segment $norm_attorney_id)} | format pattern "/normAttorney/{norm_attorney_id}/associatedNormLawFirms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Parties Represented By the Attorney.
#
# GET /normAttorney/{normAttorneyId}/associatedNormParties
# operationId: getNormPartiesAssociatedWithNormAttorney
export def "norm-attorney-associated-norm-parties get" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_attorney_id | is-empty) { error make --unspanned { msg: "path parameter 'normAttorneyId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_attorney_id: (encode-path-segment $norm_attorney_id)} | format pattern "/normAttorney/{norm_attorney_id}/associatedNormParties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Opposing Norm Attorney.
#
# GET /normAttorney/{normAttorneyId}/caseCountAnalyticsByOpposingNormAttorney
# operationId: getCaseCountAnalyticsByOpposingNormAttorneyForANormAttorney
export def "norm-attorney-case-count-analytics-by-opposing-norm-attorney get" [
  norm_attorney_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normAttorneyId: string, normAttorneyName: string, object: string>, totalCaseCount: int, totalNormAttorneyCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_attorney_id | is-empty) { error make --unspanned { msg: "path parameter 'normAttorneyId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_attorney_id: (encode-path-segment $norm_attorney_id)} | format pattern "/normAttorney/{norm_attorney_id}/caseCountAnalyticsByOpposingNormAttorney") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Attorney search.
#
# GET /normAttorneySearch
# operationId: searchNormalizedAttorneys
export def "norm-attorney-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<nextPageAPI: string, normAttorneySearchId: string, normAttorneySearchResultArray: table<firstFetchDate: string, hasAssociatedPublicData: bool, lastFetchDate: string, matchedObjectArray: list, name: string, normAttorneyDetailsAPI: string, normAttorneyId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/normAttorneySearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Norm attorney search results for a given normAttorneySearchId.
#
# GET /normAttorneySearch/{normAttorneySearchId}
# operationId: searchNormalizedAttorneysById
export def "norm-attorney-search list-normalized" [
  norm_attorney_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<nextPageAPI: string, normAttorneySearchId: string, normAttorneySearchResultArray: table<firstFetchDate: string, hasAssociatedPublicData: bool, lastFetchDate: string, matchedObjectArray: list, name: string, normAttorneyDetailsAPI: string, normAttorneyId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_attorney_search_id | is-empty) { error make --unspanned { msg: "path parameter 'normAttorneySearchId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_attorney_search_id: (encode-path-segment $norm_attorney_search_id)} | format pattern "/normAttorneySearch/{norm_attorney_search_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}

# Norm Judge Details.
#
# GET /normJudge/{normJudgeId}
# operationId: getNormJudgeById
export def "norm-judge get" [
  norm_judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, firstName: string, hasAssociatedPublicData: bool, judgeAnalyticsAPI: record<associatedNormAttorneysAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, normJudgeAPI: string, object: string>, judicialDataArray: table<abaRatings: record, aliasArray: list, bio: record, contact: record, educationArray: list, firstFetchDate: string, judicialSource: record, judicialStatus: string, lastFetchDate: string, lastFetchDateWithUpdates: string, nameHistoryArray: list, object: string, professionalCareerArray: list, serviceHistoryArray: list>, lastName: string, middleName: string, name: string, normJudgeId: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_judge_id | is-empty) { error make --unspanned { msg: "path parameter 'normJudgeId' must be non-empty" } }
  let full_url = (build-url $base ({norm_judge_id: (encode-path-segment $norm_judge_id)} | format pattern "/normJudge/{norm_judge_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Attorneys Associated with the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormAttorneys
# operationId: getNormAttorneysAssociatedWithNormJudge
export def "norm-judge-associated-norm-attorneys get" [
  norm_judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_judge_id | is-empty) { error make --unspanned { msg: "path parameter 'normJudgeId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_judge_id: (encode-path-segment $norm_judge_id)} | format pattern "/normJudge/{norm_judge_id}/associatedNormAttorneys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Law Firms Associated With the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormLawFirms
# operationId: getNormLawFirmsAssociatedWithNormJudge
export def "norm-judge-associated-norm-law-firms get" [
  norm_judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_judge_id | is-empty) { error make --unspanned { msg: "path parameter 'normJudgeId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_judge_id: (encode-path-segment $norm_judge_id)} | format pattern "/normJudge/{norm_judge_id}/associatedNormLawFirms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Parties Associated with the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormParties
# operationId: getNormPartiesAssociatedWithNormJudge
export def "norm-judge-associated-norm-parties get" [
  norm_judge_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_judge_id | is-empty) { error make --unspanned { msg: "path parameter 'normJudgeId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_judge_id: (encode-path-segment $norm_judge_id)} | format pattern "/normJudge/{norm_judge_id}/associatedNormParties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Judge search.
#
# GET /normJudgeSearch
# operationId: searchNormalizedJudges
export def "norm-judge-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<nextPageAPI: string, normJudgeSearchId: string, normJudgeSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normJudgeDetailsAPI: string, normJudgeId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/normJudgeSearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Norm judge search results for a given normJudgeSearchId.
#
# GET /normJudgeSearch/{normJudgeSearchId}
# operationId: searchNormalizedJudgesById
export def "norm-judge-search list-normalized" [
  norm_judge_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<nextPageAPI: string, normJudgeSearchId: string, normJudgeSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normJudgeDetailsAPI: string, normJudgeId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_judge_search_id | is-empty) { error make --unspanned { msg: "path parameter 'normJudgeSearchId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_judge_search_id: (encode-path-segment $norm_judge_search_id)} | format pattern "/normJudgeSearch/{norm_judge_search_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}

# Norm LawFirm Details.
#
# GET /normLawFirm/{normLawFirmId}
# operationId: getNormLawFirmById
export def "norm-law-firm get" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, lawFirmAnalyticsAPI: record<associatedNormAttorneyAPI: string, associatedNormJudgeAPI: string, associatedNormPartiesAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normLawFirmAPI: string, object: string>, name: string, normLawFirmId: string, normOrganizationData: record<cik: string, isInvolvedInLitigation: bool, lei: string, naics: string, naicsDescription: string, name: string, normCorporateGroupArray: list<record>, normOrganizationId: string, normPartyAPI: string, object: string, organizationType: string, sic: string, sicDescription: string, sosDataArray: list<record>, tickerArray: list<record>>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_law_firm_id | is-empty) { error make --unspanned { msg: "path parameter 'normLawFirmId' must be non-empty" } }
  let full_url = (build-url $base ({norm_law_firm_id: (encode-path-segment $norm_law_firm_id)} | format pattern "/normLawFirm/{norm_law_firm_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Attorneys working for the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormAttorneys
# operationId: getNormAttorneysAssociatedWithNormLawFirm
export def "norm-law-firm-associated-norm-attorneys get" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_law_firm_id | is-empty) { error make --unspanned { msg: "path parameter 'normLawFirmId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_law_firm_id: (encode-path-segment $norm_law_firm_id)} | format pattern "/normLawFirm/{norm_law_firm_id}/associatedNormAttorneys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Judges Faced By the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormJudges
# operationId: getNormJudgesAssociatedWithNormLawFirm
export def "norm-law-firm-associated-norm-judges get" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_law_firm_id | is-empty) { error make --unspanned { msg: "path parameter 'normLawFirmId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_law_firm_id: (encode-path-segment $norm_law_firm_id)} | format pattern "/normLawFirm/{norm_law_firm_id}/associatedNormJudges") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Parties Represented by the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormParties
# operationId: getNormPartiesAssociatedWithNormLawFirm
export def "norm-law-firm-associated-norm-parties get" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_law_firm_id | is-empty) { error make --unspanned { msg: "path parameter 'normLawFirmId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_law_firm_id: (encode-path-segment $norm_law_firm_id)} | format pattern "/normLawFirm/{norm_law_firm_id}/associatedNormParties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Opposing Norm Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/caseCountAnalyticsByOpposingNormLawFirm
# operationId: getCaseCountAnalyticsByOpposingNormLawFirmForANormLawFirm
export def "norm-law-firm-case-count-analytics-by-opposing-norm-law-firm get" [
  norm_law_firm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normLawFirmId: string, normLawFirmName: string, object: string>, totalCaseCount: int, totalNormLawFirmCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_law_firm_id | is-empty) { error make --unspanned { msg: "path parameter 'normLawFirmId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_law_firm_id: (encode-path-segment $norm_law_firm_id)} | format pattern "/normLawFirm/{norm_law_firm_id}/caseCountAnalyticsByOpposingNormLawFirm") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Law firm search.
#
# GET /normLawFirmSearch
# operationId: searchNormalizedLawFirms
export def "norm-law-firm-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<nextPageAPI: string, normLawFirmSearchId: string, normLawFirmSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normLawFirmDetailsAPI: string, normLawFirmId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/normLawFirmSearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Norm law firm search result for a given normLawFirmSearchId.
#
# GET /normLawFirmSearch/{normLawFirmSearchId}
# operationId: searchNormalizedLawFirmsById
export def "norm-law-firm-search list-normalized" [
  norm_law_firm_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<nextPageAPI: string, normLawFirmSearchId: string, normLawFirmSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normLawFirmDetailsAPI: string, normLawFirmId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_law_firm_search_id | is-empty) { error make --unspanned { msg: "path parameter 'normLawFirmSearchId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_law_firm_search_id: (encode-path-segment $norm_law_firm_search_id)} | format pattern "/normLawFirmSearch/{norm_law_firm_search_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}

# Norm Party Details.
#
# GET /normParty/{normPartyId}
# operationId: getNormPartyById
export def "norm-party get" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, individualData: record<firstName: string, lastName: string, middleName: string, name: string>, name: string, normOrganizationData: record<cik: string, isInvolvedInLitigation: bool, lei: string, naics: string, naicsDescription: string, name: string, normCorporateGroupArray: list<record>, normOrganizationId: string, normPartyAPI: string, object: string, organizationType: string, sic: string, sicDescription: string, sosDataArray: list<record>, tickerArray: list<record>>, normPartyId: string, object: string, partyAnalyticsAPI: record<associatedNormAttorneysAPI: string, associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normPartyAPI: string, object: string>, partyClassificationType: string, relatedNormPartyArray: table<normPartyId: string, object: string, relationshipType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_party_id | is-empty) { error make --unspanned { msg: "path parameter 'normPartyId' must be non-empty" } }
  let full_url = (build-url $base ({norm_party_id: (encode-path-segment $norm_party_id)} | format pattern "/normParty/{norm_party_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Attorneys that represented the Party.
#
# GET /normParty/{normPartyId}/associatedNormAttorneys
# operationId: getNormAttorneysAssociatedWithNormParty
export def "norm-party-associated-norm-attorneys get" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_party_id | is-empty) { error make --unspanned { msg: "path parameter 'normPartyId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_party_id: (encode-path-segment $norm_party_id)} | format pattern "/normParty/{norm_party_id}/associatedNormAttorneys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Judges Faced By the Party.
#
# GET /normParty/{normPartyId}/associatedNormJudges
# operationId: getNormJudgesAssociatedWithNormParty
export def "norm-party-associated-norm-judges get" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_party_id | is-empty) { error make --unspanned { msg: "path parameter 'normPartyId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_party_id: (encode-path-segment $norm_party_id)} | format pattern "/normParty/{norm_party_id}/associatedNormJudges") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Law Firms that represented the Party.
#
# GET /normParty/{normPartyId}/associatedNormLawFirms
# operationId: getNormLawFirmsAssociatedWithNormParty
export def "norm-party-associated-norm-law-firms get" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_party_id | is-empty) { error make --unspanned { msg: "path parameter 'normPartyId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_party_id: (encode-path-segment $norm_party_id)} | format pattern "/normParty/{norm_party_id}/associatedNormLawFirms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Case Count Analytics by Opposing Norm Party.
#
# GET /normParty/{normPartyId}/caseCountAnalyticsByOpposingNormParty
# operationId: getCaseCountAnalyticsByOpposingNormPartyForANormParty
export def "norm-party-case-count-analytics-by-opposing-norm-party get" [
  norm_party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --page-number: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normPartyId: string, normPartyName: string, object: string>, totalCaseCount: int, totalNormPartyCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_party_id | is-empty) { error make --unspanned { msg: "path parameter 'normPartyId' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_party_id: (encode-path-segment $norm_party_id)} | format pattern "/normParty/{norm_party_id}/caseCountAnalyticsByOpposingNormParty") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Party search.
#
# GET /normPartySearch
# operationId: searchNormalizedParties
export def "norm-party-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<nextPageAPI: string, normPartySearchId: string, normPartySearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normPartyDetailsAPI: string, normPartyId: string, object: string, partyClassificationType: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/normPartySearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "pageNumber": $page_number} | compact), body: null}
}

# Norm party search results for a given normPartySearchId.
#
# GET /normPartySearch/{normPartySearchId}
# operationId: searchNormalizedPartiesById
export def "norm-party-search list-normalized-parties" [
  norm_party_search_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000 (e.g. 1)
]: nothing -> record<nextPageAPI: string, normPartySearchId: string, normPartySearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normPartyDetailsAPI: string, normPartyId: string, object: string, partyClassificationType: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($norm_party_search_id | is-empty) { error make --unspanned { msg: "path parameter 'normPartySearchId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({norm_party_search_id: (encode-path-segment $norm_party_search_id)} | format pattern "/normPartySearch/{norm_party_search_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}

# Find PACER Case for a requested Case Number and Court.
#
# GET /pacer/importCaseByCourtUsingCaseNumber
# operationId: importPacerCaseByCourtUsingCaseNumber
export def "pacer-import-case-by-court-using-case-number import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # Case Number which you would like to Find in PACER site and import it to UniCourt. (e.g. 2:15-mc-12345)
  --court-id: string # Court Id of the Case number being provided.
]: nothing -> record<courtFee: float, object: string, pacerImportCaseResultsArray: table<hasOnlyMetaInfo: bool, object: string, uniCourtContent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "courtId" $court_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacer/importCaseByCourtUsingCaseNumber" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "courtId": $court_id} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/allCourts
# operationId: AllCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-all-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed. (nullable)
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/allCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/appealCourts
# operationId: AppealCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-appeal-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed. (nullable)
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --nature-of-suits-array: list<string> # Search can be narrowed down by passing Nature Of Suits. Please use the APPENDIX E - Appellate Nature Of Suits mentioned in the API Documentation. Scenario: When mulitple nature of suits needs to be requested. Imagine for a given case number 12-1234 I would like to search with the nature of suit 1110 (Insurance) and 1150 (Overpayments & Enforc. of Judgments), My query in the request will look like the example mentioned below. Example: natureOfSuitsArray=1110&natureOfSuitsArray=1150
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make. (e.g. 1)
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "natureOfSuitsArray" $nature_of_suits_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/appealCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "natureOfSuitsArray": $nature_of_suits_array, "courtRegionIdArray": $court_region_id_array, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for Bankruptcy Courts.
#
# GET /pacerCaseLocator/caseSearch/bankruptcyCourts
# operationId: BankruptcyCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-bankruptcy-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --federal-bankruptcy-chapter-array: list<string> # Search can be narrowed down by passing Federal Bankruptcy Chapters. Please use the APPENDIX D: Bankruptcy Chapters mentioned in the API Documentation. Scenario: When mulitple Federal Bankruptcy Chapters needs to be requested. Imagine for a given case number 12-1234 I would like to search with the Federal Bankruptcy Chapters 7 (Chapter 7) and 11 (Chapter 11), My query in the request will look like the example mentioned below. Example: federalBankruptcyChapterArray=7&federalBankruptcyChapterArray=11
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-discharged-start-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-discharged-end-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-dismissed-start-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case dismissed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-dismissed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "federalBankruptcyChapterArray" $federal_bankruptcy_chapter_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "caseDischargedStartDate" $case_discharged_start_date "scalar") (serialize-qp "caseDischargedEndDate" $case_discharged_end_date "scalar") (serialize-qp "caseDismissedStartDate" $case_dismissed_start_date "scalar") (serialize-qp "caseDismissedEndDate" $case_dismissed_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/bankruptcyCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "federalBankruptcyChapterArray": $federal_bankruptcy_chapter_array, "courtRegionIdArray": $court_region_id_array, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "caseDischargedStartDate": $case_discharged_start_date, "caseDischargedEndDate": $case_discharged_end_date, "caseDismissedStartDate": $case_dismissed_start_date, "caseDismissedEndDate": $case_dismissed_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/civilCourts
# operationId: CivilCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-civil-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --nature-of-suits-array: list<string> # Search can be narrowed down by passing Nature Of Suits. Please use the APPENDIX E - Civil Nature Of Suits mentioned in the API Documentation. Scenario: When mulitple nature of suits needs to be requested. Imagine for a given case number 12-1234 I would like to search with the nature of suit 110 (Insurance) and 140 (Negotiable Instrument), My query in the request will look like the example mentioned below. Example: natureOfSuitsArray=110&natureOfSuitsArray=140
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "natureOfSuitsArray" $nature_of_suits_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/civilCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "natureOfSuitsArray": $nature_of_suits_array, "courtRegionIdArray": $court_region_id_array, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/criminalCourts
# operationId: CriminalCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-criminal-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/criminalCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/multiDistrictCourts
# operationId: MultiDistrictCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-multi-district-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --jpml-number: int # Master JPML Case Number.
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Case Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "jpmlNumber" $jpml_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/multiDistrictCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "jpmlNumber": $jpml_number, "pacerCaseId": $pacer_case_id, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/allCourts
# operationId: AllCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-all-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "middleName" $middle_name "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $party_type "scalar") (serialize-qp "partyExactNameMatch" $party_exact_name_match "scalar") (serialize-qp "partyRoleArray" $party_role_array "multi") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseYearFrom" $case_year_from "scalar") (serialize-qp "caseYearTo" $case_year_to "scalar") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/allCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "lastName": $last_name, "firstName": $first_name, "middleName": $middle_name, "generation": $generation, "partyType": $party_type, "partyExactNameMatch": $party_exact_name_match, "partyRoleArray": $party_role_array, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseYearFrom": $case_year_from, "caseYearTo": $case_year_to, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/appealCourts
# operationId: AppealCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-appeal-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "middleName" $middle_name "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $party_type "scalar") (serialize-qp "partyExactNameMatch" $party_exact_name_match "scalar") (serialize-qp "partyRoleArray" $party_role_array "multi") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseYearFrom" $case_year_from "scalar") (serialize-qp "caseYearTo" $case_year_to "scalar") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/appealCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "lastName": $last_name, "firstName": $first_name, "middleName": $middle_name, "generation": $generation, "partyType": $party_type, "partyExactNameMatch": $party_exact_name_match, "partyRoleArray": $party_role_array, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseYearFrom": $case_year_from, "caseYearTo": $case_year_to, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/bankruptcyCourts
# operationId: BankruptcyCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-bankruptcy-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --ssn-or-ein: string # The 9 digit Social Security number or Federal Tax ID can be used in this search. The delimiter dash (-) can be used as the input to this API but wont be used during the search. A search for SSN 123-45-6789 or 12-3456789 will yield the same results as a search for 123456789. (nullable)
  --four-digit-ssn: string # Search for parties whose SSN ends with a specified four digits. Note: When specified, a last name/entity name must also be specified. (nullable)
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-discharged-start-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-discharged-end-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-dismissed-start-date: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case dismissed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --case-dismissed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "middleName" $middle_name "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $party_type "scalar") (serialize-qp "partyExactNameMatch" $party_exact_name_match "scalar") (serialize-qp "partyRoleArray" $party_role_array "multi") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseYearFrom" $case_year_from "scalar") (serialize-qp "caseYearTo" $case_year_to "scalar") (serialize-qp "ssnOrEin" $ssn_or_ein "scalar") (serialize-qp "fourDigitSsn" $four_digit_ssn "scalar") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "caseDischargedStartDate" $case_discharged_start_date "scalar") (serialize-qp "caseDischargedEndDate" $case_discharged_end_date "scalar") (serialize-qp "caseDismissedStartDate" $case_dismissed_start_date "scalar") (serialize-qp "caseDismissedEndDate" $case_dismissed_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/bankruptcyCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "lastName": $last_name, "firstName": $first_name, "middleName": $middle_name, "generation": $generation, "partyType": $party_type, "partyExactNameMatch": $party_exact_name_match, "partyRoleArray": $party_role_array, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseYearFrom": $case_year_from, "caseYearTo": $case_year_to, "ssnOrEin": $ssn_or_ein, "fourDigitSsn": $four_digit_ssn, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "caseDischargedStartDate": $case_discharged_start_date, "caseDischargedEndDate": $case_discharged_end_date, "caseDismissedStartDate": $case_dismissed_start_date, "caseDismissedEndDate": $case_dismissed_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/civilCourts
# operationId: CivilCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-civil-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "middleName" $middle_name "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $party_type "scalar") (serialize-qp "partyExactNameMatch" $party_exact_name_match "scalar") (serialize-qp "partyRoleArray" $party_role_array "multi") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseYearFrom" $case_year_from "scalar") (serialize-qp "caseYearTo" $case_year_to "scalar") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/civilCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "lastName": $last_name, "firstName": $first_name, "middleName": $middle_name, "generation": $generation, "partyType": $party_type, "partyExactNameMatch": $party_exact_name_match, "partyRoleArray": $party_role_array, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseYearFrom": $case_year_from, "caseYearTo": $case_year_to, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/criminalCourts
# operationId: CriminalCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-criminal-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "middleName" $middle_name "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $party_type "scalar") (serialize-qp "partyExactNameMatch" $party_exact_name_match "scalar") (serialize-qp "partyRoleArray" $party_role_array "multi") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseYearFrom" $case_year_from "scalar") (serialize-qp "caseYearTo" $case_year_to "scalar") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/criminalCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "pacerCaseId": $pacer_case_id, "lastName": $last_name, "firstName": $first_name, "middleName": $middle_name, "generation": $generation, "partyType": $party_type, "partyExactNameMatch": $party_exact_name_match, "partyRoleArray": $party_role_array, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseYearFrom": $case_year_from, "caseYearTo": $case_year_to, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/multiDistrictCourts
# operationId: MultiDistrictCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-multi-district-courts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacer-user-id: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacer-client-code: string # Client Code used while signing in to PACER account. (e.g. john)
  --case-number: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats: yy-nnnnn yy-tp-nnnnn yy tp nnnnn yytpnnnnn o:yy-nnnnn o:yy-tp-nnnnn o:yy tp nnnnn o:yytpnnnnn where: yy case year (may be 2 or 4 digits) nnnnn case number (up to 5 digits) tp case type (up to 2 characters) o office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --jpml-number: int # Master JPML Case Number.
  --pacer-case-id: int # Sequentially generated number that identifies the case in PACER system.
  --last-name: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --first-name: string # The first name of a party to search. (nullable, e.g. John)
  --middle-name: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --party-type: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --party-exact-name-match: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --party-role-array: list<string> # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --case-title: string # You can search using the case name even if you know one party. Examples: A search for case title john doe v will result in all cases with the case title John Doe v. A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --case-office: int # The divisional office in which the case was filed.
  --case-sequence-number: int # The sequence number of a given case. Ex 12345
  --case-year: int # The two digits or four digits of the year in which the case was filed.
  --case-type-array: list<string> # Search can be narrowed down by passing caseTypes. Please use the APPENDIX A: Case Types mentioned in the API Documentation. Scenario: When mulitple case types needs to be requested. Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below. Example: caseTypeArray=cv&caseTypeArray=cr
  --court-region-id-array: list<string> # Search can be narrowed down by passing courtRegionId. Please use the APPENDIX B: Court Regions mentioned in the API Documentation. Scenario: When mulitple court region ids needs to be requested. Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below. Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --case-year-from: int # Limit the results of the search to those cases from the year specified or later
  --case-year-to: int # Limit the results of the search to those cases from the year specified or earlier
  --case-filed-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-filed-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-start-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --case-terminated-end-date: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sort-parameter-query: string # The criteria based on which the search results are to be sorted. Please use the APPENDIX C: Sort Parameter - Sortable Party Parameters mentioned in the API Documentation. The fields can be sorted either ASC or DESC. Scenario 1: When mulitple sort paramters needs to be requested. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtId,ASC&caseId,ASC Scenario 2: When you want to sort the response using the case parameters in the party search. Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below. Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --case-status: string@case-status-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --page-number: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacer_user_id "scalar") (serialize-qp "pacerClientCode" $pacer_client_code "scalar") (serialize-qp "caseNumber" $case_number "scalar") (serialize-qp "jpmlNumber" $jpml_number "scalar") (serialize-qp "pacerCaseId" $pacer_case_id "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "middleName" $middle_name "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $party_type "scalar") (serialize-qp "partyExactNameMatch" $party_exact_name_match "scalar") (serialize-qp "partyRoleArray" $party_role_array "multi") (serialize-qp "caseTitle" $case_title "scalar") (serialize-qp "caseOffice" $case_office "scalar") (serialize-qp "caseSequenceNumber" $case_sequence_number "scalar") (serialize-qp "caseYear" $case_year "scalar") (serialize-qp "caseTypeArray" $case_type_array "multi") (serialize-qp "courtRegionIdArray" $court_region_id_array "multi") (serialize-qp "caseYearFrom" $case_year_from "scalar") (serialize-qp "caseYearTo" $case_year_to "scalar") (serialize-qp "caseFiledStartDate" $case_filed_start_date "scalar") (serialize-qp "caseFiledEndDate" $case_filed_end_date "scalar") (serialize-qp "caseTerminatedStartDate" $case_terminated_start_date "scalar") (serialize-qp "caseTerminatedEndDate" $case_terminated_end_date "scalar") (serialize-qp "sortParameterQuery" $sort_parameter_query "scalar") (serialize-qp "caseStatus" $case_status "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/multiDistrictCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pacerUserId": $pacer_user_id, "pacerClientCode": $pacer_client_code, "caseNumber": $case_number, "jpmlNumber": $jpml_number, "pacerCaseId": $pacer_case_id, "lastName": $last_name, "firstName": $first_name, "middleName": $middle_name, "generation": $generation, "partyType": $party_type, "partyExactNameMatch": $party_exact_name_match, "partyRoleArray": $party_role_array, "caseTitle": $case_title, "caseOffice": $case_office, "caseSequenceNumber": $case_sequence_number, "caseYear": $case_year, "caseTypeArray": $case_type_array, "courtRegionIdArray": $court_region_id_array, "caseYearFrom": $case_year_from, "caseYearTo": $case_year_to, "caseFiledStartDate": $case_filed_start_date, "caseFiledEndDate": $case_filed_end_date, "caseTerminatedStartDate": $case_terminated_start_date, "caseTerminatedEndDate": $case_terminated_end_date, "sortParameterQuery": $sort_parameter_query, "caseStatus": $case_status, "pageNumber": $page_number} | compact), body: null}
}

# Get Pacer Credential List.
#
# GET /pacerCredential
# operationId: getPacerCredential
export def "pacer-credential list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number of the PACER credentials to be retrieved. - Minimum: 1 (e.g. 1)
]: nothing -> record<nextPageAPI: string, object: string, pacerCredentialArray: table<defaultPacerClientCode: string, object: string, pacerUserId: string>, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCredential" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}

# Add Pacer Credential.
#
# PUT /pacerCredential
# operationId: addPacerCredential
export def "pacer-credential create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-pacer-client-code: string # Pacer Client Code. (nullable, e.g. Test UniCourt API)
  pacer_user_id: string # Pacer User Id. (e.g. URKYwer3tyh5r56gq2)
  password: string # Password. (e.g. your password)
]: any -> record<message: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pacerCredential")
  let req_body = {"defaultPacerClientCode": $default_pacer_client_code, "pacerUserId": $pacer_user_id, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove Pacer credential for a specific Pacer User Id.
#
# DELETE /pacerCredential/{pacerUserId}
# operationId: removePacerCredentialById
export def "pacer-credential delete" [
  pacer_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pacer_user_id | is-empty) { error make --unspanned { msg: "path parameter 'pacerUserId' must be non-empty" } }
  let full_url = (build-url $base ({pacer_user_id: (encode-path-segment $pacer_user_id)} | format pattern "/pacerCredential/{pacer_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Pacer Credential for a requested pacer User Id.
#
# GET /pacerCredential/{pacerUserId}
# operationId: getPacerCredentialById
export def "pacer-credential get" [
  pacer_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultPacerClientCode: string, object: string, pacerUserId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pacer_user_id | is-empty) { error make --unspanned { msg: "path parameter 'pacerUserId' must be non-empty" } }
  let full_url = (build-url $base ({pacer_user_id: (encode-path-segment $pacer_user_id)} | format pattern "/pacerCredential/{pacer_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets details for a requested Party ID.
#
# GET /party/{partyId}
# operationId: getPartyById
export def "party get" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyRepresentationType: record<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>, contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: list<record>, totalCount: int, totalPages: int>, partyClassificationType: string, partyId: string, partyRole: record<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>, possibleNormPartyArray: table<associatedNormAttorneysAPI: string, associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, bestMatch: bool, caseCountAnalyticsByNormPartyAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, confidenceScore: float, normPartyAPI: string, normPartyId: string, normPartyName: string, object: string, scoreConstituents: record>, sourcePartyRole: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/party/{party_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets Associated Attorney details for a requested Party ID.
#
# GET /party/{partyId}/associatedAttorneys
# operationId: getPartyAssociatedAttorneys
export def "party-associated-attorneys get" [
  party_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: table<attorneyId: string, isVisible: bool, object: string, partyAttorneyAssociationId: string, partyId: string>, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($party_id | is-empty) { error make --unspanned { msg: "path parameter 'partyId' must be non-empty" } }
  let qp = [(serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({party_id: (encode-path-segment $party_id)} | format pattern "/party/{party_id}/associatedAttorneys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNumber": $page_number} | compact), body: null}
}
