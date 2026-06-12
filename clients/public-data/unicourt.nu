# Auto-generated client for UniCourt Enterprise APIs v1.0.0
# Source: https://api.apis.guru/v2/specs/unicourt.com/1.0.0/openapi.json
# Auth: --token flag or $env.UNICOURT_ENTERPRISE_APIS_TOKEN

const BASE_URL = "https://enterpriseapi.unicourt.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o UNICOURT_ENTERPRISE_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://enterpriseapi.unicourt.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["COMPLETE" "FAILURE" "IN_PROGRESS"] }
def sortBy-completer [] { ["latest to oldest" "oldest to latest"] }
def partyClassificationType-completer [] { ["COMPANY" "INDIVIDUAL" "OTHER"] }
def groupBy-completer [] { ["Monthly" "Quarterly" "Weekly" "Yearly"] }
def sort-completer [] { ["filedDate" "relevancy"] }
def order-completer [] { ["asc" "desc"] }
def sort-completer-1 [] { ["name"] }
def sort-completer-2 [] { ["state"] }
def caseStatus-completer [] { ["closed" "open"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  attorneyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyId: string, attorneyLawFirmArray: table<attorneyLawFirmId: string, firstFetchDate: string, isVisible: bool, lastFetchDate: string, name: string, object: string>, attorneyType: record<attorneyTypeId: string, createdDate: string, name: string, object: string>, barNumber: string, contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: list<record>, totalCount: int, totalPages: int>, partyRoleGroupIdArray: list<string>, partyRoleIdArray: list<string>, possibleNormAttorneyArray: table<associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, confidenceScore: float, normAttorneyAPI: string, normAttorneyId: string, normAttorneyName: string, object: string, scoreConstituents: record>, possibleNormLawFirmArray: table<associatedNormAttorneyAPI: string, associatedNormJudgeAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, confidenceScore: float, normLawFirmAPI: string, normLawFirmId: string, normLawFirmName: string, object: string, scoreConstituents: record, sourceDetails: record>, sourceAttorneyType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/attorney/($attorneyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Associated Party details for a requested Attorney ID.
#
# GET /attorney/{attorneyId}/associatedParties
# operationId: getAttorneyAssociatedParties
export def "attorney-associated-parties get" [
  attorneyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: table<attorneyId: string, isVisible: bool, object: string, partyAttorneyAssociationId: string, partyId: string>, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/attorney/($attorneyId)/associatedParties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Specify the billing cycle to know the API usage.
#
# GET /billingCycleUsage/{billingCycle}
# operationId: getBillingUsageByBillingCycle
export def "billing-cycle-usage get" [
  billingCycle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiCallsBillable: record<count: int, lastUpdated: string>, apiCallsCredited: record<count: int, lastUpdated: string>, apiCallsMade: record<count: int, lastUpdated: string>, apiUsage: record, billingCycle: record<endDate: string, startDate: string>, days: record, object: string, totalCasesTracked: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/billingCycleUsage/($billingCycle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billingCycleArray: list<string>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billingCycles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets case information for a requested Case ID.
#
# GET /case/{caseId}
# operationId: getCase
export def "case get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneys: record<attorneyArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list<string>, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: table<causeOfAction: record, causeOfActionAdditionalDataArray: list, object: string>, chargeArray: table<charge: record, chargeAdditionalDataArray: list, chargeDegree: record, chargeSeverity: record, object: string>, court: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list<record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list<record>, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list<record>, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list<record>, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list<record>, sourceChargeArray: list<record>, sourceCourt: string, sourcePageData: list<record>>, sourceDataStatus: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/case/($caseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Attorneys for a requested Case ID.
#
# GET /case/{caseId}/attorneys
# operationId: getCaseAttorneys
export def "case-attorneys get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isVisible: oneof<nothing, bool> # Retrieve attorneys in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<attorneyArray: table<attorneyId: string, attorneyLawFirmArray: list, attorneyType: record, barNumber: string, contact: record, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record, partyRoleGroupIdArray: list, partyRoleIdArray: list, possibleNormAttorneyArray: list, possibleNormLawFirmArray: list, sourceAttorneyType: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isVisible" $isVisible "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/attorneys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Docket Entries for a requested Case ID.
#
# GET /case/{caseId}/docketEntries
# operationId: getCaseDocketEntries
export def "case-docket-entries get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --docketNumber: int # Retrieve the docket entry witih the specified docket number in the case with the specified caseId value.
  --sortBy: string@sortBy-completer # Sort the retrieved docket entries in ascending order or descending order of date.
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<docketEntryArray: table<boundary: string, docketBadge: string, docketEntryDate: string, docketEntryPrimaryDocuments: record, docketEntrySecondaryDocuments: record, docketNumber: int, lastFetchDate: string, object: string, referencedDocketNumberArray: list, sortOrder: int, text: string, textStructured: record>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "docketNumber" $docketNumber "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/docketEntries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Primary Documents of Docket Entries.
#
# GET /case/{caseId}/docketEntries/primaryDocuments
# operationId: getPrimaryDocumentsForDocketEntries
export def "case-docket-entries-primary-documents get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --docketNumber: int # Retrieve the primary documents associated with the specified docket number in the case with the specified caseId value.
  --inLibrary: oneof<nothing, bool> # Retrieve the primary documents in the with the specified inLibrary flag in the case with the specified caseId value. (allows empty value)
  --afterFirstFetchDate: string # Retrieve all primary documents in the case with the specified caseId value that were first fetched by UniCourt on the specified date or within the specified date. (nullable, format: date-time)
  --libraryDate: string # Retrieve all primary documents in the case with the specified caseId value that were added to the Crowdsourced Library on the specified date or within the specified date. (nullable, format: date-time)
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "docketNumber" $docketNumber "scalar") (serialize-qp "inLibrary" $inLibrary "scalar") (serialize-qp "afterFirstFetchDate" $afterFirstFetchDate "scalar") (serialize-qp "libraryDate" $libraryDate "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/docketEntries/primaryDocuments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Secondary Documents of Docket Entries.
#
# GET /case/{caseId}/docketEntries/secondaryDocuments
# operationId: getSecondaryDocumentsForDocketEntries
export def "case-docket-entries-secondary-documents get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --docketNumber: int # Retrieve the secondary documents associated with the specified docket number in the case with the specified caseId value.
  --inLibrary: oneof<nothing, bool> # Retrieve the secondary documents in the with the specified inLibrary flag in the case with the specified caseId value. (allows empty value)
  --afterFirstFetchDate: string # Retrieve all secondary documents in the case with the specified caseId value that were first fetched by UniCourt on the specified date or within the specified date. (nullable, format: date-time)
  --libraryDate: string # Retrieve all secondary documents in the case with the specified caseId value that were added to the Crowdsourced Library on the specified date or within the specified date. (nullable, format: date-time)
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "docketNumber" $docketNumber "scalar") (serialize-qp "inLibrary" $inLibrary "scalar") (serialize-qp "afterFirstFetchDate" $afterFirstFetchDate "scalar") (serialize-qp "libraryDate" $libraryDate "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/docketEntries/secondaryDocuments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Documents for a requested Case ID.
#
# GET /case/{caseId}/documents
# operationId: getCaseDocuments
export def "case-documents get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inLibrary: oneof<nothing, bool> # Filter all the documents those are added to the UniCourt library. (allows empty value)
  --afterFirstFetchDate: string # Get all the documents which were added to the case on or after a specific date. (nullable, format: date-time)
  --libraryDate: string # Sort all the documents based on the date when the document was added to the UniCourt Library. (nullable, format: date-time)
  --firstFetchDate: string # Sort all the documents based on the date it was fetched from the source site. (nullable, format: date-time)
  --sortBy: string@sortBy-completer # Sort documents with document order.
  --pageNumber: int # The page for which the result should be retrieved.
]: nothing -> record<caseDocumentArray: table<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record, price: float, sortOrder: int, sourceDataStatus: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inLibrary" $inLibrary "scalar") (serialize-qp "afterFirstFetchDate" $afterFirstFetchDate "scalar") (serialize-qp "libraryDate" $libraryDate "scalar") (serialize-qp "firstFetchDate" $firstFetchDate "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Hearings for a requested Case ID.
#
# GET /case/{caseId}/hearings
# operationId: getCaseHearings
export def "case-hearings get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sortBy: string@sortBy-completer # Specify the sort order of hearings in the case with the specified caseId.
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. (e.g. 1)
]: nothing -> record<hearingArray: table<firstFetchDate: string, hearingDate: string, hearingDescription: string, hearingStructured: record, lastFetchDate: string, location: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/hearings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Judges for a requested Case ID.
#
# GET /case/{caseId}/judges
# operationId: getCaseJudges
export def "case-judges get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isVisible: oneof<nothing, bool> # Retrieve attorneys judges in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<judgeArray: table<contact: record, firstFetchDate: string, firstName: string, isVisible: bool, judgeId: string, judgeType: record, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, possibleNormJudgeArray: list, sourceJudgeType: string>, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isVisible" $isVisible "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/judges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Parties for a requested Case ID.
#
# GET /case/{caseId}/parties
# operationId: getCaseParties
export def "case-parties get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isVisible: oneof<nothing, bool> # Retrieve parties in the case with the specified caseId value whose isVisible flag is set to the specified value. (allows empty value)
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
  --partyRoleId: string # Retrieve all parties with the specified partyRoleId value in the case with the specified caseId value. (allows empty value)
  --partyRoleGroupId: string # Retrieve all parties with the specified partyRoleGroupId value in the case with the specified caseId value. (allows empty value)
  --attorneyRepresentationTypeId: string # Retrieve all parties with the specified attorneyRepresentationTypeId value in the case with the specified caseId value. (allows empty value)
  --partyClassificationType: string@partyClassificationType-completer # Retrieve all parties with the specified partyClassificationType value in the case with the specified caseId value. (allows empty value)
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyArray: table<attorneyRepresentationType: record, contact: record, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record, partyClassificationType: string, partyId: string, partyRole: record, possibleNormPartyArray: list, sourcePartyRole: string>, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isVisible" $isVisible "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "partyRoleId" $partyRoleId "scalar") (serialize-qp "partyRoleGroupId" $partyRoleGroupId "scalar") (serialize-qp "attorneyRepresentationTypeId" $attorneyRepresentationTypeId "scalar") (serialize-qp "partyClassificationType" $partyClassificationType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/parties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Related Cases for a requested Case ID.
#
# GET /case/{caseId}/relatedCases
# operationId: getCaseRelatedCases
export def "case-related-cases get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: table<additionalSourceData: record, caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseRelationshipType: record, isVisible: bool, object: string, sourceCaseRelationshipType: string>, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/case/($caseId)/relatedCases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<areaOfLaw: record, caseCount: int, caseSearchAPI: string, object: string>, totalAreaOfLawCount: int, totalCaseCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByAreaOfLaw" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseClass: record, caseCount: int, caseSearchAPI: string, object: string>, totalCaseClassCount: int, totalCaseCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCaseClass" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
  --groupBy: string@groupBy-completer # GroupBy
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, groupedBy: string, monthInt: int, monthString: string, object: string, quarter: string, weekOfMonth: int, weekOfYear: int, year: int>, totalCaseCount: int, totalCaseFiledDateCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "groupBy" $groupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCaseFiledDate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, caseType: record, object: string>, totalCaseCount: int, totalCaseTypeCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCaseType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, caseTypeGroup: record, object: string>, totalCaseCount: int, totalCaseTypeGroupCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCaseTypeGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, court: record, object: string>, totalCaseCount: int, totalCourtCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCourt" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, court: record, courtLocation: record, object: string>, totalCaseCount: int, totalCourtLocationCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCourtLocation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, courtSystem: record, object: string>, totalCaseCount: int, totalCourtSystemCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCourtSystem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, courtType: record, object: string>, totalCaseCount: int, totalCourtTypeCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByCourtType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<Geo: record, caseCount: int, caseSearchAPI: string, jurisdictionGeo: record, object: string>, totalCaseCount: int, totalJurisdictionGeoCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByJurisdictionGeo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normAttorneyId: string, normAttorneyName: string, object: string>, totalCaseCount: int, totalNormAttorneyCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByNormAttorney" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normJudgeId: string, normJudgeName: string, object: string>, totalCaseCount: int, totalNormJudgeCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByNormJudge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normLawFirmId: string, normLawFirmName: string, object: string>, totalCaseCount: int, totalNormLawFirmCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByNormLawFirm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normPartyId: string, normPartyName: string, object: string>, totalCaseCount: int, totalNormPartyCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByNormParty" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, object: string, partyRole: record>, totalCaseCount: int, totalPages: int, totalPartyRoleCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByPartyRole" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, object: string, partyRoleGroup: record>, totalCaseCount: int, totalPages: int, totalPartyRoleGroupCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseCountAnalyticsByPartyRoleGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets details for a requested Document ID.
#
# GET /caseDocument/{caseDocumentId}
# operationId: getDocumentById
export def "case-document get" [
  caseDocumentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/caseDocument/($caseDocumentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets downloadable URL for a requested Document ID.
#
# GET /caseDocumentDownload/{caseDocumentId}
# operationId: getCaseDocumentDownloadById
export def "case-document-download get" [
  caseDocumentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isPreviewDocument: oneof<nothing, bool> # If the document you want to download is a preview of a document. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPreviewDocument" $isPreviewDocument "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/caseDocumentDownload/($caseDocumentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Case Document Order for requested Document Ids.
#
# PUT /caseDocumentOrder
# operationId: orderCaseDocument
# --pacerOptions shape: {pacerClientCode?: string, pacerUserId: string}
export def "case-document-order orderCaseDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  caseDocumentId: string # Document ID which you want to order. (e.g. CDOCcre989d654fa05)
  --isPreviewOnly: oneof<nothing, bool> # Flag value to determine if the document order is a preview order or no. (e.g. true)
  --pacerOptions: record # **Applicable for PACER cases.** — shape: {pacerClientCode?: string, pacerUserId: string}
]: any -> record<callbackGeneratedDate: string, caseDocument: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/caseDocumentOrder")
  let body = {caseDocumentId: $caseDocumentId, isPreviewOnly: $isPreviewOnly, pacerOptions: $pacerOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date for which fetch the Case Document Order Callback list. By default, the date will be set to current date. (format: date-time)
  --status: string@status-completer # Status of Document Order callbacks. Default status will fetch all callbacks.
  --pageNumber: int # Page to fetch the Case Document Order Callback list.<br>   - Minimum: 1  (default: 1)
]: nothing -> record<callbackArray: table<callbackGeneratedDate: string, caseDocument: record, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record, file: record, object: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseDocumentOrder/callbacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Case Document Order Callback for a requested Case Document Order Callback Id.
#
# GET /caseDocumentOrder/callbacks/{caseDocumentOrderCallbackId}
# operationId: getCaseDocumentOrderCallbackById
export def "case-document-order-callbacks get" [
  caseDocumentOrderCallbackId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callbackGeneratedDate: string, caseDocument: record<addedToLibraryDate: string, caseDocumentId: string, childDocumentIdArray: list<string>, description: string, documentFiledDate: string, downloadAPI: string, estimatedOrderDuration: string, firstFetchDate: string, inLibrary: bool, isPreviewAvailable: bool, name: string, object: string, pages: int, parentDocumentId: string, previewDocument: record<addedToLibraryDate: string, downloadAPI: string, inLibrary: bool, object: string>, price: float, sortOrder: int, sourceDataStatus: string>, caseDocumentId: string, caseDocumentOrderCallbackAPI: string, caseDocumentOrderCallbackId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/caseDocumentOrder/callbacks/($caseDocumentOrderCallbackId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for which callbacks are to be retrieved. (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --status: string@status-completer # The status code of the callbacks to be retrieved.
  --pageNumber: int # The page number of the callbacks to be retrieved.<br>   - Minimum: 1  (default: 1, e.g. 1)
]: nothing -> record<callbackArray: table<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record, file: record, object: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseExport/callbacks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Case Export Callback for a requested Case Export Callback Id.
#
# GET /caseExport/callbacks/{caseExportCallbackId}
# operationId: getCaseExportCallbackById
export def "case-export-callbacks get" [
  caseExportCallbackId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/caseExport/callbacks/($caseExportCallbackId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets case exported for a requested Case ID.
#
# GET /caseExport/{caseId}
# operationId: exportCase
export def "case-export exportCase" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callbackGeneratedDate: string, caseExportCallbackAPI: string, caseExportCallbackId: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, file: record<expiryDate: string, fileUrl: string, name: string, object: string>, object: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/caseExport/($caseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Case search.
#
# GET /caseSearch
# operationId: searchCases
export def "case-search searchCases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query parameter for keyword expressions.</a>
  --qp-sort: string@sort-completer # Query parameter specifying how results are to be sorted. Results can be sorted according to filedDate or relevancy. (default: filedDate, e.g. filedDate)
  --order: string@order-completer # Query parameter specifying whether search result are sorted in ascending or descending order. (default: desc, e.g. desc)
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<caseSearchId: string, caseSearchResultArray: table<caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseStatus: record, caseType: record, court: record, courtLocation: record, filedDate: string, firstFetchDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, matchedObjectArray: list, object: string, participantsLastFetchDate: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseSearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Case search results for a given caseSearchId.
#
# GET /caseSearch/{caseSearchId}
# operationId: searchCasesById
export def "case-search searchCasesById" [
  caseSearchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<caseSearchId: string, caseSearchResultArray: table<caseAPI: string, caseId: string, caseName: string, caseNumber: string, caseStatus: record, caseType: record, court: record, courtLocation: record, filedDate: string, firstFetchDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, matchedObjectArray: list, object: string, participantsLastFetchDate: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/caseSearch/($caseSearchId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Case Track for the requested Case Id.
#
# PUT /caseTrack
# operationId: trackCase
# --caseTrackParams shape: {caseId: string, pacerOptions?: record}
# --schedule shape: {days: list, type: "daily"|"weekly"|"monthly"}
export def "case-track trackCase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  caseTrackParams: record # shape: {caseId: string, pacerOptions?: record}
  schedule: record # shape: {days: list, type: "daily"|"weekly"|"monthly"}
]: any -> record<message: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/caseTrack")
  let body = {caseTrackParams: $caseTrackParams, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Case Track for a specific Case Id.
#
# DELETE /caseTrack/{caseId}
# operationId: removeCaseTrackById
export def "case-track removeCaseTrackById" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/caseTrack/($caseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Case Track for a requested Case Id.
#
# GET /caseTrack/{caseId}
# operationId: getCaseTrackById
export def "case-track get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, lastFetchDate: string, lastFetchDateWithUpdates: string, lastTrackedDetails: record<lastTrackDate: string, lastTrackException: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, schedule: record<days: list<int>, object: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/caseTrack/($caseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --lastFetchDate: string # The lastFetchDate value of the tracked case. The date value should be entered in the format YYYY-MM-DDTHH:MM:SS+ZZ:zz.  (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --lastFetchDateWithUpdates: string # The date on which changes were last found in the case information.  (format: date-time, e.g. 2022-03-08T10:17:56+00:00)
  --pageNumber: int # The page number of the results to be retrieved.<br>   - Minimum: 1  (e.g. 1)
]: nothing -> record<caseTrackPreviewArray: table<caseAPI: string, caseId: string, lastFetchDate: string, lastFetchDateWithUpdates: string, lastTrackedDetails: record, object: string, pacerOptions: record, schedule: record>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lastFetchDate" $lastFetchDate "scalar") (serialize-qp "lastFetchDateWithUpdates" $lastFetchDateWithUpdates "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseTracks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Case Update for the requested Case Id.
#
# PUT /caseUpdate
# operationId: updateCase
# --pacerOptions shape: {additionalPageArray?: list, fetchParticipantsIfOlderThanDays?: int, pacerClientCode?: string, pacerUserId: string, refreshType?: "fetchNewDocketEntries"|"fetchAllDocketEntries"}
export def "case-update updateCase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  caseId: string # UniCourt's Case Id for update. (e.g. CASEhq9d8b72d0800c)
  --pacerOptions: record # Applicable for PACER cases. — shape: {additionalPageArray?: list, fetchParticipantsIfOlderThanDays?: int, pacerClientCode?: string, pacerUserId: string, refreshType?: "fetchNewDocketEntries"|"fetchAllDocketEntries"}
]: any -> record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, requestedDate: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/caseUpdate")
  let body = {caseId: $caseId, pacerOptions: $pacerOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Case Updates for a requested CaseId.
#
# GET /caseUpdate/{caseId}
# operationId: getCaseUpdateByCaseId
export def "case-update get" [
  caseId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<case: record<attorneys: record<attorneyArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseDocuments: record<caseDocumentArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, caseId: string, caseName: string, caseNumber: string, caseStats: record<allCaseDocumentCount: int, attorneyCount: int, caseDocumentInLibraryCount: int, docketEntryCount: int, freeCaseDocumentCount: int, hearingCount: int, judgeCount: int, object: string, paidCaseDocumentCount: int, partyCount: int, relatedCaseCount: int>, caseStatus: record<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, caseType: record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, causeOfActionArray: list<record>, chargeArray: list<record>, court: record<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, courtLocation: record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, courtServiceStatusAPI: string, courtServiceStatusId: string, docketEntries: record<docketEntryArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, exportAPI: string, filedDate: string, firstFetchDate: string, hasDocumentsWithPreview: bool, hasOnlyMetaInfo: bool, hearings: record<hearingArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, judges: record<judgeArray: list, nextPageAPI: string, object: string, pageNumber: int, totalCount: int, totalPages: int>, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, participantsLastFetchDate: string, parties: record<nextPageAPI: string, object: string, pageNumber: int, partyArray: list, totalCount: int, totalPages: int>, relatedCases: record<nextPageAPI: string, object: string, pageNumber: int, relatedCaseArray: list, totalCount: int, totalPages: int>, sourceCaseData: record<natureOfSuitArray: list, object: string, sourceCaseStatus: string, sourceCaseType: string, sourceCauseOfActionArray: list, sourceChargeArray: list, sourceCourt: string, sourcePageData: list>, sourceDataStatus: string, url: string>, caseAPI: string, caseId: string, exception: record<code: string, details: string, message: string, object: string>, object: string, pacerOptions: record<additionalPageArray: list<record>, fetchParticipantsIfOlderThanDays: int, object: string, pacerClientCode: string, pacerUserId: string, refreshType: string>, requestedDate: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/caseUpdate/($caseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Case Update  list for a requested Date.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --caseId: string # The caseId value of the case for which updates should be retrieved.
  --requestedDate: string # The date for which case updates are to be retrieved. (format: date-time)
  --status: string@status-completer # Status of the case updates to be retrieved.
  --pageNumber: int # The page number of the callbacks to be retrieved.<br>   - Minimum: 1  (default: 1, e.g. 1)
]: nothing -> record<caseUpdatePreviewArray: table<caseAPI: string, caseId: string, exception: record, object: string, pacerOptions: record, requestedDate: string, status: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "caseId" $caseId "scalar") (serialize-qp "requestedDate" $requestedDate "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/caseUpdates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Court Coverage of all courts of specific type.
#
# GET /courtCoverage/{courtId}
# operationId: getCourtCoverage
export def "court-coverage get" [
  courtId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseClassCoverageArray: table<caseClass: record, caseCount: int, caseDocumentInLibraryCount: int, caseDocumentInLibraryInLastThirtyDaysCount: int, casesInLastThirtyDaysCount: int, courtServiceStatusAPI: string, freeCaseDocumentCount: int, freeCaseDocumentsInLastThirtyDaysCount: int, object: string, paidCaseDocumentCount: int, paidCaseDocumentsInLastThirtyDaysCount: int>, court: record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, lastUpdateCountDate: string, object: string, totalCaseCount: int, totalCaseDocumentInLibraryCount: int, totalCaseDocumentInLibraryInLastThirtyDaysCount: int, totalCasesInLastThirtyDaysCount: int, totalFreeCaseDocumentCount: int, totalFreeCaseDocumentsInLastThirtyDaysCount: int, totalPaidCaseDocumentCount: int, totalPaidCaseDocumentsInLastThirtyDaysCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/courtCoverage/($courtId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiCallsBillable: record<count: int, lastUpdated: string>, apiCallsCredited: record<count: int, lastUpdated: string>, apiCallsMade: record<count: int, lastUpdated: string>, apiUsage: record, object: string, usageEndTime: string, usageStartTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dailyUsage/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate new token to access API.
#
# POST /generateNewToken
# operationId: generateNewToken
export def "generate-new-token generateNewToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clientId: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  clientSecret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> record<accessToken: string, object: string, tokenId: string, tokenType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/generateNewToken")
  let body = {clientId: $clientId, clientSecret: $clientSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# API to invalidate all access tokens.
#
# PUT /invalidateAllTokens
# operationId: invalidateAllTokens
export def "invalidate-all-tokens invalidateAllTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clientId: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  clientSecret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> record<message: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invalidateAllTokens")
  let body = {clientId: $clientId, clientSecret: $clientSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# API to invalidate the access token.
#
# PUT /invalidateToken
# operationId: invalidateToken
export def "invalidate-token invalidateToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clientId: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  clientSecret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
  tokenId: string # The Token ID of token being invalidated (e.g. TKID384a057WFC3Dp3)
]: any -> record<message: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invalidateToken")
  let body = {clientId: $clientId, clientSecret: $clientSecret, tokenId: $tokenId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets details for a requested Judge ID.
#
# GET /judge/{judgeId}
# operationId: getJudgeById
export def "judge get" [
  judgeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, judgeId: string, judgeType: record<createdDate: string, judgeTypeId: string, name: string, object: string>, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, possibleNormJudgeArray: table<associatedNormAttorneysAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, bestMatch: bool, caseCountAnalyticsByNormJudgeAPI: string, confidenceScore: float, normJudgeAPI: string, normJudgeId: string, normJudgeName: string, object: string, scoreConstituents: record>, sourceJudgeType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/judge/($judgeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# API to list all the access tokens Id.
#
# PUT /listAllTokenIds
# operationId: listAllTokenIds
export def "list-all-token-ids listAllTokenIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clientId: string # Your Client ID obtainable by logging into your UniCourt account. (e.g. G3cfixgetVzfaoszGOBp5LPGtih1nMJ9)
  clientSecret: string # Your Client Secret ID obtainable by logging into your UniCourt account. (e.g. u6PTti57IjPlrwU5MzOwLBD2MCwx-IEbo8sTStTivh1I-EqQ8Jcm27Gfo2GhpHCw)
]: any -> record<AccessTokenIdArray: table<issueAddress: string, issuedDate: string, object: string, tokenId: string>, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/listAllTokenIds")
  let body = {clientId: $clientId, clientSecret: $clientSecret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<areaOfLawArray: table<areaOfLawId: string, caseClass: string, caseClassId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/areaOfLaw" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AreaOfLaw Object for the given AreaOfLaw Id.
#
# GET /masterData/areaOfLaw/{areaOfLawId}
# operationId: getAreaOfLaw
export def "master-data-area-of-law get" [
  areaOfLawId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<areaOfLawId: string, caseClass: string, caseClassId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/areaOfLaw/($areaOfLawId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<attorneyRepresentationTypeArray: table<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/attorneyRepresentationType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attorney Representation Type Object for the given attorneyRepresentationTypeId.
#
# GET /masterData/attorneyRepresentationType/{attorneyRepresentationTypeId}
# operationId: getAttorneyRepresentationType
export def "master-data-attorney-representation-type get" [
  attorneyRepresentationTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/attorneyRepresentationType/($attorneyRepresentationTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<attorneyTypeArray: table<attorneyTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/attorneyType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attorney Type Object for given Attorney Type Id.
#
# GET /masterData/attorneyType/{attorneyTypeId}
# operationId: getAttorneyType
export def "master-data-attorney-type get" [
  attorneyTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/attorneyType/($attorneyTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseClassArray: table<caseClassId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseClass" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Case Class Object for the given Case Class Id.
#
# GET /masterData/caseClass/{caseClassId}
# operationId: getCaseClass
export def "master-data-case-class get" [
  caseClassId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseClassId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/caseClass/($caseClassId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseRelationshipTypeArray: table<caseRelationshipTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseRelationshipType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Case Relationship Type Object for the given caseRelationshipTypeId.
#
# GET /masterData/caseRelationshipType/{caseRelationshipTypeId}
# operationId: getCaseRelationshipType
export def "master-data-case-relationship-type get" [
  caseRelationshipTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseRelationshipTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/caseRelationshipType/($caseRelationshipTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseStatusArray: table<caseClassArray: list, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the caseStatus information for the given caseStatusId.
#
# GET /masterData/caseStatus/{caseStatusId}
# operationId: getCaseStatus
export def "master-data-case-status get" [
  caseStatusId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseClassArray: list<string>, caseStatusGroup: string, caseStatusGroupId: string, caseStatusId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/caseStatus/($caseStatusId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseStatusGroupArray: table<caseStatusGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseStatusGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the caseStatusGroup information for the given caseStatusGroupId.
#
# GET /masterData/caseStatusGroup/{caseStatusGroupId}
# operationId: getCaseStatusGroup
export def "master-data-case-status-group get" [
  caseStatusGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseStatusGroupId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/caseStatusGroup/($caseStatusGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseTypeArray: table<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CaseType Object for given Case Type Id.
#
# GET /masterData/caseType/{caseTypeId}
# operationId: getCaseType
export def "master-data-case-type get" [
  caseTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroup: string, caseTypeGroupId: string, caseTypeId: string, caseTypeTag: string, createdDate: string, name: string, object: string, saliCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/caseType/($caseTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<caseTypeGroupArray: table<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/caseTypeGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CaseType Group for the given CaseType Group Id.
#
# GET /masterData/caseTypeGroup/{caseTypeGroupId}
# operationId: getCaseTypeGroup
export def "master-data-case-type-group get" [
  caseTypeGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<areaOfLaw: string, areaOfLawId: string, caseClass: string, caseClassId: string, caseTypeGroupId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/caseTypeGroup/($caseTypeGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<causeOfActionArray: table<causeOfActionGroup: string, causeOfActionGroupId: string, causeOfActionId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/causeOfAction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CauseOfAction Object for the given causeOfActionId.
#
# GET /masterData/causeOfAction/{causeOfActionId}
# operationId: getCauseOfAction
export def "master-data-cause-of-action get" [
  causeOfActionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<causeOfActionGroup: string, causeOfActionGroupId: string, causeOfActionId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/causeOfAction/($causeOfActionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<causeOfActionAdditionalDataArray: table<causeOfActionAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/causeOfActionAdditionalData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CauseOfActionAdditionalData Object for the given causeOfActionAdditionalDataId.
#
# GET /masterData/causeOfActionAdditionalData/{causeOfActionAdditionalDataId}
# operationId: getCauseOfActionAdditionalData
export def "master-data-cause-of-action-additional-data get" [
  causeOfActionAdditionalDataId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<causeOfActionAdditionalDataId: string, createdDate: string, object: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/causeOfActionAdditionalData/($causeOfActionAdditionalDataId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<causeOfActionGroupArray: table<causeOfActionGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/causeOfActionGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CauseOfActionGroup Object for the given causeOfActionGroupId.
#
# GET /masterData/causeOfActionGroup/{causeOfActionGroupId}
# operationId: getCauseOfActionGroup
export def "master-data-cause-of-action-group get" [
  causeOfActionGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<causeOfActionGroupId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/causeOfActionGroup/($causeOfActionGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeArray: table<chargeGroup: string, chargeGroupId: string, chargeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/charge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Charge Object for the given chargeId.
#
# GET /masterData/charge/{chargeId}
# operationId: getCharge
export def "master-data-charge get" [
  chargeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeGroup: string, chargeGroupId: string, chargeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/charge/($chargeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeAdditionalDataArray: table<chargeAdditionalDataId: string, createdDate: string, object: string, type: string, value: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/chargeAdditionalData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Charge Additional Data Object for the given chargeAdditionalDataId.
#
# GET /masterData/chargeAdditionalData/{chargeAdditionalDataId}
# operationId: getChargeAdditionalData
export def "master-data-charge-additional-data get" [
  chargeAdditionalDataId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeAdditionalDataId: string, createdDate: string, object: string, type: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/chargeAdditionalData/($chargeAdditionalDataId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeDegreeArray: table<chargeDegreeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/chargeDegree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ChargeDegree Object for the given chargeDegreeId.
#
# GET /masterData/chargeDegree/{chargeDegreeId}
# operationId: getChargeDegree
export def "master-data-charge-degree get" [
  chargeDegreeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeDegreeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/chargeDegree/($chargeDegreeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeGroupArray: table<chargeGroupId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/chargeGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Charge Group Object for the given chargeGroupId.
#
# GET /masterData/chargeGroup/{chargeGroupId}
# operationId: getChargeGroup
export def "master-data-charge-group get" [
  chargeGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeGroupId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/chargeGroup/($chargeGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<chargeSeverityArray: table<chargeSeverityId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/chargeSeverity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ChargeSeverity Object for the given chargeSeverityId.
#
# GET /masterData/chargeSeverity/{chargeSeverityId}
# operationId: getChargeSeverity
export def "master-data-charge-severity get" [
  chargeSeverityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chargeSeverityId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/chargeSeverity/($chargeSeverityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/court" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Court Object for given courtId.
#
# GET /masterData/court/{courtId}
# operationId: getCourt
export def "master-data-court get" [
  courtId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalLevels: record<level1: string, level2: string, level3: string, level4: string, object: string>, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/court/($courtId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Appeal Court Objects for given courtId.
#
# GET /masterData/court/{courtId}/appealCourts
# operationId: getAppealCourtsForCourt
export def "master-data-court-appeal-courts get" [
  courtId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/masterData/court/($courtId)/appealCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associated Court Location for given courtId.
#
# GET /masterData/court/{courtId}/courtLocations
# operationId: getCourtLocationsForCourt
export def "master-data-court-court-locations get" [
  courtId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtLocationArray: table<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/masterData/court/($courtId)/courtLocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Jurisdiction Geo Objects for given courtId.
#
# GET /masterData/court/{courtId}/jurisdictionGeo
# operationId: getJurisdictionGeoForCourt
export def "master-data-court-jurisdiction-geo get" [
  courtId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-2 # Sort field. (default: state, e.g. state)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<jurisdictionGeoArray: table<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/masterData/court/($courtId)/jurisdictionGeo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtLocationArray: table<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/courtLocation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Courthouse Object for given Court Location Id.
#
# GET /masterData/courtLocation/{courtLocationId}
# operationId: getCourtLocation
export def "master-data-court-location get" [
  courtLocationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<city: string, courtLocationId: string, courtServiceStatusAPI: string, courtsForCourtLocationAPI: string, createdDate: string, name: string, object: string, stateName: string, streetAddress1: string, streetAddress2: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/courtLocation/($courtLocationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associated Court for given Court Location.
#
# GET /masterData/courtLocation/{courtLocationId}/courts
# operationId: getCourtsForCourtLocation
export def "master-data-court-location-courts get" [
  courtLocationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/masterData/courtLocation/($courtLocationId)/courts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtServiceStatusArray: table<caseClassIdArray: list, caseDocumentOrderServiceStatus: record, caseTrackServiceStatus: record, caseUpdateServiceStatus: record, courtIdArray: list, courtLocationIdArray: list, courtServiceStatusId: string, object: string, serviceStatusAsOn: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/courtServiceStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Court Service Status Object for the given courtServiceStatusId.
#
# GET /masterData/courtServiceStatus/{courtServiceStatusId}
# operationId: getCourtServiceStatus
export def "master-data-court-service-status get" [
  courtServiceStatusId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseClassIdArray: list<string>, caseDocumentOrderServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, caseTrackServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, caseUpdateServiceStatus: record<object: string, serviceDetails: string, serviceStatusDownDetails: record<details: string, eta: string, object: string, reason: string>, serviceUp: bool>, courtIdArray: list<string>, courtLocationIdArray: list<string>, courtServiceStatusId: string, object: string, serviceStatusAsOn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/courtServiceStatus/($courtServiceStatusId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtSystemArray: table<courtSystemId: string, courtType: string, courtTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/courtSystem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Court System Object for given courtSystemId.
#
# GET /masterData/courtSystem/{courtSystemId}
# operationId: getCourtSystem
export def "master-data-court-system get" [
  courtSystemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<courtSystemId: string, courtType: string, courtTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/courtSystem/($courtSystemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtTypeArray: table<courtTypeId: string, createdDate: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/courtType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Court Type Object for given courtTypeId.
#
# GET /masterData/courtType/{courtTypeId}
# operationId: getCourtType
export def "master-data-court-type get" [
  courtTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<courtTypeId: string, createdDate: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/courtType/($courtTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<judgeTypeArray: table<createdDate: string, judgeTypeId: string, name: string, object: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/judgeType" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Judge Type Object for the given judgeTypeId.
#
# GET /masterData/judgeType/{judgeTypeId}
# operationId: getJudgeType
export def "master-data-judge-type get" [
  judgeTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: string, judgeTypeId: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/judgeType/($judgeTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-2 # Sort field. (default: state, e.g. state)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<jurisdictionGeoArray: table<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/jurisdictionGeo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Jurisdiction Geo Object for given Jurisdiction Geo Id.
#
# GET /masterData/jurisdictionGeo/{jurisdictionGeoId}
# operationId: getJurisdictionGeo
export def "master-data-jurisdiction-geo get" [
  jurisdictionGeoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<city: string, country: string, county: string, courtsForJurisdictionGeoAPI: string, createdDate: string, fipsCode: string, jurisdictionGeoId: string, object: string, state: string, zipCodeArray: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/jurisdictionGeo/($jurisdictionGeoId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associated Court for given Jurisdiction Geo.
#
# GET /masterData/jurisdictionGeo/{jurisdictionGeoId}/courts
# operationId: getCourtsForJurisdictionGeo
export def "master-data-jurisdiction-geo-courts get" [
  jurisdictionGeoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<courtArray: table<additionalLevels: record, appealCourtsForCourtAPI: string, container: string, containerType: string, courtId: string, courtLocationsForCourtAPI: string, courtServiceStatusAPI: string, courtSystemId: string, courtTypeId: string, createdDate: string, jurisdictionGeoForCourtAPI: string, name: string, nameAka: string, object: string, system: string, type: string>, nextPageAPI: string, object: string, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/masterData/jurisdictionGeo/($jurisdictionGeoId)/courts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyRoleArray: table<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/partyRole" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Party Role Object.
#
# GET /masterData/partyRole/{partyRoleId}
# operationId: getPartyRole
export def "master-data-party-role get" [
  partyRoleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/partyRole/($partyRoleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.</a>
  --pageNumber: int # Page number. - minimum: 1 - maximum: 100  (e.g. 1)
  --qp-sort: string@sort-completer-1 # Sort field. (default: name, e.g. name)
  --order: string@order-completer # Sort order. (default: asc, e.g. asc)
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyRoleGroupArray: table<createdDate: string, description: string, name: string, object: string, partyRoleGroupId: string>, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/masterData/partyRoleGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Party Role Group Object.
#
# GET /masterData/partyRoleGroup/{partyRoleGroupId}
# operationId: getPartyRoleGroup
export def "master-data-party-role-group get" [
  partyRoleGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: string, description: string, name: string, object: string, partyRoleGroupId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/masterData/partyRoleGroup/($partyRoleGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Norm Attorney Details.
#
# GET /normAttorney/{normAttorneyId}
# operationId: getNormAttorneyById
export def "norm-attorney get" [
  normAttorneyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyAnalyticsAPI: record<associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normAttorneyAPI: string, object: string>, barRecordArray: table<admittedDate: string, barNumber: string, barSourceData: record, barSourceType: string, contact: record, firstFetchDate: string, inactivationDate: string, lastFetchDate: string, lastFetchDateWithUpdates: string, object: string, stateCode: string, status: string>, caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, firstName: string, hasAssociatedPublicData: bool, lastName: string, middleName: string, name: string, normAttorneyId: string, object: string, similarNormAttorneyArray: table<barRecordPreviewArray: list, name: string, normAttorneyAPI: string, normAttorneyId: string, normAttorneySimilarityScore: float, object: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/normAttorney/($normAttorneyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Judges faced by the Attorney.
#
# GET /normAttorney/{normAttorneyId}/associatedNormJudges
# operationId: getNormJudgesAssociatedWithNormAttorney
export def "norm-attorney-associated-norm-judges get" [
  normAttorneyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normAttorney/($normAttorneyId)/associatedNormJudges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Law Firms the attorney has worked for.
#
# GET /normAttorney/{normAttorneyId}/associatedNormLawFirms
# operationId: getNormLawFirmsAssociatedWithNormAttorney
export def "norm-attorney-associated-norm-law-firms get" [
  normAttorneyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normAttorney/($normAttorneyId)/associatedNormLawFirms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Parties Represented By the Attorney.
#
# GET /normAttorney/{normAttorneyId}/associatedNormParties
# operationId: getNormPartiesAssociatedWithNormAttorney
export def "norm-attorney-associated-norm-parties get" [
  normAttorneyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normAttorney/($normAttorneyId)/associatedNormParties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Case Count Analytics by Opposing Norm Attorney.
#
# GET /normAttorney/{normAttorneyId}/caseCountAnalyticsByOpposingNormAttorney
# operationId: getCaseCountAnalyticsByOpposingNormAttorneyForANormAttorney
export def "norm-attorney-case-count-analytics-by-opposing-norm-attorney get" [
  normAttorneyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normAttorneyId: string, normAttorneyName: string, object: string>, totalCaseCount: int, totalNormAttorneyCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normAttorney/($normAttorneyId)/caseCountAnalyticsByOpposingNormAttorney" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attorney search.
#
# GET /normAttorneySearch
# operationId: searchNormalizedAttorneys
export def "norm-attorney-search searchNormalizedAttorneys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.</a>
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<nextPageAPI: string, normAttorneySearchId: string, normAttorneySearchResultArray: table<firstFetchDate: string, hasAssociatedPublicData: bool, lastFetchDate: string, matchedObjectArray: list, name: string, normAttorneyDetailsAPI: string, normAttorneyId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/normAttorneySearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Norm attorney search results for a given normAttorneySearchId.
#
# GET /normAttorneySearch/{normAttorneySearchId}
# operationId: searchNormalizedAttorneysById
export def "norm-attorney-search searchNormalizedAttorneysById" [
  normAttorneySearchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<nextPageAPI: string, normAttorneySearchId: string, normAttorneySearchResultArray: table<firstFetchDate: string, hasAssociatedPublicData: bool, lastFetchDate: string, matchedObjectArray: list, name: string, normAttorneyDetailsAPI: string, normAttorneyId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normAttorneySearch/($normAttorneySearchId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Norm Judge Details.
#
# GET /normJudge/{normJudgeId}
# operationId: getNormJudgeById
export def "norm-judge get" [
  normJudgeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, firstName: string, hasAssociatedPublicData: bool, judgeAnalyticsAPI: record<associatedNormAttorneysAPI: string, associatedNormLawFirmsAPI: string, associatedNormPartiesAPI: string, normJudgeAPI: string, object: string>, judicialDataArray: table<abaRatings: record, aliasArray: list, bio: record, contact: record, educationArray: list, firstFetchDate: string, judicialSource: record, judicialStatus: string, lastFetchDate: string, lastFetchDateWithUpdates: string, nameHistoryArray: list, object: string, professionalCareerArray: list, serviceHistoryArray: list>, lastName: string, middleName: string, name: string, normJudgeId: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/normJudge/($normJudgeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attorneys Associated with the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormAttorneys
# operationId: getNormAttorneysAssociatedWithNormJudge
export def "norm-judge-associated-norm-attorneys get" [
  normJudgeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normJudge/($normJudgeId)/associatedNormAttorneys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Law Firms Associated With the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormLawFirms
# operationId: getNormLawFirmsAssociatedWithNormJudge
export def "norm-judge-associated-norm-law-firms get" [
  normJudgeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normJudge/($normJudgeId)/associatedNormLawFirms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Parties Associated with the Judge.
#
# GET /normJudge/{normJudgeId}/associatedNormParties
# operationId: getNormPartiesAssociatedWithNormJudge
export def "norm-judge-associated-norm-parties get" [
  normJudgeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normJudge/($normJudgeId)/associatedNormParties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Judge search.
#
# GET /normJudgeSearch
# operationId: searchNormalizedJudges
export def "norm-judge-search searchNormalizedJudges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.</a>
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<nextPageAPI: string, normJudgeSearchId: string, normJudgeSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normJudgeDetailsAPI: string, normJudgeId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/normJudgeSearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Norm judge search results for a given normJudgeSearchId.
#
# GET /normJudgeSearch/{normJudgeSearchId}
# operationId: searchNormalizedJudgesById
export def "norm-judge-search searchNormalizedJudgesById" [
  normJudgeSearchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<nextPageAPI: string, normJudgeSearchId: string, normJudgeSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normJudgeDetailsAPI: string, normJudgeId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normJudgeSearch/($normJudgeSearchId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Norm LawFirm Details.
#
# GET /normLawFirm/{normLawFirmId}
# operationId: getNormLawFirmById
export def "norm-law-firm get" [
  normLawFirmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, lawFirmAnalyticsAPI: record<associatedNormAttorneyAPI: string, associatedNormJudgeAPI: string, associatedNormPartiesAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normLawFirmAPI: string, object: string>, name: string, normLawFirmId: string, normOrganizationData: record<cik: string, isInvolvedInLitigation: bool, lei: string, naics: string, naicsDescription: string, name: string, normCorporateGroupArray: list<record>, normOrganizationId: string, normPartyAPI: string, object: string, organizationType: string, sic: string, sicDescription: string, sosDataArray: list<record>, tickerArray: list<record>>, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/normLawFirm/($normLawFirmId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attorneys working for the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormAttorneys
# operationId: getNormAttorneysAssociatedWithNormLawFirm
export def "norm-law-firm-associated-norm-attorneys get" [
  normLawFirmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normLawFirm/($normLawFirmId)/associatedNormAttorneys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Judges Faced By the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormJudges
# operationId: getNormJudgesAssociatedWithNormLawFirm
export def "norm-law-firm-associated-norm-judges get" [
  normLawFirmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normLawFirm/($normLawFirmId)/associatedNormJudges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Parties Represented by the Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/associatedNormParties
# operationId: getNormPartiesAssociatedWithNormLawFirm
export def "norm-law-firm-associated-norm-parties get" [
  normLawFirmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormPartyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normPartyAPI: string, normPartyId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normLawFirm/($normLawFirmId)/associatedNormParties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Case Count Analytics by Opposing Norm Law Firm.
#
# GET /normLawFirm/{normLawFirmId}/caseCountAnalyticsByOpposingNormLawFirm
# operationId: getCaseCountAnalyticsByOpposingNormLawFirmForANormLawFirm
export def "norm-law-firm-case-count-analytics-by-opposing-norm-law-firm get" [
  normLawFirmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normLawFirmId: string, normLawFirmName: string, object: string>, totalCaseCount: int, totalNormLawFirmCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normLawFirm/($normLawFirmId)/caseCountAnalyticsByOpposingNormLawFirm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Law firm search.
#
# GET /normLawFirmSearch
# operationId: searchNormalizedLawFirms
export def "norm-law-firm-search searchNormalizedLawFirms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.</a>
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<nextPageAPI: string, normLawFirmSearchId: string, normLawFirmSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normLawFirmDetailsAPI: string, normLawFirmId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/normLawFirmSearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Norm law firm search result for a given normLawFirmSearchId.
#
# GET /normLawFirmSearch/{normLawFirmSearchId}
# operationId: searchNormalizedLawFirmsById
export def "norm-law-firm-search searchNormalizedLawFirmsById" [
  normLawFirmSearchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<nextPageAPI: string, normLawFirmSearchId: string, normLawFirmSearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normLawFirmDetailsAPI: string, normLawFirmId: string, object: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normLawFirmSearch/($normLawFirmSearchId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Norm Party Details.
#
# GET /normParty/{normPartyId}
# operationId: getNormPartyById
export def "norm-party get" [
  normPartyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<caseAnalyticsAPI: record<caseCountAnalyticsByAreaOfLawAPI: string, caseCountAnalyticsByCaseClassAPI: string, caseCountAnalyticsByCaseTypeAPI: string, caseCountAnalyticsByCaseTypeGroupAPI: string, caseCountAnalyticsByCourtAPI: string, caseCountAnalyticsByCourtLocationAPI: string, caseCountAnalyticsByCourtSystemAPI: string, caseCountAnalyticsByCourtTypeAPI: string, caseCountAnalyticsByJurisdictionGeoAPI: string, caseCountAnalyticsByPartyRoleAPI: string, caseCountAnalyticsByPartyRoleGroupAPI: string, object: string, totalCases: int>, caseSearchAPI: string, individualData: record<firstName: string, lastName: string, middleName: string, name: string>, name: string, normOrganizationData: record<cik: string, isInvolvedInLitigation: bool, lei: string, naics: string, naicsDescription: string, name: string, normCorporateGroupArray: list<record>, normOrganizationId: string, normPartyAPI: string, object: string, organizationType: string, sic: string, sicDescription: string, sosDataArray: list<record>, tickerArray: list<record>>, normPartyId: string, object: string, partyAnalyticsAPI: record<associatedNormAttorneysAPI: string, associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, caseCountAnalyticsByOpposingNormAttorneyAPI: string, caseCountAnalyticsByOpposingNormLawFirmAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, normPartyAPI: string, object: string>, partyClassificationType: string, relatedNormPartyArray: table<normPartyId: string, object: string, relationshipType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/normParty/($normPartyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attorneys that represented the Party.
#
# GET /normParty/{normPartyId}/associatedNormAttorneys
# operationId: getNormAttorneysAssociatedWithNormParty
export def "norm-party-associated-norm-attorneys get" [
  normPartyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormAttorneyArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normAttorneyAPI: string, normAttorneyId: string, object: string, stateBarDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normParty/($normPartyId)/associatedNormAttorneys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Judges Faced By the Party.
#
# GET /normParty/{normPartyId}/associatedNormJudges
# operationId: getNormJudgesAssociatedWithNormParty
export def "norm-party-associated-norm-judges get" [
  normPartyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormJudgeArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, firstName: string, lastName: string, middleName: string, name: string, normJudgeAPI: string, normJudgeId: string, object: string, version: string>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normParty/($normPartyId)/associatedNormJudges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Law Firms that represented the Party.
#
# GET /normParty/{normPartyId}/associatedNormLawFirms
# operationId: getNormLawFirmsAssociatedWithNormParty
export def "norm-party-associated-norm-law-firms get" [
  normPartyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<associatedNormLawFirmArray: table<caseCount: int, caseSearchAPI: string, caseTimeline: record, name: string, normLawFirmAPI: string, normLawFirmId: string, object: string, sosDataArray: list>, nextPageAPI: string, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normParty/($normPartyId)/associatedNormLawFirms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Case Count Analytics by Opposing Norm Party.
#
# GET /normParty/{normPartyId}/caseCountAnalyticsByOpposingNormParty
# operationId: getCaseCountAnalyticsByOpposingNormPartyForANormParty
export def "norm-party-case-count-analytics-by-opposing-norm-party get" [
  normPartyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters. All options are documented above.
  --pageNumber: int # Page number. - minimum: 1
]: nothing -> record<nextPageAPI: string, object: string, previousPageAPI: string, results: table<caseCount: int, caseSearchAPI: string, normPartyId: string, normPartyName: string, object: string>, totalCaseCount: int, totalNormPartyCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normParty/($normPartyId)/caseCountAnalyticsByOpposingNormParty" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Party search.
#
# GET /normPartySearch
# operationId: searchNormalizedParties
export def "norm-party-search searchNormalizedParties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The URL encoded query you are searching for. The query can be as simple as a keyword, but supports many additional options and filters.</a>
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<nextPageAPI: string, normPartySearchId: string, normPartySearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normPartyDetailsAPI: string, normPartyId: string, object: string, partyClassificationType: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/normPartySearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Norm party search results for a given normPartySearchId.
#
# GET /normPartySearch/{normPartySearchId}
# operationId: searchNormalizedPartiesById
export def "norm-party-search searchNormalizedPartiesById" [
  normPartySearchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved. - Minimum: 1 - Maximum: 1000  (e.g. 1)
]: nothing -> record<nextPageAPI: string, normPartySearchId: string, normPartySearchResultArray: table<firstFetchDate: string, lastFetchDate: string, matchedObjectArray: list, name: string, normPartyDetailsAPI: string, normPartyId: string, object: string, partyClassificationType: string>, object: string, pageNumber: int, previousPageAPI: string, q: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/normPartySearch/($normPartySearchId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find PACER Case for a requested Case Number and Court.
#
# GET /pacer/importCaseByCourtUsingCaseNumber
# operationId: importPacerCaseByCourtUsingCaseNumber
export def "pacer-import-case-by-court-using-case-number importPacerCaseByCourtUsingCaseNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # Case Number which you would like to Find in PACER site and import it to UniCourt. (e.g. 2:15-mc-12345)
  --courtId: string # Court Id of the Case number being provided.
]: nothing -> record<courtFee: float, object: string, pacerImportCaseResultsArray: table<hasOnlyMetaInfo: bool, object: string, uniCourtContent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "courtId" $courtId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacer/importCaseByCourtUsingCaseNumber" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/allCourts
# operationId: AllCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-all-courts AllCourtsPacerCaseLocatorCaseSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed. (nullable)
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Case Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/allCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/appealCourts
# operationId: AppealCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-appeal-courts AppealCourtsPacerCaseLocatorCaseSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn    where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed. (nullable)
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --natureOfSuitsArray: list # Search can be narrowed down by passing Nature Of Suits. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-e-nature-of-suits'>APPENDIX E - Appellate Nature Of Suits</a> mentioned in the API Documentation.   	Scenario: When mulitple nature of suits needs to be requested.   	Imagine for a given case number 12-1234 I would like to search with the nature of suit 1110 (Insurance) and 1150 (Overpayments & Enforc. of Judgments), My query in the request will look like the example mentioned below.   	Example: natureOfSuitsArray=1110&natureOfSuitsArray=1150
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Case Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make. (e.g. 1)
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "natureOfSuitsArray" $natureOfSuitsArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/appealCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for Bankruptcy Courts.
#
# GET /pacerCaseLocator/caseSearch/bankruptcyCourts
# operationId: BankruptcyCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-bankruptcy-courts BankruptcyCourtsPacerCaseLocatorCaseSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --federalBankruptcyChapterArray: list # Search can be narrowed down by passing Federal Bankruptcy Chapters. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-d-bankruptcy-chapters'>APPENDIX D: Bankruptcy Chapters</a> mentioned in the API Documentation.   	Scenario: When mulitple Federal Bankruptcy Chapters needs to be requested.   	Imagine for a given case number 12-1234 I would like to search with the Federal Bankruptcy Chapters 7 (Chapter 7) and 11 (Chapter 11), My query in the request will look like the example mentioned below.   	Example: federalBankruptcyChapterArray=7&federalBankruptcyChapterArray=11
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseDischargedStartDate: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00   	Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --caseDischargedEndDate: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00   	Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --caseDismissedStartDate: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case dismissed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00   	Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --caseDismissedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Case Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "federalBankruptcyChapterArray" $federalBankruptcyChapterArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "caseDischargedStartDate" $caseDischargedStartDate "scalar") (serialize-qp "caseDischargedEndDate" $caseDischargedEndDate "scalar") (serialize-qp "caseDismissedStartDate" $caseDismissedStartDate "scalar") (serialize-qp "caseDismissedEndDate" $caseDismissedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/bankruptcyCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/civilCourts
# operationId: CivilCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-civil-courts CivilCourtsPacerCaseLocatorCaseSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --natureOfSuitsArray: list # Search can be narrowed down by passing Nature Of Suits. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-e-nature-of-suits'>APPENDIX E - Civil Nature Of Suits</a> mentioned in the API Documentation.   	Scenario: When mulitple nature of suits needs to be requested.   	Imagine for a given case number 12-1234 I would like to search with the nature of suit 110 (Insurance) and 140 (Negotiable Instrument), My query in the request will look like the example mentioned below.   	Example: natureOfSuitsArray=110&natureOfSuitsArray=140
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Case Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "natureOfSuitsArray" $natureOfSuitsArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/civilCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/criminalCourts
# operationId: CriminalCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-criminal-courts CriminalCourtsPacerCaseLocatorCaseSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Case Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/criminalCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/caseSearch/multiDistrictCourts
# operationId: MultiDistrictCourtsPacerCaseLocatorCaseSearch
export def "pacer-case-locator-case-search-multi-district-courts MultiDistrictCourtsPacerCaseLocatorCaseSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --jpmlNumber: int # Master JPML Case Number.
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Case Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "jpmlNumber" $jpmlNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/caseSearch/multiDistrictCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/allCourts
# operationId: AllCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-all-courts AllCourtsPacerCaseLocatorPartySearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --lastName: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --firstName: string # The first name of a party to search. (nullable, e.g. John)
  --middleName: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --partyType: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --partyExactNameMatch: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --partyRoleArray: list # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseYearFrom: int # Limit the results of the search to those cases from the year specified or later
  --caseYearTo: int # Limit the results of the search to those cases from the year specified or earlier
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Party Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario 1: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC   	Scenario 2: When you want to sort the response using the case parameters in the party search.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $partyType "scalar") (serialize-qp "partyExactNameMatch" $partyExactNameMatch "scalar") (serialize-qp "partyRoleArray" $partyRoleArray "multi") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseYearFrom" $caseYearFrom "scalar") (serialize-qp "caseYearTo" $caseYearTo "scalar") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/allCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/appealCourts
# operationId: AppealCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-appeal-courts AppealCourtsPacerCaseLocatorPartySearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --lastName: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --firstName: string # The first name of a party to search. (nullable, e.g. John)
  --middleName: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --partyType: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --partyExactNameMatch: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --partyRoleArray: list # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseYearFrom: int # Limit the results of the search to those cases from the year specified or later
  --caseYearTo: int # Limit the results of the search to those cases from the year specified or earlier
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Party Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario 1: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC   	Scenario 2: When you want to sort the response using the case parameters in the party search.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $partyType "scalar") (serialize-qp "partyExactNameMatch" $partyExactNameMatch "scalar") (serialize-qp "partyRoleArray" $partyRoleArray "multi") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseYearFrom" $caseYearFrom "scalar") (serialize-qp "caseYearTo" $caseYearTo "scalar") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/appealCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/bankruptcyCourts
# operationId: BankruptcyCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-bankruptcy-courts BankruptcyCourtsPacerCaseLocatorPartySearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --lastName: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --firstName: string # The first name of a party to search. (nullable, e.g. John)
  --middleName: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --partyType: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --partyExactNameMatch: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --partyRoleArray: list # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseYearFrom: int # Limit the results of the search to those cases from the year specified or later
  --caseYearTo: int # Limit the results of the search to those cases from the year specified or earlier
  --ssnOrEin: string # The 9 digit Social Security number or Federal Tax ID can be used in this search. The delimiter dash (-) can be used as the input to this API but wont be used during the search. A search for SSN 123-45-6789 or 12-3456789 will yield the same results as a search for 123456789. (nullable)
  --fourDigitSsn: string # Search for parties whose SSN ends with a specified four digits.  	Note: When specified, a last name/entity name must also be specified. (nullable)
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseDischargedStartDate: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00   	Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --caseDischargedEndDate: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case discharged end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00   	Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --caseDismissedStartDate: string # Narrowing the search for bankruptcy cases by limiting the cases which matches the criteria for case dismissed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00   	Note: This parameter is applicable since we only perform this search for Bankruptcy Court type. (nullable, format: date-time)
  --caseDismissedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Party Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario 1: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC   	Scenario 2: When you want to sort the response using the case parameters in the party search.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $partyType "scalar") (serialize-qp "partyExactNameMatch" $partyExactNameMatch "scalar") (serialize-qp "partyRoleArray" $partyRoleArray "multi") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseYearFrom" $caseYearFrom "scalar") (serialize-qp "caseYearTo" $caseYearTo "scalar") (serialize-qp "ssnOrEin" $ssnOrEin "scalar") (serialize-qp "fourDigitSsn" $fourDigitSsn "scalar") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "caseDischargedStartDate" $caseDischargedStartDate "scalar") (serialize-qp "caseDischargedEndDate" $caseDischargedEndDate "scalar") (serialize-qp "caseDismissedStartDate" $caseDismissedStartDate "scalar") (serialize-qp "caseDismissedEndDate" $caseDismissedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/bankruptcyCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/civilCourts
# operationId: CivilCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-civil-courts CivilCourtsPacerCaseLocatorPartySearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --lastName: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --firstName: string # The first name of a party to search. (nullable, e.g. John)
  --middleName: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --partyType: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --partyExactNameMatch: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --partyRoleArray: list # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseYearFrom: int # Limit the results of the search to those cases from the year specified or later
  --caseYearTo: int # Limit the results of the search to those cases from the year specified or earlier
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Party Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario 1: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC   	Scenario 2: When you want to sort the response using the case parameters in the party search.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $partyType "scalar") (serialize-qp "partyExactNameMatch" $partyExactNameMatch "scalar") (serialize-qp "partyRoleArray" $partyRoleArray "multi") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseYearFrom" $caseYearFrom "scalar") (serialize-qp "caseYearTo" $caseYearTo "scalar") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/civilCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/criminalCourts
# operationId: CriminalCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-criminal-courts CriminalCourtsPacerCaseLocatorPartySearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --lastName: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --firstName: string # The first name of a party to search. (nullable, e.g. John)
  --middleName: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --partyType: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --partyExactNameMatch: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --partyRoleArray: list # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseYearFrom: int # Limit the results of the search to those cases from the year specified or later
  --caseYearTo: int # Limit the results of the search to those cases from the year specified or earlier
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Party Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario 1: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC   	Scenario 2: When you want to sort the response using the case parameters in the party search.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $partyType "scalar") (serialize-qp "partyExactNameMatch" $partyExactNameMatch "scalar") (serialize-qp "partyRoleArray" $partyRoleArray "multi") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseYearFrom" $caseYearFrom "scalar") (serialize-qp "caseYearTo" $caseYearTo "scalar") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/criminalCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PACER Case Locator Search API for All Courts.
#
# GET /pacerCaseLocator/partySearch/multiDistrictCourts
# operationId: MultiDistrictCourtsPacerCaseLocatorPartySearch
export def "pacer-case-locator-party-search-multi-district-courts MultiDistrictCourtsPacerCaseLocatorPartySearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pacerUserId: string # User ID or User Name of the PACER Account used while signing in to PACER. (e.g. johndoe)
  --pacerClientCode: string # Client Code used while signing in to PACER account. (e.g. john)
  --caseNumber: string # If the court type is selected as All or if you need data for a specific case number format, then you need to use this option. Case numbers may be entered in each of the following formats:   	yy-nnnnn   	yy-tp-nnnnn   	yy tp nnnnn   	yytpnnnnn   	o:yy-nnnnn   	o:yy-tp-nnnnn   	o:yy tp nnnnn   	o:yytpnnnnn   where:   yy  case year (may be 2 or 4 digits)   nnnnn  case number (up to 5 digits)   tp  case type (up to 2 characters)   o  office where the case was filed (1 digit). (nullable, e.g. 12-1234)
  --jpmlNumber: int # Master JPML Case Number.
  --pacerCaseId: int # Sequentially generated number that identifies the case in PACER system.
  --lastName: string # The last name of a party to search. This can be person or non person entity. (nullable, e.g. John)
  --firstName: string # The first name of a party to search. (nullable, e.g. John)
  --middleName: string # The middle name of a party to search. (nullable, e.g. Doe)
  --generation: string # The name suffix (e.g., III, MD). (nullable, e.g. III)
  --partyType: string # The court-assigned party type for a party involved in a case. Party type codes are created and assigned by individual courts, and as such, their meanings can vary from court to court. (nullable, e.g. ptf)
  --partyExactNameMatch: oneof<nothing, bool> # When set to true this field will search the party with an exact match of the name provided.
  --partyRoleArray: list # The court-assigned role for a party to a case. Party role codes are created and assigned by individual courts, and as such, their meanings can vary from court to court.
  --caseTitle: string # You can search using the case name even if you know one party.   	Examples:   	A search for case title john doe v will result in all cases with the case title John Doe v.   	A search for case title Acme, Inc. will result in all case titles starting with Acme, Inc. (nullable)
  --caseOffice: int # The divisional office in which the case was filed.
  --caseSequenceNumber: int # The sequence number of a given case. Ex 12345
  --caseYear: int # The two digits or four digits of the year in which the case was filed.
  --caseTypeArray: list # Search can be narrowed down by passing caseTypes. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-a-case-types'>APPENDIX A: Case Types</a> mentioned in the API Documentation.   	Scenario: When mulitple case types needs to be requested.   	Imagine for a given case number 12-1234 I would like to search only with the case type civil(cv) and criminal(cr), My query in the request will look like the example mentioned below.   	Example: caseTypeArray=cv&caseTypeArray=cr
  --courtRegionIdArray: list # Search can be narrowed down by passing courtRegionId. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-b-court-regions'>APPENDIX B: Court Regions</a> mentioned in the API Documentation.   	Scenario: When mulitple court region ids needs to be requested.   	Imagine for a given case number 12-1234 I would like to search in the court regions California Central (cac) and California Eastern (cae), My query in the request will look like the example mentioned below.   	Example: courtRegionIdArray=cac&courtRegionIdArray=cae
  --caseYearFrom: int # Limit the results of the search to those cases from the year specified or later
  --caseYearTo: int # Limit the results of the search to those cases from the year specified or earlier
  --caseFiledStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseFiledEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case filed end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedStartDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated start date on or after the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --caseTerminatedEndDate: string # Narrowing the search by limiting the cases which matches the criteria for case terminated end date on or before the given date. Format: YYYY-MM-DDTHH:MM:SS+ZZ:zz, Ex: 2017-12-20T12:54:24+00:00 (nullable, format: date-time)
  --sortParameterQuery: string # The criteria based on which the search results are to be sorted. Please use the <a href='https://docs.unicourt.com/pacer-glossary/appendix-c-sort-parameter'>APPENDIX C: Sort Parameter - Sortable Party Parameters</a> mentioned in the API Documentation. The fields can be sorted either ASC or DESC.   	Scenario 1: When mulitple sort paramters needs to be requested.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of courtId and caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtId,ASC&caseId,ASC   	Scenario 2: When you want to sort the response using the case parameters in the party search.   	Imagine for a given case number 12-1234 I would like to sort the results in the Ascending order of caseOffice and descending order of caseId, My query in the request will look like the example mentioned below.   	Example: sortParameterQuery=courtCase.caseOffice,ASC&caseid,DESC (nullable, default: sort=caseYear,DESC)
  --caseStatus: string@caseStatus-completer # Status of a case. 'closed' for a Terminated case, 'open' for Pending cases. If this parameter is not sent both cases that fall in open and closed will be queried. (nullable)
  --pageNumber: int # Page Number for a given Job ID or for the search your going to make.
]: nothing -> record<nextPageAPI: string, object: string, pacerPageInfo: record<first: bool, last: bool, number: int, numberOfElements: int, object: string, size: int, totalElements: int, totalPages: int>, pacerReceipt: record<billablePages: int, clientCode: string, csoId: int, description: string, firmId: string, loginId: string, object: string, reportId: string, search: string, searchFee: string, transactionDate: string>, pacerSearchResultsArray: table<hasOnlyMetaInfo: bool, object: string, pacerContent: record, uniCourtContent: record>, pageNumber: int, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pacerUserId" $pacerUserId "scalar") (serialize-qp "pacerClientCode" $pacerClientCode "scalar") (serialize-qp "caseNumber" $caseNumber "scalar") (serialize-qp "jpmlNumber" $jpmlNumber "scalar") (serialize-qp "pacerCaseId" $pacerCaseId "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "generation" $generation "scalar") (serialize-qp "partyType" $partyType "scalar") (serialize-qp "partyExactNameMatch" $partyExactNameMatch "scalar") (serialize-qp "partyRoleArray" $partyRoleArray "multi") (serialize-qp "caseTitle" $caseTitle "scalar") (serialize-qp "caseOffice" $caseOffice "scalar") (serialize-qp "caseSequenceNumber" $caseSequenceNumber "scalar") (serialize-qp "caseYear" $caseYear "scalar") (serialize-qp "caseTypeArray" $caseTypeArray "multi") (serialize-qp "courtRegionIdArray" $courtRegionIdArray "multi") (serialize-qp "caseYearFrom" $caseYearFrom "scalar") (serialize-qp "caseYearTo" $caseYearTo "scalar") (serialize-qp "caseFiledStartDate" $caseFiledStartDate "scalar") (serialize-qp "caseFiledEndDate" $caseFiledEndDate "scalar") (serialize-qp "caseTerminatedStartDate" $caseTerminatedStartDate "scalar") (serialize-qp "caseTerminatedEndDate" $caseTerminatedEndDate "scalar") (serialize-qp "sortParameterQuery" $sortParameterQuery "scalar") (serialize-qp "caseStatus" $caseStatus "scalar") (serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCaseLocator/partySearch/multiDistrictCourts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The page number of the PACER credentials to be retrieved.<br>   - Minimum: 1  (e.g. 1)
]: nothing -> record<nextPageAPI: string, object: string, pacerCredentialArray: table<defaultPacerClientCode: string, object: string, pacerUserId: string>, pageNumber: int, previousPageAPI: string, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pacerCredential" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Pacer Credential.
#
# PUT /pacerCredential
# operationId: addPacerCredential
export def "pacer-credential addPacerCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultPacerClientCode: string # Pacer Client Code. (nullable, e.g. Test UniCourt API)
  pacerUserId: string # Pacer User Id. (e.g. URKYwer3tyh5r56gq2)
  password: string # Password. (e.g. your password)
]: any -> record<message: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pacerCredential")
  let body = {defaultPacerClientCode: $defaultPacerClientCode, pacerUserId: $pacerUserId, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Pacer credential for a specific Pacer User Id.
#
# DELETE /pacerCredential/{pacerUserId}
# operationId: removePacerCredentialById
export def "pacer-credential removePacerCredentialById" [
  pacerUserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pacerCredential/($pacerUserId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Pacer Credential for a requested pacer User Id.
#
# GET /pacerCredential/{pacerUserId}
# operationId: getPacerCredentialById
export def "pacer-credential get" [
  pacerUserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<defaultPacerClientCode: string, object: string, pacerUserId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pacerCredential/($pacerUserId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets details for a requested Party ID.
#
# GET /party/{partyId}
# operationId: getPartyById
export def "party get" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attorneyRepresentationType: record<attorneyRepresentationTypeId: string, createdDate: string, name: string, object: string>, contact: record<addressArray: list<record>, emailArray: list<record>, object: string, phoneNumberArray: list<record>>, firstFetchDate: string, firstName: string, isVisible: bool, lastFetchDate: string, lastName: string, middleName: string, name: string, namePrefix: string, nameSuffix: string, object: string, partyAttorneyAssociations: record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: list<record>, totalCount: int, totalPages: int>, partyClassificationType: string, partyId: string, partyRole: record<createdDate: string, description: string, name: string, object: string, partyRoleGroup: string, partyRoleGroupId: string, partyRoleId: string>, possibleNormPartyArray: table<associatedNormAttorneysAPI: string, associatedNormJudgesAPI: string, associatedNormLawFirmsAPI: string, bestMatch: bool, caseCountAnalyticsByNormPartyAPI: string, caseCountAnalyticsByOpposingNormPartyAPI: string, confidenceScore: float, normPartyAPI: string, normPartyId: string, normPartyName: string, object: string, scoreConstituents: record>, sourcePartyRole: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/party/($partyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Associated Attorney details for a requested Party ID.
#
# GET /party/{partyId}/associatedAttorneys
# operationId: getPartyAssociatedAttorneys
export def "party-associated-attorneys get" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Query parameter specifying the page number of the search results to be retrieved.
]: nothing -> record<nextPageAPI: string, object: string, pageNumber: int, partyAttorneyAssociationArray: table<attorneyId: string, isVisible: bool, object: string, partyAttorneyAssociationId: string, partyId: string>, totalCount: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/party/($partyId)/associatedAttorneys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
