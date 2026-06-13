# Auto-generated client for Bills API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/bills/v1/openapi.json
# Auth: --token flag or $env.BILLS_API_TOKEN

const BASE_URL = "https://bills-api.parliament.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BILLS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://bills-api.parliament.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Category-completer [] { ["Hybrid" "Private" "Public"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def CurrentHouse-completer [] { ["All" "Commons" "Lords" "Unassigned"] }
def OriginatingHouse-completer [] { ["All" "Commons" "Lords"] }
def SortOrder-completer [] { ["DateUpdatedAscending" "DateUpdatedDescending" "TitleAscending" "TitleDescending"] }
def Decision-completer [] { ["Agreed" "All" "Disagreed" "NoDecision" "NotMoved" "Withdrawn"] }
def House-completer [] { ["All" "Commons" "Lords" "Unassigned"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Category: string@Category-completer
  --Skip: int # format: int32
  --Take: int # format: int32
]: nothing -> record<items: table<category: string, description: string, id: int, name: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Category" $Category "scalar") (serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/BillTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of Bills.
#
# GET /api/v1/Bills
# operationId: GetBills
export def "bills GetBills" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --SearchTerm: string
  --Session: int # format: int32
  --CurrentHouse: string@CurrentHouse-completer
  --OriginatingHouse: string@OriginatingHouse-completer
  --MemberId: int # format: int32
  --DepartmentId: int # format: int32
  --BillStage: list
  --BillStagesExcluded: list
  --IsDefeated: oneof<nothing, bool>
  --IsWithdrawn: oneof<nothing, bool>
  --BillType: list
  --SortOrder: string@SortOrder-completer
  --BillIds: list
  --Skip: int # format: int32
  --Take: int # format: int32
]: nothing -> record<items: table<billId: int, billTypeId: int, billWithdrawn: string, currentHouse: string, currentStage: record, includedSessionIds: list, introducedSessionId: int, isAct: bool, isDefeated: bool, lastUpdate: string, originatingHouse: string, shortTitle: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SearchTerm" $SearchTerm "scalar") (serialize-qp "Session" $Session "scalar") (serialize-qp "CurrentHouse" $CurrentHouse "scalar") (serialize-qp "OriginatingHouse" $OriginatingHouse "scalar") (serialize-qp "MemberId" $MemberId "scalar") (serialize-qp "DepartmentId" $DepartmentId "scalar") (serialize-qp "BillStage" $BillStage "multi") (serialize-qp "BillStagesExcluded" $BillStagesExcluded "multi") (serialize-qp "IsDefeated" $IsDefeated "scalar") (serialize-qp "IsWithdrawn" $IsWithdrawn "scalar") (serialize-qp "BillType" $BillType "multi") (serialize-qp "SortOrder" $SortOrder "scalar") (serialize-qp "BillIds" $BillIds "multi") (serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Bills" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a Bill.
#
# GET /api/v1/Bills/{billId}
# operationId: GetBill
export def "bills GetBill" [
  billId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<agent: record<address: string, email: string, name: string, phoneNo: string, website: string>, billId: int, billTypeId: int, billWithdrawn: string, currentHouse: string, currentStage: record<abbreviation: string, description: string, house: string, id: int, sessionId: int, sortOrder: int, stageId: int, stageSittings: list<record>>, includedSessionIds: list<int>, introducedSessionId: int, isAct: bool, isDefeated: bool, lastUpdate: string, longTitle: string, originatingHouse: string, petitionInformation: string, petitioningPeriod: string, promoters: table<organisationName: string, organisationUrl: string>, shortTitle: string, sponsors: table<member: record, organisation: record, sortOrder: int>, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Bills/($billId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of news articles for a Bill.
#
# GET /api/v1/Bills/{billId}/NewsArticles
# operationId: GetNewsArticles
export def "bills-news-articles GetNewsArticles" [
  billId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Skip: int # format: int32
  --Take: int # format: int32
]: nothing -> record<items: table<content: string, displayDate: string, id: int, title: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Bills/($billId)/NewsArticles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of Bill publications.
#
# GET /api/v1/Bills/{billId}/Publications
# operationId: GetBillPublication
export def "bills-publications GetBillPublication" [
  billId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<billId: int, publications: table<displayDate: string, files: list, house: string, id: int, links: list, publicationType: record, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Bills/($billId)/Publications")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all Bill stages.
#
# GET /api/v1/Bills/{billId}/Stages
export def "bills-stages get" [
  billId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Skip: int # format: int32
  --Take: int # format: int32
]: nothing -> record<items: table<abbreviation: string, description: string, house: string, id: int, sessionId: int, sortOrder: int, stageId: int, stageSittings: list>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Bills/($billId)/Stages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a Bill stage.
#
# GET /api/v1/Bills/{billId}/Stages/{billStageId}
# operationId: GetBillStageDetails
export def "bills-stages GetBillStageDetails" [
  billId: int
  billStageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<abbreviation: string, committee: record<category: string, house: string, id: int, name: string, url: string>, description: string, house: string, id: int, lastUpdate: string, nextStageBillStageId: int, previousStageBillStageId: int, sessionId: int, sortOrder: int, stageId: int, stageSittings: table<billId: int, billStageId: int, date: string, id: int, stageId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Bills/($billId)/Stages/($billStageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of amendments.
#
# GET /api/v1/Bills/{billId}/Stages/{billStageId}/Amendments
# operationId: GetAmendments
export def "bills-stages-amendments GetAmendments" [
  billId: int
  billStageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --SearchTerm: string
  --Decision: string@Decision-completer
  --MemberId: int # format: int32
  --Skip: int # format: int32
  --Take: int # format: int32
]: nothing -> record<items: table<amendmentId: int, amendmentPosition: string, amendmentType: string, billId: int, billStageId: int, clause: int, decision: string, lineNumber: int, marshalledListText: string, pageNumber: int, schedule: int, sponsors: list, summaryText: list>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SearchTerm" $SearchTerm "scalar") (serialize-qp "Decision" $Decision "scalar") (serialize-qp "MemberId" $MemberId "scalar") (serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Bills/($billId)/Stages/($billStageId)/Amendments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an amendment.
#
# GET /api/v1/Bills/{billId}/Stages/{billStageId}/Amendments/{amendmentId}
# operationId: GetAmendment
export def "bills-stages-amendments GetAmendment" [
  billId: int
  billStageId: int
  amendmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<amendmentId: int, amendmentLines: table<hangingIndentation: string, imageType: string, indentation: int, isImage: bool, text: string>, amendmentNote: string, amendmentPosition: string, amendmentType: string, billId: int, billStageId: int, clause: int, decision: string, explanatoryText: string, explanatoryTextPrefix: string, lineNumber: int, marshalledListText: string, pageNumber: int, schedule: int, sponsors: table<house: string, isLead: bool, memberFrom: string, memberId: int, memberPage: string, memberPhoto: string, name: string, party: string, partyColour: string, sortOrder: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Bills/($billId)/Stages/($billStageId)/Amendments/($amendmentId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of Bill stage publications.
#
# GET /api/v1/Bills/{billId}/Stages/{stageId}/Publications
export def "bills-stages-publications get" [
  billId: int
  stageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<billStageId: int, publications: table<displayDate: string, files: list, id: int, links: list, publicationType: record, title: string>, sittings: table<publications: list, sittingId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Bills/($billId)/Stages/($stageId)/Publications")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Skip: int # format: int32
  --Take: int # format: int32
]: nothing -> record<items: table<description: string, id: int, name: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/PublicationTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return information on a document.
#
# GET /api/v1/Publications/{publicationId}/Documents/{documentId}
export def "publications-documents get" [
  publicationId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<contentLength: int, contentType: string, filename: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Publications/($publicationId)/Documents/($documentId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a document.
#
# GET /api/v1/Publications/{publicationId}/Documents/{documentId}/Download
export def "publications-documents-download get" [
  publicationId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Publications/($publicationId)/Documents/($documentId)/Download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Rss/Bills/($id).rss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an Rss feed of all Bills.
#
# GET /api/v1/Rss/allbills.rss
export def "rss-allbillsrss get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Rss/allbills.rss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an Rss feed of private Bills.
#
# GET /api/v1/Rss/privatebills.rss
export def "rss-privatebillsrss get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Rss/privatebills.rss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an Rss feed of public Bills.
#
# GET /api/v1/Rss/publicbills.rss
export def "rss-publicbillsrss get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Rss/publicbills.rss")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of Sittings.
#
# GET /api/v1/Sittings
# operationId: GetSittings
export def "sittings GetSittings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --House: string@House-completer
  --DateFrom: string # format: date-time
  --DateTo: string # format: date-time
  --Skip: int # format: int32
  --Take: int # format: int32
]: nothing -> record<items: table<billId: int, billStageId: int, date: string, id: int, stageId: int>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "House" $House "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Sittings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Skip: int # format: int32
  --Take: int # format: int32
]: nothing -> record<items: table<house: string, id: int, name: string>, itemsPerPage: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Skip" $Skip "scalar") (serialize-qp "Take" $Take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Stages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
