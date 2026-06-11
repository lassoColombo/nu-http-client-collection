# Auto-generated client for Business Rates v2.0
# Source: https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/business-rates-api/2.0/oas/resolved
# Auth: --token flag or $env.BUSINESS_RATES_TOKEN

const BASE_URL = "https://test-api.service.hmrc.gov.uk/organisations/business-rates"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUSINESS_RATES_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://test-api.service.hmrc.gov.uk/organisations/business-rates" "https://api.service.hmrc.gov.uk/organisations/business-rates"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Accept-completer [] { ["application/vnd.hmrc.2.0+json"] }
def projection-completer [] { ["detailed" "summary"] }
def status-completer [] { ["APPROVED" "DECLINED" "MORE_EVIDENCE_REQUIRED" "PENDING" "REVOKED"] }
def sortField-completer [] { ["ADDRESS" "AGENT" "BAREF" "CREATED_DATE_TIME" "STATUS"] }
def sortDirection-completer [] { ["ASC" "DESC"] }
def checkCaseStatus-completer [] { ["ASSIGNED" "CANCELLED" "CLOSED" "DECISION_SENT" "OPEN" "PENDING" "RECEIVED" "UNDER_REVIEW"] }
def sortField-completer-1 [] { ["ADDRESS" "BAREF" "CLIENT" "CREATED_DATE_TIME" "REPRESENTATION_STATUS" "STATUS"] }
def sortField-completer-2 [] { ["ADDRESS" "CASEREF" "EFFECTIVE_DATE" "IP_ORGANISATION_NAME" "LAST_READ_AT" "SUBJECT"] }
def projection-completer-1 [] { ["data" "html" "legacy"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "property-search PropertySearch" } } | get name | first)
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

# Search for properties
#
# GET /property-search
# operationId: PropertySearch
export def "property-search PropertySearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --postcode: string # Filters the results to include properties which match the provided postcode. The search is not case sensitive and must contain the 'Outward Code' (e.g. RH1). This, or at least one other search parameter, must be included in your search.
  --billingAuthorityReference: string # Filters the results to include properties which are inside the provided billing authority. The search is not case sensitive and supports partial references. This, or at least one other search parameter, must be included in your search.
  --uarn: int # Filters the results down to a single property with the given UARN. This, or at least one other search parameter, must be included in your search. (format: int64, e.g. 12345678901)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --afterAddress: string # The last property address you've retrieved if you want to get to the next page of results. The search will only return properties with address alphabetically after the specified address
  --afterUarn: int # return only properties with UARNs greater than the specified UARN. Must be used in conjunction with afterAddress (format: int64)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "postcode" $postcode "scalar") (serialize-qp "billingAuthorityReference" $billingAuthorityReference "scalar") (serialize-qp "uarn" $uarn "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "afterAddress" $afterAddress "scalar") (serialize-qp "afterUarn" $afterUarn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/property-search" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Valuation history
#
# GET /properties/{uarn}/valuations
# operationId: GetValuationHistory
export def "properties-valuations GetValuationHistory" [
  uarn: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --propertyLinkSubmissionId: string # The property link you wish to filter the history on (e.g. PL123456)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/properties/($uarn)/valuations" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Valuation
#
# GET /properties/{uarn}/valuations/{valuationId}
# operationId: GetValuation
export def "properties-valuations GetValuation" [
  uarn: int
  valuationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projection: string@projection-completer # Return summary (simplified) projection, or detailed (full) view of the resource. (default: summary)
  --propertyLinkSubmissionId: string # The property link ID of the property you wish to view (required with projection=detailed) (e.g. PL123456)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projection" $projection "scalar") (serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/properties/($uarn)/valuations/($valuationId)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# My organisation's property links
#
# GET /my-organisation/property-links
# operationId: GetMyOrganisationsPropertyLinks
export def "my-organisation-property-links GetMyOrganisationsPropertyLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # Address, or part of the address (e.g. street name or postcode), to filter by
  --uarn: int # The Unique Address Reference Number (UARN) of the property (format: int64, e.g. 12345678901)
  --billingAuthorityReference: string # Filters the results to include properties which are inside the provided billing authority.
  --status: string@status-completer # The status of a property link to filter by
  --page: int # The results for this endpoint are paginated and this refers to the page number (format: int32, default: 1)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --sortField: string@sortField-completer # Field to sort the results by
  --sortDirection: string@sortDirection-completer # Results will be sorted in the specified direction (ascending or descending)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "uarn" $uarn "scalar") (serialize-qp "billingAuthorityReference" $billingAuthorityReference "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortDirection" $sortDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my-organisation/property-links" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create property link
#
# POST /my-organisation/property-links
# operationId: CreatePropertyLink
export def "my-organisation-property-links CreatePropertyLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my-organisation/property-links")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# My organisation's property link
#
# GET /my-organisation/property-links/{propertyLinkSubmissionId}
# operationId: GetMyOrganisationsPropertyLink
export def "my-organisation-property-links GetMyOrganisationsPropertyLink" [
  propertyLinkSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projection: string@projection-completer # Return summary (simplified) projection, or detailed (full) view of the resource. (default: summary)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projection" $projection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/my-organisation/property-links/($propertyLinkSubmissionId)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach property link evidence
#
# POST /my-organisation/property-links/{propertyLinkSubmissionId}/evidence
# operationId: AttachPropertyLinkEvidence
export def "my-organisation-property-links-evidence AttachPropertyLinkEvidence" [
  propertyLinkSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/property-links/($propertyLinkSubmissionId)/evidence")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Status of property link evidence
#
# GET /my-organisation/property-links/{propertyLinkSubmissionId}/evidence/{evidenceReference}
# operationId: GetPropertyLinkEvidenceStatus
export def "my-organisation-property-links-evidence GetPropertyLinkEvidenceStatus" [
  propertyLinkSubmissionId: string
  evidenceReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/property-links/($propertyLinkSubmissionId)/evidence/($evidenceReference)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# My organisation's check cases
#
# GET /my-organisation/check-cases
# operationId: GetMyOrganisationsCheckCases
export def "my-organisation-check-cases GetMyOrganisationsCheckCases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --propertyLinkSubmissionId: string # The property link you wish to filter on (e.g. PLQQ2YMP)
  --checkCaseStatus: string@checkCaseStatus-completer # The check case status you wish to filter on
  --checkCaseReference: string # The check case reference you wish to filter on
  --page: int # The results for this endpoint are paginated and this refers to the page number (format: int32, default: 1)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar") (serialize-qp "checkCaseStatus" $checkCaseStatus "scalar") (serialize-qp "checkCaseReference" $checkCaseReference "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my-organisation/check-cases" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a check case
#
# POST /my-organisation/check-cases
# operationId: CreateCheckCase
export def "my-organisation-check-cases CreateCheckCase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my-organisation/check-cases")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# My organisation's check case
#
# GET /my-organisation/check-cases/{checkCaseSubmissionId}
# operationId: GetMyOrganisationsCheckCase
export def "my-organisation-check-cases GetMyOrganisationsCheckCase" [
  checkCaseSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --propertyLinkSubmissionId: string # The property link associated with this check case (e.g. PLQQ2YMP)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/my-organisation/check-cases/($checkCaseSubmissionId)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach check case evidence
#
# POST /my-organisation/check-cases/{checkCaseSubmissionId}/evidence
# operationId: AttachCheckCaseEvidence
export def "my-organisation-check-cases-evidence AttachCheckCaseEvidence" [
  checkCaseSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/check-cases/($checkCaseSubmissionId)/evidence")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Status of check case evidence
#
# GET /my-organisation/check-cases/{checkCaseSubmissionId}/evidence/{evidenceReference}
# operationId: GetCheckCaseEvidenceStatus
export def "my-organisation-check-cases-evidence GetCheckCaseEvidenceStatus" [
  checkCaseSubmissionId: string
  evidenceReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/check-cases/($checkCaseSubmissionId)/evidence/($evidenceReference)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# My organisation's challenge cases
#
# GET /my-organisation/challenge-cases
# operationId: GetMyOrganisationsChallengeCases
export def "my-organisation-challenge-cases GetMyOrganisationsChallengeCases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --propertyLinkSubmissionId: string # The property link you wish to filter on (e.g. PLQQ2YMP)
  --page: int # The results for this endpoint are paginated and this refers to the page number (format: int32, default: 1)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my-organisation/challenge-cases" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a challenge case
#
# POST /my-organisation/challenge-cases
# operationId: CreateChallengeCase
export def "my-organisation-challenge-cases CreateChallengeCase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my-organisation/challenge-cases")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# My organisation's challenge case
#
# GET /my-organisation/challenge-cases/{challengeCaseSubmissionId}
# operationId: GetMyOrganisationsChallengeCase
export def "my-organisation-challenge-cases GetMyOrganisationsChallengeCase" [
  challengeCaseSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projection: string@projection-completer # Return summary (simplified) projection, or detailed (full) view of the resource.
  --propertyLinkSubmissionId: string # The property link you wish to filter on
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projection" $projection "scalar") (serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/my-organisation/challenge-cases/($challengeCaseSubmissionId)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach challenge case evidence
#
# POST /my-organisation/challenge-cases/{challengeCaseSubmissionId}/evidence
# operationId: AttachChallengeCaseEvidence
export def "my-organisation-challenge-cases-evidence AttachChallengeCaseEvidence" [
  challengeCaseSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/challenge-cases/($challengeCaseSubmissionId)/evidence")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Status of challenge case evidence
#
# GET /my-organisation/challenge-cases/{challengeCaseSubmissionId}/evidence/{evidenceReference}
# operationId: GetChallengeCaseEvidenceStatus
export def "my-organisation-challenge-cases-evidence GetChallengeCaseEvidenceStatus" [
  challengeCaseSubmissionId: string
  evidenceReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/challenge-cases/($challengeCaseSubmissionId)/evidence/($evidenceReference)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# My clients
#
# GET /my-organisation/clients
# operationId: GetClients
export def "my-organisation-clients GetClients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientOrganisation: string # This parameter allows you to filter your clients by the start of their organisation's name
  --appointedFromDate: string # Filters the results to include only clients appointed on or after this date (format: date, e.g. 2020-01-31)
  --appointedToDate: string # Filters the results to include only clients appointed on or before this date (format: date, e.g. 2020-12-31)
  --page: int # The results for this endpoint are paginated and this refers to the page number (format: int32, default: 1)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientOrganisation" $clientOrganisation "scalar") (serialize-qp "appointedFromDate" $appointedFromDate "scalar") (serialize-qp "appointedToDate" $appointedToDate "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my-organisation/clients" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# My client's check cases
#
# GET /my-organisation/clients/all/check-cases
# operationId: GetMyClientsCheckCases
export def "my-organisation-clients-all-check-cases GetMyClientsCheckCases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --propertyLinkSubmissionId: string # The property link you wish to filter on
  --checkCaseStatus: string@checkCaseStatus-completer # The check case status you wish to filter on
  --checkCaseReference: string # The check case reference you wish to filter on
  --page: int # The results for this endpoint are paginated and this refers to the page number (format: int32, default: 1)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar") (serialize-qp "checkCaseStatus" $checkCaseStatus "scalar") (serialize-qp "checkCaseReference" $checkCaseReference "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my-organisation/clients/all/check-cases" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a client check case
#
# POST /my-organisation/clients/all/check-cases
# operationId: CreateCheckCaseForClient
export def "my-organisation-clients-all-check-cases CreateCheckCaseForClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my-organisation/clients/all/check-cases")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# My client's check case
#
# GET /my-organisation/clients/all/check-cases/{checkCaseSubmissionId}
# operationId: GetCheckCaseForClient
export def "my-organisation-clients-all-check-cases GetCheckCaseForClient" [
  checkCaseSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/clients/all/check-cases/($checkCaseSubmissionId)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach check case evidence for client
#
# POST /my-organisation/clients/all/check-cases/{checkCaseSubmissionId}/evidence
# operationId: AttachCheckCaseEvidenceForClient
export def "my-organisation-clients-all-check-cases-evidence AttachCheckCaseEvidenceForClient" [
  checkCaseSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/clients/all/check-cases/($checkCaseSubmissionId)/evidence")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Status of check case evidence for a client
#
# GET /my-organisation/clients/all/check-cases/{checkCaseSubmissionId}/evidence/{evidenceReference}
# operationId: GetClientCheckCaseEvidenceStatus
export def "my-organisation-clients-all-check-cases-evidence GetClientCheckCaseEvidenceStatus" [
  checkCaseSubmissionId: string
  evidenceReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/clients/all/check-cases/($checkCaseSubmissionId)/evidence/($evidenceReference)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# My client's challenge cases
#
# GET /my-organisation/clients/all/challenge-cases
# operationId: GetMyClientsChallengeCases
export def "my-organisation-clients-all-challenge-cases GetMyClientsChallengeCases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --propertyLinkSubmissionId: string # The property link you wish to filter on
  --page: int # The results for this endpoint are paginated and this refers to the page number (format: int32, default: 1)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my-organisation/clients/all/challenge-cases" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a client challenge case
#
# POST /my-organisation/clients/all/challenge-cases
# operationId: CreateChallengeCaseForClient
export def "my-organisation-clients-all-challenge-cases CreateChallengeCaseForClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my-organisation/clients/all/challenge-cases")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# My client's challenge case
#
# GET /my-organisation/clients/all/challenge-cases/{challengeCaseSubmissionId}
# operationId: GetChallengeCaseForClient
export def "my-organisation-clients-all-challenge-cases GetChallengeCaseForClient" [
  challengeCaseSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --propertyLinkSubmissionId: string # The property link associated with this challenge case
  --projection: string@projection-completer # Return summary (simplified) projection, or detailed (full) view of the resource.
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertyLinkSubmissionId" $propertyLinkSubmissionId "scalar") (serialize-qp "projection" $projection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/my-organisation/clients/all/challenge-cases/($challengeCaseSubmissionId)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach challenge case evidence for clients
#
# POST /my-organisation/clients/all/challenge-cases/{challengeCaseSubmissionId}/evidence
# operationId: AttachChallengeCaseEvidenceForClient
export def "my-organisation-clients-all-challenge-cases-evidence AttachChallengeCaseEvidenceForClient" [
  challengeCaseSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/clients/all/challenge-cases/($challengeCaseSubmissionId)/evidence")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Status of challenge case evidence for a client
#
# GET /my-organisation/clients/all/challenge-cases/{challengeCaseSubmissionId}/evidence/{evidenceReference}
# operationId: GetClientsChallengeCaseEvidenceStatus
export def "my-organisation-clients-all-challenge-cases-evidence GetClientsChallengeCaseEvidenceStatus" [
  challengeCaseSubmissionId: string
  evidenceReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/clients/all/challenge-cases/($challengeCaseSubmissionId)/evidence/($evidenceReference)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# My client's property links
#
# GET /my-organisation/clients/all/property-links
# operationId: GetMyClientsPropertyLinks
export def "my-organisation-clients-all-property-links GetMyClientsPropertyLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # Address, or part of the address (e.g. street name or postcode), to filter by
  --uarn: int # The Unique Address Reference Number (UARN) of the property (format: int64, e.g. 12345678901)
  --billingAuthorityReference: string # Filters the results to include properties which are inside the provided billing authority.
  --clientOrganisation: string # client's organsiation name to filter by
  --status: string@status-completer # The status of a property link to filter by
  --appointedFromDate: string # Filters the results to include only property-links where appointedDate is on or after this date (format: date, e.g. 2020-01-31)
  --appointedToDate: string # Filters the results to include only property-links where appointedDate is on or before this date (format: date, e.g. 2020-12-31)
  --page: int # The results for this endpoint are paginated and this refers to the page number (format: int32, default: 1)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --sortField: string@sortField-completer-1 # Field to sort the results by
  --sortDirection: string@sortDirection-completer # Results will be sorted in the specified direction (ascending or descending)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "uarn" $uarn "scalar") (serialize-qp "billingAuthorityReference" $billingAuthorityReference "scalar") (serialize-qp "clientOrganisation" $clientOrganisation "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "appointedFromDate" $appointedFromDate "scalar") (serialize-qp "appointedToDate" $appointedToDate "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortDirection" $sortDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my-organisation/clients/all/property-links" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create property link on client's behalf
#
# POST /my-organisation/clients/all/property-links
# operationId: CreatePropertyLinkForClient
export def "my-organisation-clients-all-property-links CreatePropertyLinkForClient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my-organisation/clients/all/property-links")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# My client's property link
#
# GET /my-organisation/clients/all/property-links/{propertyLinkSubmissionId}
# operationId: GetMyClientsPropertyLink
export def "my-organisation-clients-all-property-links GetMyClientsPropertyLink" [
  propertyLinkSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projection: string@projection-completer # Return summary (simplified) projection, or detailed (full) view of the resource. (default: summary)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projection" $projection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/my-organisation/clients/all/property-links/($propertyLinkSubmissionId)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attach property link evidence for a client
#
# POST /my-organisation/clients/all/property-links/{propertyLinkSubmissionId}/evidence
# operationId: AttachPropertyLinkEvidenceForClient
export def "my-organisation-clients-all-property-links-evidence AttachPropertyLinkEvidenceForClient" [
  propertyLinkSubmissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/clients/all/property-links/($propertyLinkSubmissionId)/evidence")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Status of property link evidence for a client
#
# GET /my-organisation/clients/all/property-links/{propertyLinkSubmissionId}/evidence/{evidenceReference}
# operationId: GetClientPropertyLinkEvidenceStatus
export def "my-organisation-clients-all-property-links-evidence GetClientPropertyLinkEvidenceStatus" [
  propertyLinkSubmissionId: string
  evidenceReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/clients/all/property-links/($propertyLinkSubmissionId)/evidence/($evidenceReference)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Messages summary
#
# GET /my-organisation/messages
# operationId: GetMessageSummary
export def "my-organisation-messages GetMessageSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ccaCaseRef: string # The ccaCaseRef of the check case
  --hereditamentAddress: string # The address of the check case
  --ipOrganisationName: string # The organisation the message relates to
  --isRead: string@bool-completer # Filters the results to include only messages that have been read (true) or have not been read (false)
  --fromCreatedDateTime: string # Filters the results to include only messages created on or after this datetime. Values must be in UTC format `YYYY-MM-DDThh:mm:ssZ` (format: date-time)
  --toCreatedDateTime: string # Filters the results to include only messages created on or before this datetime. Values must be in UTC format `YYYY-MM-DDThh:mm:ssZ` (format: date-time)
  --sortField: string@sortField-completer-2 # The sort field for the messages
  --page: int # The results for this endpoint are paginated and this refers to the page number (format: int32, default: 1)
  --pageSize: int # The results for this endpoint are paginated and this refers to the number of elements per page (format: int32, default: 15)
  --sortDirection: string@sortDirection-completer # Results will be sorted in the specified direction (ascending or descending)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ccaCaseRef" $ccaCaseRef "scalar") (serialize-qp "hereditamentAddress" $hereditamentAddress "scalar") (serialize-qp "ipOrganisationName" $ipOrganisationName "scalar") (serialize-qp "isRead" $isRead "scalar") (serialize-qp "fromCreatedDateTime" $fromCreatedDateTime "scalar") (serialize-qp "toCreatedDateTime" $toCreatedDateTime "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortDirection" $sortDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my-organisation/messages" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detailed message
#
# GET /my-organisation/messages/{messageId}
# operationId: GetMessageDetailed
export def "my-organisation-messages GetMessageDetailed" [
  messageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projection: string@projection-completer-1 # Currently only accepts 'data', 'html', and 'legacy' (default) projection.
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projection" $projection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/my-organisation/messages/($messageId)" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark message as read
#
# POST /my-organisation/messages/{messageId}
# operationId: MarkMessageAsRead
export def "my-organisation-messages MarkMessageAsRead" [
  messageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/my-organisation/messages/($messageId)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unread message count
#
# GET /my-organisation/messages/unreadCount
# operationId: UnreadMessageCount
export def "my-organisation-messages-unread-count UnreadMessageCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my-organisation/messages/unreadCount")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lookup values by type
#
# GET /lookup-codes/{lookupName}
# operationId: GetLookupValues
export def "lookup-codes GetLookupValues" [
  lookupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lookup-codes/($lookupName)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
