# Auto-generated client for Frankie Financial API v1.5.3
# Source: https://api.apis.guru/v2/specs/frankiefinancial.io/1.5.3/swagger.json
# Auth: --token flag or $env.FRANKIE_FINANCIAL_API_TOKEN

const BASE_URL = "https://api.demo.frankiefinancial.io/compliance/v1.2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FRANKIE_FINANCIAL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "api_key" => { {scheme: $scheme, headers: {api_key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.demo.frankiefinancial.io/compliance/v1.2"] }
def auth-scheme-completer [] { ["api_key" "none"] }

# Completers for enum parameters
def result-level-completer [] { ["full" "summary"] }
def validation-completer [] { ["acn" "off" "on" "only"] }
def entity-type-completer [] { ["INDIVIDUAL" "ORGANISATION" "TRUST"] }
def gender-completer [] { ["F" "M" "O" "U"] }
def document-status-completer [] { ["DOC_CHECKED" "DOC_SCANNED" "INITIALISING" "SCAN_IN_PROGRESS"] }
def id-type-completer [] { ["ANNUAL_RETURN" "ATTESTATION" "BANK_ACCOUNT" "BANK_STATEMENT" "BIRTH_CERT" "CHARGES" "CHECK_RESULTS" "CITIZENSHIP" "CONCESSION" "DEATH_CERT" "DEVICE" "DRIVERS_LICENCE" "EMAIL_ADDRESS" "EXTERNAL_ADMIN" "HEALTH_CONCESSION" "IMMIGRATION" "INTENT_PROOF" "MARRIAGE_CERT" "MILITARY_ID" "MOBILE_PHONE" "MSISDN" "NAME_CHANGE" "NATIONAL_HEALTH_ID" "NATIONAL_ID" "OTHER" "PASSPORT" "PENSION" "PRE_ASIC" "REPORT" "SELF_IMAGE" "TAX_ID" "UTILITY_BILL" "VEHICLE_REGISTRATION" "VISA"] }
def status-completer [] { ["FALSE_POSITIVE" "STALE" "TRUE_POSITIVE" "TRUE_POSITIVE_ACCEPT" "TRUE_POSITIVE_REJECT" "UNKNOWN"] }
def set-completer [] { ["archived" "clear" "fail" "inactive" "wait"] }
def risk-completer [] { ["high" "low" "medium" "significant" "unacceptable"] }
def payload-completer [] { ["object" "string"] }
def function-result-completer [] { ["COMPLETED" "FAILED" "INCOMPLETE"] }
def notification-type-completer [] { ["ALERT" "EVENT" "FUNCTION" "RESULT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "business-international-profile create" } } | get name | first)
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

# Retrieve a business profile from any country (AUS included).
#
# POST /business/international/profile
# operationId: InternationalBusinessProfile
export def "business-international-profile create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --company-code: string # This is the company number returned in the search results (InternationalBusinessSearchResponse.Companies.CompanyDTO[n].Code)
  country: string # The ISO 3166-1 alpha2 country code of country registry you wish to search. This is consistent for all countries except for: - The United States which requires the state registry to query as well. - As an example, for a Delaware query, the country code would be "US-DE". - A Texas query would use "US-TX" - Canada, which also requires you to supply a territory code too. - A Yukon query would use CA-YU, Manitoba would use CA-MB - You can do an all jurisdiction search with CA-ALL - United Arab Emirates (UAE) - For Abu Dhabi, use "DI" - For Dubai, use "DU" See details here: https://apidocs.frankiefinancial.com/docs/country-codes-for-international-business-queries
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business/international/profile")
  let req_body = {"company_code": $company_code, "country": $country} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search for a business from any country (AUS included).
#
# POST /business/international/search
# operationId: InternationalBusinessSearch
export def "business-international-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  country: string # The ISO 3166-1 alpha2 country code of country registry you wish to search. This is consistent for all countries except for: - The United States which requires the state registry to query as well. - As an example, for a Delaware query, the country code would be "US-DE". - A Texas query would use "US-TX" - Canada, which also requires you to supply a territory code too. - A Yukon query would use CA-YU, Manitoba would use CA-MB - You can do an all jurisdiction search with CA-ALL - United Arab Emirates (UAE) - For Abu Dhabi, use "DI" - For Dubai, use "DU" See details here: https://apidocs.frankiefinancial.com/docs/country-codes-for-international-business-queries
  --organisation-name: string # Name or name fragment you wish to search for. Note: The less you supply, the more, but less relevant results will be returned. CRITICAL NOTE: This is *NOT* to be used as a progressive search function. You must supply at least one of organisation_name and/or organisation_number. If you supply both, a name search will be conducted first, then the number will be checked against the result set and any remaining results returned.
  --organisation-number: string # The business number you wish to search on. This should be a unique corporate identifier as per the country registry you're searching.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business/international/search")
  let req_body = {"country": $country, "organisation_name": $organisation_name, "organisation_number": $organisation_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Business Entity and Query UBO (AUS Only)
#
# POST /business/ownership/query
# operationId: BusinessOwnershipQuery
# --organisation shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "business-ownership-query list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-type: list<string> # When creating a new check, we need to define the checks we wish to run. If this parameter is not supplied then the check will be based on a configured check type for each entity category. The checkType is make up of a comma separated list of the types of check we wish to run. The order is important, and must be of the form: - Entity Check (if you're running this). Choose one from the available options - ID Check (If you want this) - PEP Checks (again if you want this, choose one of the options) Entity Checks - One of: - "one_plus": Checks name, address and DoB against a minimum of 1 data source. (also known as a 1+1) - "two_plus": Checks name, address and DoB against a minimum of 2 independent data sources (also known as a 2+2) ID Checks - One of: - "id": Checks all of the identity documents, but not necessarily the entity itself independently. Use this in conjunction with a one_plus or two_plus for more. Fraud Checks - One or more of: - "fraudlist": Checks to see if the identity appears on any known fraud lists. Should be run after KYC/ID checks have passed. - "fraudid": Checks external ID services to see if details appear in fraud detection services (e.g. EmailAge or FraudNet) PEP Checks - One of: - "pep": Will only run PEP/Sanctions checks (no identity verification) - "pep_media": Will run PEP/Sanctions checks, as well as watchlist and adverse media checks. (no identity verification) * NOTE: These checks will ONLY run if either the KYC/ID checks have been run prior, or it is the only check requested. Pre-defined combinations: - "full": equivalent to "two_plus,id,pep_media" or "pep_media" if the target is an organisation. - "default": Currently defined as "two_plus,id" or "pep" if the target is an organisation. Custom: - By arrangement with Frankie you can define your own KYC check type. This will allow you to set the minimum number of matches for: - name - date of birth - address - government id This allows for alternatives to the "standard" two_plus or one_plus (note, these can be overridden too). Profile: - "profile": By arrangement with Frankie you can have a "profile" check type that applies checks according to a profile that you assign to the entity from a predefined set of profiles. The profile to use will be taken from the entity.entityProfile field if set, or be run through a set of configurable rules to determine which one to use. Profiles act a little like the Pre-defined combinations above in that they can map to a defined list. But they offer a lot more besides, including rules for determining default settings, inbuild data aging and other configurable features. They also allow for a new result set top be returned that provides a more detailed and useful breakdown of the check/verification process. Entity Profiles are the future of checks with Frankie Financial.
  --entity-categories: list<string> # A comma separated list that specifies the categories of entities associated with the target organisation that will be checked. - organisation - Just the organisation itself. - ubos - All ultimate beneficial owners. - pseudo_ubos - Use an alterntive category when an organisation has no actual UBOs. The actual category to use is defined via configuration, default is no alterntive category. - direct_owners - All direct owners of the company, both organisations and individuals, may include UBOs for for simple ownership. - officers - All officers of the company - officers_directors - All directors of the company - officers_other - All non-director officers of the company - all - All direct and indirect owners, both organisations and individuals (including UBOs), and officers of all organisations.
  --result-level: string@result-level-completer # The result level allows you to specify the level of detail returned for the entity check. You can choose summary or full. (default: summary)
  --validation: string@validation-completer # Should a validation check be run before the ownership query. The default is specified via configuration. The validation checks to see if the provided organisation is suitable for an ownership query by looking for the ACN in public data sources. Options are: - "on": Validate only when ACN is not provided. This is the typical default. - "acn": Validate even if ACN is provided. - "only": Like "acn" but only do validation query, don't proceed with ownership query. This option cannot be set as the default via configuration. - "off": Never validate. The Ownership query will then fail if an ACN is not provided.
  --generate-report: string # The type of human readable report, if any, to generate based on the ownership query results.
  --include-historical: oneof<nothing, bool> # If set to true, historical ownership data will be requested.
  --only-profile: oneof<nothing, bool> # If set to true, a full UBO report will not be requested.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  organisation: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checkType" $check_type "csv") (serialize-qp "entityCategories" $entity_categories "csv") (serialize-qp "resultLevel" $result_level "scalar") (serialize-qp "validation" $validation "scalar") (serialize-qp "generateReport" $generate_report "scalar") (serialize-qp "includeHistorical" $include_historical "scalar") (serialize-qp "onlyProfile" $only_profile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business/ownership/query" $qp)
  let req_body = {"organisation": $organisation} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"checkType": $check_type, "entityCategories": $entity_categories, "resultLevel": $result_level, "validation": $validation, "generateReport": $generate_report, "includeHistorical": $include_historical, "onlyProfile": $only_profile} | compact), body: $req_body}
}

# Run Report(s) against a new or existing organisation entity (AUS Only).
#
# POST /business/reports
# operationId: RunBusinessReports
# --addresses item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
# --dateOfBirth shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
# --flags item shape: {flag?: string, value?: int}
# --identityDocs item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
# --name shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
# --organisationData shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
export def "business-reports create-run" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-types: string # Define the report(s) you wish to run. You can request more than one as a comma separated list. Duplicates will be ignored. Note: These reports are different to the business details and UBO queries and are meant to provide deeper detail and background on a business or organisation. Current valid report types are: - creditScore - creditReport
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --date-of-birth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entity-id: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entity-profile: string # If the entity is using the new profiles feature, then their profile name will be found here. Note: If setting a profile, you must ensure that the profile matches a known configuration. Please contact Frankie developer support if you're unsure as to what valid values are.
  --entity-type: string@entity-type-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extra-data: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added. See here for more information about possible values you can use: https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, ... (2 more fields)}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing. Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale - "F"emale - "U"nspecified - "O"ther (for want of a better option) (e.g. F)
  --identity-docs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisation-data: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportTypes" $report_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business/reports" $qp)
  let req_body = {"addresses": $addresses, "dateOfBirth": $date_of_birth, "entityId": $entity_id, "entityProfile": $entity_profile, "entityType": $entity_type, "extraData": $extra_data, "flags": $flags, "gender": $gender, "identityDocs": $identity_docs, "name": $name, "organisationData": $organisation_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"reportTypes": $report_types} | compact), body: $req_body}
}

# Run KYC/AML Checks on Organisation and/or Associated Individuals.
#
# POST /business/{entityId}/verify
# operationId: CheckOrganisation
export def "business-verify check-organisation" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-type: list<string> # When creating a new check, we need to define the checks we wish to run. If this parameter is not supplied then the check will be based on a configured check type for each entity category. The checkType is make up of a comma separated list of the types of check we wish to run. The order is important, and must be of the form: - Entity Check (if you're running this). Choose one from the available options - ID Check (If you want this) - PEP Checks (again if you want this, choose one of the options) Entity Checks - One of: - "one_plus": Checks name, address and DoB against a minimum of 1 data source. (also known as a 1+1) - "two_plus": Checks name, address and DoB against a minimum of 2 independent data sources (also known as a 2+2) ID Checks - One of: - "id": Checks all of the identity documents, but not necessarily the entity itself independently. Use this in conjunction with a one_plus or two_plus for more. Fraud Checks - One or more of: - "fraudlist": Checks to see if the identity appears on any known fraud lists. Should be run after KYC/ID checks have passed. - "fraudid": Checks external ID services to see if details appear in fraud detection services (e.g. EmailAge or FraudNet) PEP Checks - One of: - "pep": Will only run PEP/Sanctions checks (no identity verification) - "pep_media": Will run PEP/Sanctions checks, as well as watchlist and adverse media checks. (no identity verification) * NOTE: These checks will ONLY run if either the KYC/ID checks have been run prior, or it is the only check requested. Pre-defined combinations: - "full": equivalent to "two_plus,id,pep_media" or "pep_media" if the target is an organisation. - "default": Currently defined as "two_plus,id" or "pep" if the target is an organisation. Custom: - By arrangement with Frankie you can define your own KYC check type. This will allow you to set the minimum number of matches for: - name - date of birth - address - government id This allows for alternatives to the "standard" two_plus or one_plus (note, these can be overridden too). Profile: - "profile": By arrangement with Frankie you can have a "profile" check type that applies checks according to a profile that you assign to the entity from a predefined set of profiles. The profile to use will be taken from the entity.entityProfile field if set, or be run through a set of configurable rules to determine which one to use. Profiles act a little like the Pre-defined combinations above in that they can map to a defined list. But they offer a lot more besides, including rules for determining default settings, inbuild data aging and other configurable features. They also allow for a new result set top be returned that provides a more detailed and useful breakdown of the check/verification process. Entity Profiles are the future of checks with Frankie Financial.
  --entity-categories: list<string> # A comma separated list that specifies the categories of entities associated with the target organisation that will be checked. - organisation - Just the organisation itself. - ubos - All ultimate beneficial owners. - pseudo_ubos - Use an alterntive category when an organisation has no actual UBOs. The actual category to use is defined via configuration, default is no alterntive category. - direct_owners - All direct owners of the company, both organisations and individuals, may include UBOs for for simple ownership. - officers - All officers of the company - officers_directors - All directors of the company - officers_other - All non-director officers of the company - all - All direct and indirect owners, both organisations and individuals (including UBOs), and officers of all organisations.
  --result-level: string@result-level-completer # The result level allows you to specify the level of detail returned for the entity check. You can choose summary or full. (default: summary)
  --generate-report: string # The type of human readable report, if any, to generate based on the ownership query results.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "checkType" $check_type "csv") (serialize-qp "entityCategories" $entity_categories "csv") (serialize-qp "resultLevel" $result_level "scalar") (serialize-qp "generateReport" $generate_report "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/business/{entity_id}/verify") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"checkType": $check_type, "entityCategories": $entity_categories, "resultLevel": $result_level, "generateReport": $generate_report} | compact), body: null}
}

# Create New Document.
#
# POST /document
# operationId: CreateDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
export def "document create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document")
  let req_body = {"country": $country, "docScan": $doc_scan, "documentId": $document_id, "documentStatus": $document_status, "extraData": $extra_data, "idExpiry": $id_expiry, "idIssued": $id_issued, "idNumber": $id_number, "idSubType": $id_sub_type, "idType": $id_type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Document and Compare to Original.
#
# POST /document/new/compare
# operationId: CompareDocument
# --compareDocument shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
# --toDocument shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
export def "document-new-compare create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --compare-document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --to-document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document/new/compare")
  let req_body = {"compareDocument": $compare_document, "toDocument": $to_document} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create and OCR Scan Document.
#
# POST /document/new/scan
# operationId: CreateScanDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
export def "document-new-scan create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document/new/scan")
  let req_body = {"country": $country, "docScan": $doc_scan, "documentId": $document_id, "documentStatus": $document_status, "extraData": $extra_data, "idExpiry": $id_expiry, "idIssued": $id_issued, "idNumber": $id_number, "idSubType": $id_sub_type, "idType": $id_type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Document and Run Utility Price Comparison.
#
# POST /document/new/utility/process/compare
# operationId: CreateProcessIndustryUtilityDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
export def "document-new-utility-process-compare create-industry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-limit: int # The maximum number of plans to return (default: 30)
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planLimit" $plan_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/document/new/utility/process/compare" $qp)
  let req_body = {"country": $country, "docScan": $doc_scan, "documentId": $document_id, "documentStatus": $document_status, "extraData": $extra_data, "idExpiry": $id_expiry, "idIssued": $id_issued, "idNumber": $id_number, "idSubType": $id_sub_type, "idType": $id_type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"planLimit": $plan_limit} | compact), body: $req_body}
}

# Create and Verify Document.
#
# POST /document/new/verify
# operationId: VerifyDocument
# --document shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
# --entityData shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "document-new-verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --entity-data: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document/new/verify")
  let req_body = {"document": $document, "entityData": $entity_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search For a Document !! EXPERIMENTAL !!
#
# POST /document/search
# operationId: SearchDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
export def "document-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document/search")
  let req_body = {"country": $country, "docScan": $doc_scan, "documentId": $document_id, "documentStatus": $document_status, "extraData": $extra_data, "idExpiry": $id_expiry, "idIssued": $id_issued, "idNumber": $id_number, "idSubType": $id_sub_type, "idType": $id_type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Document.
#
# DELETE /document/{documentId}
# operationId: DeleteDocument
export def "document delete" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve Document Details
#
# GET /document/{documentId}
# operationId: QueryDocument
export def "document list" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Existing Document.
#
# POST /document/{documentId}
# operationId: UpdateDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
export def "document update" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --no-invalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --body-document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let qp = [(serialize-qp "noInvalidate" $no_invalidate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}") $qp)
  let req_body = {"country": $country, "docScan": $doc_scan, "documentId": $body_document_id, "documentStatus": $document_status, "extraData": $extra_data, "idExpiry": $id_expiry, "idIssued": $id_issued, "idNumber": $id_number, "idSubType": $id_sub_type, "idType": $id_type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"noInvalidate": $no_invalidate} | compact), body: $req_body}
}

# Retrieve Document Verification Check Details.
#
# GET /document/{documentId}/checks
# operationId: QueryDocumentChecks
export def "document-checks list" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}/checks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Document and Compare to Original.
#
# POST /document/{documentId}/compare
# operationId: UpdateCompareDocument
# --compareDocument shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
# --toDocument shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
export def "document-compare update" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --compare-document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --to-document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}/compare"))
  let req_body = {"compareDocument": $compare_document, "toDocument": $to_document} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve Document and Scan Data
#
# GET /document/{documentId}/full
# operationId: QueryDocumentFull
export def "document-full list" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}/full"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update and OCR Scan Document
#
# POST /document/{documentId}/scan
# operationId: UpdateScanDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
export def "document-scan update" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --body-document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}/scan"))
  let req_body = {"country": $country, "docScan": $doc_scan, "documentId": $body_document_id, "documentStatus": $document_status, "extraData": $extra_data, "idExpiry": $id_expiry, "idIssued": $id_issued, "idNumber": $id_number, "idSubType": $id_sub_type, "idType": $id_type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Document and Run Utility Price Comparison.
#
# POST /document/{documentId}/utility/process/compare
# operationId: UpdateProcessIndustryUtilityDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
export def "document-utility-process-compare update-industry" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-limit: int # The maximum number of plans to return (default: 30)
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed. See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more (e.g. AUS)
  --doc-scan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls. Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, ... (4 more fields)}
  --body-document-id: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --document-status: string@document-status-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned. - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error. (e.g. DOC_SCANNED)
  --extra-data: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added. If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, ... (2 more fields)}
  --id-expiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --id-issued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --id-number: string # The ID number of the document (if known). (e.g. 123456789)
  --id-sub-type: string # The sub-type of identity document. Very document specific.
  id_type: string@id-type-completer # Valid ID types - "OTHER": Generic document type. Unspecified. - "DRIVERS_LICENCE": Driver's licence. - "PASSPORT": Passport - "VISA": Visa document (not Visa payment card) - "IMMIGRATION": Immigration card - "NATIONAL_ID": Any national ID card - "TAX_ID": Any national tax identifier - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS) - "CONCESSION": State issued concession card - "HEALTH_CONCESSION": State issued health specific concession card - "PENSION": State issued pension ID - "MILITARY_ID": Military ID - "BIRTH_CERT": Birth certificate - "CITIZENSHIP": Citizenship certificate - "MARRIAGE_CERT": Marriage certificate - "DEATH_CERT": Death certificate - "NAME_CHANGE": Name chage confirmation - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc - "BANK_STATEMENT": Bank/card statement - "BANK_ACCOUNT": Bank account - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter - "ATTESTATION": A document of attestation (e.g. Statutory Declaration) - "SELF_IMAGE": A "selfie" used for comparisions - "EMAIL_ADDRESS": An email address - "MSISDN": A mobile phone number - "DEVICE": A device ID - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation - "EXTERNAL_ADMIN": Details of appointed administrator. - "CHARGES": Details of any charges that have been laid against a company or director - "PRE_ASIC": Any documents that are Pre-ASIC - "ANNUAL_RETURN": Details of a company's annual return - "REPORT": Frankie generated report. Special document types - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie. (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence) You should always use the local abbreviation for this. E.g. - VIC for The Australian state of Victoria - MA for the US state of Massachusetts - etc (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let qp = [(serialize-qp "planLimit" $plan_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}/utility/process/compare") $qp)
  let req_body = {"country": $country, "docScan": $doc_scan, "documentId": $body_document_id, "documentStatus": $document_status, "extraData": $extra_data, "idExpiry": $id_expiry, "idIssued": $id_issued, "idNumber": $id_number, "idSubType": $id_sub_type, "idType": $id_type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"planLimit": $plan_limit} | compact), body: $req_body}
}

# Provide Explicit Consent to Switch Utility Plans.
#
# POST /document/{documentId}/utility/process/consent
# operationId: UpdateProcessIndustryUtilityDocumentConsent
# --details shape: {concessionCard?: record, vulnerabilities?: record}
export def "document-utility-process-consent update-industry" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  correlation_id: string # Correlation ID as passed to comparison request (format: uuid, e.g. d290f1ee-6c54-4b01-90e6-d701748f0851)
  --details: record # Information for the residents of the property being supplied — shape: {concessionCard?: record, vulnerabilities?: record}
  plan_id: string # Unique ID of plan, selected from comparison results (format: string, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}/utility/process/consent"))
  let req_body = {"correlationId": $correlation_id, "details": $details, "planId": $plan_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Initiate Switching of Utility Plan.
#
# POST /document/{documentId}/utility/process/switch
# operationId: UpdateProcessIndustryUtilityDocumentSwitch
# --details shape: {customerDetails: record}
export def "document-utility-process-switch update-industry" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --confirmation: list<string> # Array of strings containing all the keys of the elements that required confirmation in the EIC. The absence of any key for a mandatory confirmation will result in an error response.
  correlation_id: string # Correlation ID as passed to comparison request (format: uuid, e.g. d290f1ee-6c54-4b01-90e6-d701748f0851)
  details: record # Details required to switch retailers — shape: {customerDetails: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}/utility/process/switch"))
  let req_body = {"confirmation": $confirmation, "correlationId": $correlation_id, "details": $details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update and Verify Document.
#
# POST /document/{documentId}/verify
# operationId: UpdateVerifyDocument
# --document shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
# --entityData shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "document-verify update" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --entity-data: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/document/{document_id}/verify"))
  let req_body = {"document": $document, "entityData": $entity_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create New Entity.
#
# POST /entity
# operationId: CreateEntity
# --addresses item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
# --dateOfBirth shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
# --flags item shape: {flag?: string, value?: int}
# --identityDocs item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
# --name shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
# --organisationData shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
export def "entity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --date-of-birth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entity-id: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entity-profile: string # If the entity is using the new profiles feature, then their profile name will be found here. Note: If setting a profile, you must ensure that the profile matches a known configuration. Please contact Frankie developer support if you're unsure as to what valid values are.
  --entity-type: string@entity-type-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extra-data: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added. See here for more information about possible values you can use: https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, ... (2 more fields)}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing. Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale - "F"emale - "U"nspecified - "O"ther (for want of a better option) (e.g. F)
  --identity-docs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisation-data: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entity")
  let req_body = {"addresses": $addresses, "dateOfBirth": $date_of_birth, "entityId": $entity_id, "entityProfile": $entity_profile, "entityType": $entity_type, "extraData": $extra_data, "flags": $flags, "gender": $gender, "identityDocs": $identity_docs, "name": $name, "organisationData": $organisation_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Entity and Get IDV Token
#
# POST /entity/new/idvalidate/getToken
# operationId: CreateEntityGetIDVToken
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-new-idvalidate-get-token create-idv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --applicant-id: string # The applicantId previously supplied when creating a token for the first time for an entity. Only required if re-submitting for a fresh token on a previously created applicant.
  --application-id: string # If this is for a native application SDK, then we need the applicationId as reported by the SDK. This will then be tied to the token so it cannot be used in another application or handset. You must send either an applicationID or a referrer (see below)
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
  --referrer: string # If this is for a web SDK, then you need to supply the referrer domain so that the token can be validated by the IDV service You must send either a referrer or an applicationID (see above)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entity/new/idvalidate/getToken")
  let req_body = {"applicantId": $applicant_id, "applicationId": $application_id, "entity": $entity, "referrer": $referrer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Entity and Push Self-Verification Link
#
# POST /entity/new/verify/pushToMobile
# operationId: CreateCheckEntityPushToMobile
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-new-verify-push-to-mobile create-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nopush: oneof<nothing, bool> # If set to true, then no SMS/email will be pushed. It will be up to the API caller to manage the delivery of the link.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nopush" $nopush "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entity/new/verify/pushToMobile" $qp)
  let req_body = {"deviceCheckDetails": $device_check_details, "entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"nopush": $nopush} | compact), body: $req_body}
}

# Create and Verify Entity
#
# POST /entity/new/verify/{checkType}/{resultLevel}
# operationId: CreateCheckEntity
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-new-verify create-check" [
  check_type: string
  result_level: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($check_type | is-empty) { error make --unspanned { msg: "path parameter 'checkType' must be non-empty" } }
  if ($result_level | is-empty) { error make --unspanned { msg: "path parameter 'resultLevel' must be non-empty" } }
  let full_url = (build-url $base ({check_type: (encode-path-segment $check_type), result_level: (encode-path-segment $result_level)} | format pattern "/entity/new/verify/{check_type}/{result_level}"))
  let req_body = {"deviceCheckDetails": $device_check_details, "entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search for Entity
#
# POST /entity/search
# operationId: SearchEntity
# --addresses item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
# --dateOfBirth shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
# --flags item shape: {flag?: string, value?: int}
# --identityDocs item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
# --name shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
# --organisationData shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
export def "entity-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --date-of-birth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entity-id: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entity-profile: string # If the entity is using the new profiles feature, then their profile name will be found here. Note: If setting a profile, you must ensure that the profile matches a known configuration. Please contact Frankie developer support if you're unsure as to what valid values are.
  --entity-type: string@entity-type-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extra-data: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added. See here for more information about possible values you can use: https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, ... (2 more fields)}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing. Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale - "F"emale - "U"nspecified - "O"ther (for want of a better option) (e.g. F)
  --identity-docs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisation-data: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entity/search")
  let req_body = {"addresses": $addresses, "dateOfBirth": $date_of_birth, "entityId": $entity_id, "entityProfile": $entity_profile, "entityType": $entity_type, "extraData": $extra_data, "flags": $flags, "gender": $gender, "identityDocs": $identity_docs, "name": $name, "organisationData": $organisation_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Entity
#
# DELETE /entity/{entityId}
# operationId: DeleteEntity
export def "entity delete" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve Entity Details
#
# GET /entity/{entityId}
# operationId: QueryEntity
export def "entity list" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Existing Entity.
#
# POST /entity/{entityId}
# operationId: UpdateEntity
# --addresses item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
# --dateOfBirth shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
# --extraData item shape: {kvpKey?: string, ... (2 more fields)}
# --flags item shape: {flag?: string, value?: int}
# --identityDocs item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
# --name shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
# --organisationData shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
export def "entity update" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --no-invalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --date-of-birth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --body-entity-id: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it. (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entity-profile: string # If the entity is using the new profiles feature, then their profile name will be found here. Note: If setting a profile, you must ensure that the profile matches a known configuration. Please contact Frankie developer support if you're unsure as to what valid values are.
  --entity-type: string@entity-type-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extra-data: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added. See here for more information about possible values you can use: https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, ... (2 more fields)}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing. Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale - "F"emale - "U"nspecified - "O"ther (for want of a better option) (e.g. F)
  --identity-docs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, ... (2 more fields)}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisation-data: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "noInvalidate" $no_invalidate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}") $qp)
  let req_body = {"addresses": $addresses, "dateOfBirth": $date_of_birth, "entityId": $body_entity_id, "entityProfile": $entity_profile, "entityType": $entity_type, "extraData": $extra_data, "flags": $flags, "gender": $gender, "identityDocs": $identity_docs, "name": $name, "organisationData": $organisation_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"noInvalidate": $no_invalidate} | compact), body: $req_body}
}

# Update Check Result States (Batch)
#
# POST /entity/{entityId}/check/{checkId}/{checkClass}
# operationId: UpdateCheckClassResults
export def "entity-check update-class-results" [
  entity_id: string
  check_id: string
  check_class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --check-class-ids: list<string>
  comment: string
  --status: string@status-completer # Indicates the status of a check result as set by a user. - "UNKNOWN": The user has not decided so the actual check result applies as normal. - "TRUE_POSITIVE": The check result has been acknowledged as correct but the final effect (accept/reject) has not been decided. - "TRUE_POSITIVE_ACCEPT": The check result is correct but will be ignored. This is also known as 'whitelisting' - "TRUE_POSITIVE_REJECT": The check result is correct and will be used. - "FALSE_POSITIVE": The check result is not applicable and will be ignored. - "STALE": The check result will become invisible, will not be considered and will not count towards due diligence requirements.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'checkId' must be non-empty" } }
  if ($check_class | is-empty) { error make --unspanned { msg: "path parameter 'checkClass' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id), check_id: (encode-path-segment $check_id), check_class: (encode-path-segment $check_class)} | format pattern "/entity/{entity_id}/check/{check_id}/{check_class}"))
  let req_body = {"checkClassIds": $check_class_ids, "comment": $comment, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Check Result State
#
# POST /entity/{entityId}/check/{checkId}/{checkClass}/{checkClassId}
# operationId: UpdateCheckClassResult
export def "entity-check update-class-result" [
  entity_id: string
  check_id: string
  check_class: string
  check_class_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Set the new status of the Check Class (PRO/BCRO). Valid values are: - "unknown" - "true_positive" - "true_positive_accept" - "true_positive_reject" - "false_positive" - "stale"
  --undo: oneof<nothing, bool> # Undo a prior operation.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'checkId' must be non-empty" } }
  if ($check_class | is-empty) { error make --unspanned { msg: "path parameter 'checkClass' must be non-empty" } }
  if ($check_class_id | is-empty) { error make --unspanned { msg: "path parameter 'checkClassId' must be non-empty" } }
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "undo" $undo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id), check_id: (encode-path-segment $check_id), check_class: (encode-path-segment $check_class), check_class_id: (encode-path-segment $check_class_id)} | format pattern "/entity/{entity_id}/check/{check_id}/{check_class}/{check_class_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"status": $status, "undo": $undo} | compact), body: null}
}

# Retrieve Entity Verication Check Details
#
# GET /entity/{entityId}/checks
# operationId: QueryEntityChecks
export def "entity-checks list" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alldata: oneof<nothing, bool> # Requests that literally all data should be included in the response to a "get checks" request. This is as opposed to a filtered view where expired results are by default not included for entities that have an assigned profile.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "alldata" $alldata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/checks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"alldata": $alldata} | compact), body: null}
}

# Set Entity Blacklist State.
#
# POST /entity/{entityId}/flag/blacklist
# operationId: BlacklistEntity
export def "entity-flag-blacklist create" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag.
  --reason: string # Set the reason for blacklisting. Valid values are: - "NO_REASON_SUPPLIED" - "FABRICATED_IDENTITY" - "IDENTITY_TAKEOVER" - "FALSIFIED_ID_DOCUMENTS" - "STOLEN_ID_DOCUMENTS" - "MERCHANT_FRAUD" - "NEVER_PAY_BUST_OUT" - "CONFLICTING_DATA_PROVIDED" - "MONEY_MULE" - "FALSE_FRAUD_CLAIM" - "FRAUDULENT_3RD_PARTY" - "COMPANY_TAKEOVER" - "FICTITIOUS_EMPLOYER" - "COLLUSIVE_EMPLOYER" - "OVER_VALUATION_OF_ASSETS" - "FALSIFIED_EMPLOYMENT_DETAILS" - "MANIPULATED_IDENTITY" - "SYNDICATED_FRAUD" - "INTERNAL_FRAUD" - "BANK_FRAUD" - "UNDISCLOSED_DATA" - "FALSE_HARDSHIP" - "SMR_REPORT_LODGED" - "2X_SMR_REPORTS_LODGED"
  --blocked-by: string # Specify who is setting the entity as blacklisted.
  --attribute: string # Specify the blacklisted attribute. Valid values are: - "ENTIRE_PROFILE" - "FULL_NAME" - "EMAIL_ADDRESS" - "PHONE_NUMBER" - "ID_DOCUMENT" - "MAILING_ADDRESS" - "RESIDENTIAL_ADDRESS"
  --original-id: string # Specify the Id of the matching blacklisted entity or single data-point.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "set" $set "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "blockedBy" $blocked_by "scalar") (serialize-qp "attribute" $attribute "scalar") (serialize-qp "originalId" $original_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/flag/blacklist") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"set": $set, "reason": $reason, "blockedBy": $blocked_by, "attribute": $attribute, "originalId": $original_id} | compact), body: null}
}

# Resolve Duplicate States.
#
# POST /entity/{entityId}/flag/duplicate/{otherId}
# operationId: FlagDuplicateEntity
export def "entity-flag-duplicate create" [
  entity_id: string
  other_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($other_id | is-empty) { error make --unspanned { msg: "path parameter 'otherId' must be non-empty" } }
  let qp = [(serialize-qp "set" $set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id), other_id: (encode-path-segment $other_id)} | format pattern "/entity/{entity_id}/flag/duplicate/{other_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"set": $set} | compact), body: null}
}

# Set Entity Ongoing AML Monitoring Status.
#
# POST /entity/{entityId}/flag/monitor
# operationId: EntityMonitoring
export def "entity-flag-monitor create-monitoring" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "set" $set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/flag/monitor") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"set": $set} | compact), body: null}
}

# Set Entity Watchlist State.
#
# POST /entity/{entityId}/flag/watchlist
# operationId: WatchlistEntity
export def "entity-flag-watchlist create" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag.
  --reason: string # Set the reason for watchlisting. Valid values are: - "WAS_BLACKLISTED"
  --comment: string # A comment describing the reason for a request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "set" $set "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/flag/watchlist") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"set": $set, "reason": $reason, "comment": $comment} | compact), body: null}
}

# Retrieve Entity Details and Document Scan Data
#
# GET /entity/{entityId}/full
# operationId: QueryEntityFull
export def "entity-full list" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/full"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Entity and Get IDV Token
#
# POST /entity/{entityId}/idvalidate/getToken
# operationId: UpdateEntityGetIDVToken
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-idvalidate-get-token update-idv" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --applicant-id: string # The applicantId previously supplied when creating a token for the first time for an entity. Only required if re-submitting for a fresh token on a previously created applicant.
  --application-id: string # If this is for a native application SDK, then we need the applicationId as reported by the SDK. This will then be tied to the token so it cannot be used in another application or handset. You must send either an applicationID or a referrer (see below)
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
  --referrer: string # If this is for a web SDK, then you need to supply the referrer domain so that the token can be validated by the IDV service You must send either a referrer or an applicationID (see above)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/idvalidate/getToken"))
  let req_body = {"applicantId": $applicant_id, "applicationId": $application_id, "entity": $entity, "referrer": $referrer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Entity and Initiate IDV Process
#
# POST /entity/{entityId}/idvalidate/initProcess
# operationId: UpdateEntityInitIDVProcess
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-idvalidate-init-process update-idv" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/idvalidate/initProcess"))
  let req_body = {"deviceCheckDetails": $device_check_details, "entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Entity States
#
# POST /entity/{entityId}/status
# operationId: UpdateEntityState
export def "entity-status update-state" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: string@set-completer # The status of an entity. Valid values are: - "wait": Waiting for new details from entity. - "fail": Manually fail the onboarding process. - "archived": Hide entity from on onboarding. - "clear": Remove any of the above manual states as well as any manual risk. - "inactive": Hide entity and prevent any further operations on it. Cannot be cleared.
  --risk: string@risk-completer # The risk override setting for an entity. This value will be used until a verify result updates a real risk factor. Valid values are: - "low" - "medium" - "high" - "unacceptable" - "significant"
  --comment: string # A comment describing the reason for a request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "set" $set "scalar") (serialize-qp "risk" $risk "scalar") (serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/status") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"set": $set, "risk": $risk, "comment": $comment} | compact), body: null}
}

# Update Entity and Push Self-Verification Link
#
# POST /entity/{entityId}/verify/pushToMobile
# operationId: UpdateCheckEntityPushToMobile
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-verify-push-to-mobile update-check" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nopush: oneof<nothing, bool> # If set to true, then no SMS/email will be pushed. It will be up to the API caller to manage the delivery of the link.
  --phase: int # Set the Push To Mobile phase. Currently supported values: - 2
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "nopush" $nopush "scalar") (serialize-qp "phase" $phase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/entity/{entity_id}/verify/pushToMobile") $qp)
  let req_body = {"deviceCheckDetails": $device_check_details, "entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"nopush": $nopush, "phase": $phase} | compact), body: $req_body}
}

# Update Entity and Verify Details
#
# POST /entity/{entityId}/verify/{checkType}/{resultLevel}
# operationId: UpdateCheckEntity
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-verify update-check" [
  entity_id: string
  check_type: string
  result_level: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force the verification to run, overriding any data aging or past check
  --no-invalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
  --x-frankie-background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this. See more details here: https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --device-check-details: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($check_type | is-empty) { error make --unspanned { msg: "path parameter 'checkType' must be non-empty" } }
  if ($result_level | is-empty) { error make --unspanned { msg: "path parameter 'resultLevel' must be non-empty" } }
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "noInvalidate" $no_invalidate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id), check_type: (encode-path-segment $check_type), result_level: (encode-path-segment $result_level)} | format pattern "/entity/{entity_id}/verify/{check_type}/{result_level}") $qp)
  let req_body = {"deviceCheckDetails": $device_check_details, "entity": $entity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id, "X-Frankie-Background": $x_frankie_background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"force": $force, "noInvalidate": $no_invalidate} | compact), body: $req_body}
}

# (Re)retrieve Response Result.
#
# GET /retrieve/response/{requestId}
# operationId: RetrieveResult
export def "retrieve-response get-result" [
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string@payload-completer # Specifies the type of the payload field in the retrieved response. Default is 'string'.
  --x-frankie-customer-id: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --x-frankie-customer-child-id: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID. Note: If using a CustomerChildID, you will also need a separate api_key for each child. Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data. A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($request_id | is-empty) { error make --unspanned { msg: "path parameter 'requestId' must be non-empty" } }
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({request_id: (encode-path-segment $request_id)} | format pattern "/retrieve/response/{request_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Frankie-CustomerID": $x_frankie_customer_id, "X-Frankie-CustomerChildID": $x_frankie_customer_child_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"payload": $payload} | compact), body: null}
}

# Service Status
#
# GET /ruok
# operationId: StatusCheck
export def "ruok check-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asking-nicely: oneof<nothing, bool> # If set to true, the request is being made politely.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "askingNicely" $asking_nicely "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ruok" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"askingNicely": $asking_nicely} | compact), body: null}
}

# Push Notification Payload
#
# POST /your/configured/path/{requestId}
# operationId: notifyResult
export def "your-configured-path notify-result" [
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --check-id: string # If you're calling a processing function of some kind, a check number will be issued. This field will only be present if the function you're calling would normally return a checkId (such as scan, verify, and compare). (format: uuid)
  --document-id: string # Only supplied if the original request was tied to a document. This will be the same ID that was sent in the original acceptance. (format: uuid)
  --entity-customer-reference: string # If the entity in entityId above has had an external service ID attached to it in the entity extraData with kvpKey = customer_reference, then this is that kvpValue (e.g. AU0123456)
  --entity-id: string # Only supplied if the original request was tied to an entity. This will be the same ID that was sent in the original acceptance. (format: uuid)
  --function: string # Short description of the original function called, or function that was triggered. (e.g. entity.create)
  --function-result: string@function-result-completer # High level indication of the final disposition of a backgrounded function - "COMPLETED": the request completed (not that the final result is a success, just that we completed) - "FAILED": the request failed. - "INCOMPLETE": could not complete the request. (e.g. COMPLETED)
  --link-reference: string # URI for resource containing more details about the reason for the notification. (format: uri, e.g. https://portal.frankiefinancial.io/entity/3fa85f64-5717-4562-b3fc-2c963f66afa6)
  --message: string # A brief, human readable message describing the reason for the notification. (e.g. Entity successfully created)
  --notification-type: string@notification-type-completer # Indicates the type of notification being pushed. - "FUNCTION": A request that you previously backgrounded has completed and this is the notification that is it complete (success is another matter) - "RESULT": Like the FUNCTION notification, this tells you that a previously backgrounded request has completed, and that there is a set of results in the payload pointer. - "EVENT": There has been a stateful change in a document, entity or some other piece of data that we are holding/monitoring for you. This is an indication that you may wish to take some action. - "ALERT": Like the EVENT, except that the severity of the notification indicates that action is almost certainly required.
  --body-request-id: string # Unique identifier for every request. Can be used for tracking down answers with technical support. Uses the ULID format (a time-based, sortable UUID) Note: this will be different for every request. (format: ulid, e.g. 01BFJA617JMJXEW6G7TDDXNSHX)
  --username: string # The portal username that initiated the operation that led to this notification. If applicable and available.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($request_id | is-empty) { error make --unspanned { msg: "path parameter 'requestId' must be non-empty" } }
  let full_url = (build-url $base ({request_id: (encode-path-segment $request_id)} | format pattern "/your/configured/path/{request_id}"))
  let req_body = {"checkId": $check_id, "documentId": $document_id, "entityCustomerReference": $entity_customer_reference, "entityId": $entity_id, "function": $function, "functionResult": $function_result, "linkReference": $link_reference, "message": $message, "notificationType": $notification_type, "requestId": $body_request_id, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
