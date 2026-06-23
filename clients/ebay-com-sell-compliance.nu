# Auto-generated client for Compliance API v1.4.1
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-compliance/1.4.1/openapi.json
# Auth: --token flag or $env.COMPLIANCE_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/compliance/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o COMPLIANCE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.ebay.com/sell/compliance/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "listing-violation get" } } | get name | first)
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

# This call returns specific listing violations for the supported listing compliance types. Only one compliance type can be passed in per call, and the response will include all the listing violations for this compliance type, and listing violations are grouped together by eBay listing ID. See ComplianceTypeEnum for more information on the supported listing compliance types. This method also has pagination control. Note: A maximum of 2000 listing violations will be returned in a result set. If the seller has more than 2000 listing violations, some/all of those listing violations must be corrected before additional listing violations will be retrieved. The user should pay attention to the total value in the response. If this value is '2000', it is possible that the seller has more than 2000 listing violations, but this field maxes out at 2000. Note: In a future release of this API, the seller will be able to pass in a specific eBay listing ID as a query parameter to see if this specific listing has any violations. Note: Only mocked non-compliant listing data will be returned for this call in the Sandbox environment, and not specific to the seller. However, the user can still use this mock data to experiment with the compliance type filters and pagination control.
#
# GET /listing_violation
# operationId: getListingViolations
export def "listing-violation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compliance-type: string # A seller uses this query parameter to retrieve listing violations of a specific compliance type. Only one compliance type value should be passed in here. See ComplianceTypeEnum for more information on the compliance types that can be passed in here. If the listing_id query parameter is used, the compliance_type query parameter {if passed in) will be ignored. This is because all of a listing's policy violations {each compliance type) will be returned if a listing_id is provided. Either the listing_id or a compliance_type query parameter must be used, and if the seller only wants to view listing violations of a specific compliance type, both of these parameters can be used. Note: The listing_id query parameter is not yet available for use, so the seller does not have the ability to retrieve listing violations for one or more specific listings. Until the listing_id query parameter becomes available, the compliance_type query parameter is required with each getListingViolations call.
  --offset: string # The integer value input into this field controls the first listing violation in the result set that will be displayed at the top of the response. The offset and limit query parameters are used to control the pagination of the output. For example, if offset is set to 10 and limit is set to 10, the call retrieves listing violations 11 thru 20 from the resulting set of violations. Note: This feature employs a zero-based index, where the first item in the list has an offset of 0. If the listing_id parameter is included in the request, this parameter will be ignored. Default: 0 {zero)
  --listing-id: string # Note: This query parameter is not yet supported for the Compliance API. Please note that until this query parameter becomes available, the compliance_type query parameter is required with each getListingViolations call. This query parameter is used if the user wants to view all listing violations for one or more eBay listings. The string value passed into this field is the unique identifier of the listing, sometimes referred to as the Item ID. Either the listing_id or a compliance_type query parameter must be used, and if the seller only wants to view listing violations of a specific compliance type, both of these parameters can be used. Up to 50 listing IDs can be specified with this query parameter, and each unique listing ID is separated with a comma.
  --limit: string # This query parameter is used if the user wants to set a limit on the number of listing violations that are returned on one page of the result set. This parameter is used in conjunction with the offset parameter to control the pagination of the output. For example, if offset is set to 10 and limit is set to 10, the call retrieves listing violations 11 thru 20 from the collection of listing violations that match the value set in the compliance_type parameter. Note: This feature employs a zero-based index, where the first item in the list has an offset of 0. If the listing_id parameter is included in the request, this parameter will be ignored. Default: 100 Maximum: 200
  --filter: string # This filter allows a user to retrieve only listings that are currently out of compliance, or only listings that are at risk of becoming out of compliance. Although other filters may be added in the future, complianceState is the only supported filter type at this time. The two compliance 'states' are OUT_OF_COMPLIANCE and AT_RISK. Below is an example of how to set up this compliance state filter. Notice that the filter type and filter value are separated with a colon (:) character, and the filter value is wrapped with curly brackets. filter=complianceState:{OUT_OF_COMPLIANCE}
  --x-ebay-c-marketplace-id: string # This header is required and is used to specify the eBay marketplace identifier. Supported values for this header can be found in the MarketplaceIdEnum type definition. Note that Version 1.4.0 of the Compliance API is only supported on the US, UK, Australia, Canada {English), and Germany sites.
]: nothing -> record<href: string, limit: int, listingViolations: table<complianceType: string, listingId: string, offerId: string, sku: string, violations: list>, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "compliance_type" $compliance_type "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "listing_id" $listing_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listing_violation" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"compliance_type": $compliance_type, "offset": $offset, "listing_id": $listing_id, "limit": $limit, "filter": $filter} | compact), body: null}
}

# This call returns listing violation counts for a seller. A user can pass in one or more compliance types through the compliance_type query parameter. See ComplianceTypeEnum for more information on the supported listing compliance types. Listing violations are returned for multiple marketplaces if the seller sells on multiple eBay marketplaces. Note: Only a canned response, with counts for all listing compliance types, is returned in the Sandbox environment. Due to this limitation, the compliance_type query parameter (if used) will not have an effect on the response.
#
# GET /listing_violation_summary
# operationId: getListingViolationsSummary
export def "listing-violation-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compliance-type: string # A user passes in one or more compliance type values through this query parameter. See ComplianceTypeEnum for more information on the supported compliance types that can be passed in here. If more than one compliance type value is used, delimit these values with a comma. If no compliance type values are passed in, the listing count for all compliance types will be returned. Note: Only a canned response, with counts for all listing compliance types, is returned in the Sandbox environment. Due to this limitation, the compliance_type query parameter (if used) will not have an effect on the response.
  --x-ebay-c-marketplace-id: string # Use this header to specify the eBay marketplace identifier. Supported values for this header can be found in the MarketplaceIdEnum type definition. Note that Version 1.4.0 of the Compliance API is only supported on the US, UK, Australia, Canada {English), and Germany sites.
]: nothing -> record<violationSummaries: table<complianceType: string, listingCount: int, marketplaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "compliance_type" $compliance_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/listing_violation_summary" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"compliance_type": $compliance_type} | compact), body: null}
}

# This call suppresses a listing violation for a specific listing. Only listing violations in the AT_RISK state (returned in the violations.complianceState field of the getListingViolations call) can be suppressed. Note: At this time, the suppressViolation call only supports the suppressing of ASPECTS_ADOPTION listing violations in the AT_RISK state. In the future, it is possible that this method can be used to suppress other listing violation types. A successful call returns a http status code of 204 Success. There is no response payload. If the call is not successful, an error code will be returned stating the issue.
#
# POST /suppress_listing_violation
# operationId: suppressViolation
export def "suppress-listing-violation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compliance-type: string # The compliance type of the listing violation to suppress is specified in this field. The compliance type for each listing violation is found in the complianceType field under the listingViolations array in a getListingViolations response. Note: At this time, the suppressViolation method is only used to suppress aspect adoption listing violations in the 'at-risk' state, so ASPECTS_ADOPTION is currently the only supported value for this field. For implementation help, refer to eBay API documentation
  --listing-id: string # The unique identifier of the listing with the violation(s) is specified in this field. The unique identifier of the listing with the listing violation(s) is found in the listingId field under the listingViolations array in a getListingViolations response. Note: At this time, the suppressViolation method is only used to suppress aspect adoption listing violations in the 'at-risk' state, so the listing specified in this field should be a listing with an ASPECTS_ADOPTION violation in the 'at-risk' state.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppress_listing_violation")
  let req_body = {"complianceType": $compliance_type, "listingId": $listing_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
