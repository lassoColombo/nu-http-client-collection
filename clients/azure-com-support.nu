# Auto-generated client for Microsoft.Support v2019-05-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/support/2019-05-01-preview/swagger.json
# Auth: --token flag or $env.MICROSOFT_SUPPORT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MICROSOFT_SUPPORT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["Microsoft.Support/communications" "Microsoft.Support/supportTickets"] }
def severity-completer [] { ["critical" "minimal" "moderate"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-support-operations list" } } | get name | first)
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

# This lists all the available Microsoft Support REST API operations.
#
# GET /providers/Microsoft.Support/operations
# operationId: Operations_List
export def "providers-microsoft-support-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Support/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists all the Azure services available for support ticket creation. Here are the Service Ids for **Billing**, **Subscription Management**, and **Service and subscription limits (Quotas)** issues: Issue typeService IdBilling'/providers/Microsoft.Support/services/517f2da6-78fd-0498-4e22-ad26996b1dfc'Subscription Management'/providers/Microsoft.Support/services/f3dc5421-79ef-1efa-41a5-42bf3cbb52c6'Quota'/providers/Microsoft.Support/services/06bfd9d3-516b-d5c6-5802-169c800dec89' For **Technical** issues, select the Service Id that maps to the Azure service/product as displayed in the **Services** drop-down list on the Azure portal's New support request page. Always use the service and it's corresponding problem classification(s) obtained programmatically for support ticket creation. This practice ensures that you always have the most recent set of service and problem classification Ids.
#
# GET /providers/Microsoft.Support/services
# operationId: Services_List
export def "providers-microsoft-support-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Support/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a specific Azure service for support ticket creation.
#
# GET /providers/Microsoft.Support/services/{serviceName}
# operationId: Services_Get
export def "providers-microsoft-support-services get" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<id: string, name: string, properties: record<displayName: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.Support/services/{service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists all the problem classifications (categories) available for a specific Azure service. Always use the service and problem classifications obtained programmatically. This practice ensures that you always have the most recent set of service and problem classification Ids.
#
# GET /providers/Microsoft.Support/services/{serviceName}/problemClassifications
# operationId: ProblemClassifications_List
export def "providers-microsoft-support-services-problem-classifications list" [
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name)} | format pattern "/providers/Microsoft.Support/services/{service_name}/problemClassifications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the details of a specific problem classification for a specific Azure service.
#
# GET /providers/Microsoft.Support/services/{serviceName}/problemClassifications/{problemClassificationName}
# operationId: ProblemClassifications_Get
export def "providers-microsoft-support-services-problem-classifications get" [
  service_name: string
  problem_classification_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<id: string, name: string, properties: record<displayName: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  if ($problem_classification_name | is-empty) { error make --unspanned { msg: "path parameter 'problemClassificationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: (encode-path-segment $service_name), problem_classification_name: (encode-path-segment $problem_classification_name)} | format pattern "/providers/Microsoft.Support/services/{service_name}/problemClassifications/{problem_classification_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Check the availability of a resource name. This API should to be used to check the uniqueness of the name for support ticket creation for the selected subscription.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Support/checkNameAvailability
# operationId: SupportTickets_CheckNameAvailability
export def "subscriptions-providers-microsoft-support-check-name-availability check-tickets" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  name: string # The resource name to validate
  type: string@type-completer # The type of resource
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/checkNameAvailability") $qp)
  let req_body = {"name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all the support tickets for an Azure subscription. You can also filter the support tickets by Status or CreatedDate using the $filter parameter. Output will be a paged result with nextLink, using which you can retrieve the next set of support tickets. Support ticket data is available for 12 months after ticket creation. If a ticket was created more than 12 months ago, a request for data might cause an error.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets
# operationId: SupportTickets_List
export def "subscriptions-providers-microsoft-support-support-tickets list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of values to return in the collection. Default is 25 and max is 100.
  --filter: string # The filter to apply on the operation. We support 'odata v4.0' filter semantics. Learn more Status filter can only be used with 'eq' operator. For CreatedDate filter, the supported operators are 'gt' and 'ge'. When using both filters, combine them using the logical 'AND'.
  --api-version: string # Api version
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top, "$filter": $filter, "api-version": $api_version} | compact), body: null}
}

# Gets details for a specific support ticket in an Azure subscription. Support ticket data is available for 12 months after ticket creation. If a ticket was created more than 12 months ago, a request for data might cause an error.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}
# operationId: SupportTickets_Get
export def "subscriptions-providers-microsoft-support-support-tickets get" [
  subscription_id: string
  support_ticket_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<id: string, name: string, properties: record<contactDetails: record<additionalEmailAddresses: list, country: string, firstName: string, lastName: string, phoneNumber: string, preferredContactMethod: string, preferredSupportLanguage: string, preferredTimeZone: string, primaryEmailAddress: string>, createdDate: string, description: string, enrollmentId: string, modifiedDate: string, problemClassificationDisplayName: string, problemClassificationId: string, problemStartTime: string, productionOutage: bool, quotaTicketDetails: record<quotaChangeRequestSubType: string, quotaChangeRequestVersion: string, quotaChangeRequests: list>, require24X7Response: bool, serviceDisplayName: string, serviceId: string, serviceLevelAgreement: record<expirationTime: string, slaMinutes: int, startTime: string>, severity: string, status: string, supportEngineer: record<emailAddress: string>, supportPlanType: string, supportTicketId: string, technicalTicketDetails: record<resourceId: string>, title: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($support_ticket_name | is-empty) { error make --unspanned { msg: "path parameter 'supportTicketName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), support_ticket_name: (encode-path-segment $support_ticket_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# This API allows you to update the severity level or your contact information in the support ticket. Note: The severity levels cannot be changed if a support ticket is actively being worked upon by an Azure support engineer. In such a case, contact your support engineer to request severity update by adding a new communication using the Communications API.
#
# PATCH /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}
# operationId: SupportTickets_Update
# --contactDetails shape: {additionalEmailAddresses?: list<string>, country?: string, firstName?: string, lastName?: string, phoneNumber?: string, preferredContactMethod?: "email"|"phone", preferredSupportLanguage?: string, preferredTimeZone?: string, primaryEmailAddress?: string}
export def "subscriptions-providers-microsoft-support-support-tickets update" [
  subscription_id: string
  support_ticket_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  --contact-details: record # Contact information associated with the support ticket. — shape: {additionalEmailAddresses?: list<string>, country?: string, firstName?: string, lastName?: string, phoneNumber?: string, preferredContactMethod?: "email"|"phone", preferredSupportLanguage?: string, preferredTimeZone?: string, primaryEmailAddress?: string}
  --severity: string@severity-completer # Severity level
]: any -> record<id: string, name: string, properties: record<contactDetails: record<additionalEmailAddresses: list, country: string, firstName: string, lastName: string, phoneNumber: string, preferredContactMethod: string, preferredSupportLanguage: string, preferredTimeZone: string, primaryEmailAddress: string>, createdDate: string, description: string, enrollmentId: string, modifiedDate: string, problemClassificationDisplayName: string, problemClassificationId: string, problemStartTime: string, productionOutage: bool, quotaTicketDetails: record<quotaChangeRequestSubType: string, quotaChangeRequestVersion: string, quotaChangeRequests: list>, require24X7Response: bool, serviceDisplayName: string, serviceId: string, serviceLevelAgreement: record<expirationTime: string, slaMinutes: int, startTime: string>, severity: string, status: string, supportEngineer: record<emailAddress: string>, supportPlanType: string, supportTicketId: string, technicalTicketDetails: record<resourceId: string>, title: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($support_ticket_name | is-empty) { error make --unspanned { msg: "path parameter 'supportTicketName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), support_ticket_name: (encode-path-segment $support_ticket_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}") $qp)
  let req_body = {"contactDetails": $contact_details, "severity": $severity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a new support ticket for Quota increase, Technical, Billing, and Subscription Management issues for the specified subscription. A paid technical support plan is required to create a support ticket using this API. Learn more Use the Services API to map the right Service Id to the issue type. For example: For billing tickets set *serviceId* to *'/providers/Microsoft.Support/services/517f2da6-78fd-0498-4e22-ad26996b1dfc'*. For Technical issues, the Service id will map to the Azure service you want to raise a support ticket for. Always call the Services and ProblemClassifications API to get the most recent set of services and problem categories required for support ticket creation.
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}
# operationId: SupportTickets_Create
# --properties shape: {contactDetails: record, description: string, problemClassificationId: string, problemStartTime?: string, quotaTicketDetails?: record, require24X7Response?: bool, serviceId: string, serviceLevelAgreement?: record, severity: "minimal"|"moderate"|"critical", supportEngineer?: record, supportTicketId?: string, technicalTicketDetails?: record, title: string}
export def "subscriptions-providers-microsoft-support-support-tickets create" [
  subscription_id: string
  support_ticket_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  --properties: record # Describes the properties of a support ticket. — shape: {contactDetails: record, description: string, problemClassificationId: string, problemStartTime?: string, quotaTicketDetails?: record, require24X7Response?: bool, serviceId: string, serviceLevelAgreement?: record, severity: "minimal"|"moderate"|"critical", supportEngineer?: record, supportTicketId?: string, technicalTicketDetails?: record, title: string}
]: any -> record<id: string, name: string, properties: record<contactDetails: record<additionalEmailAddresses: list, country: string, firstName: string, lastName: string, phoneNumber: string, preferredContactMethod: string, preferredSupportLanguage: string, preferredTimeZone: string, primaryEmailAddress: string>, createdDate: string, description: string, enrollmentId: string, modifiedDate: string, problemClassificationDisplayName: string, problemClassificationId: string, problemStartTime: string, productionOutage: bool, quotaTicketDetails: record<quotaChangeRequestSubType: string, quotaChangeRequestVersion: string, quotaChangeRequests: list>, require24X7Response: bool, serviceDisplayName: string, serviceId: string, serviceLevelAgreement: record<expirationTime: string, slaMinutes: int, startTime: string>, severity: string, status: string, supportEngineer: record<emailAddress: string>, supportPlanType: string, supportTicketId: string, technicalTicketDetails: record<resourceId: string>, title: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($support_ticket_name | is-empty) { error make --unspanned { msg: "path parameter 'supportTicketName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), support_ticket_name: (encode-path-segment $support_ticket_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Check the availability of a resource name. This API should to be used to check the uniqueness of the name for adding a new communication to the support ticket.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}/checkNameAvailability
# operationId: Communications_CheckNameAvailability
export def "subscriptions-providers-microsoft-support-support-tickets-check-name-availability check-communications" [
  subscription_id: string
  support_ticket_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  name: string # The resource name to validate
  type: string@type-completer # The type of resource
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($support_ticket_name | is-empty) { error make --unspanned { msg: "path parameter 'supportTicketName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), support_ticket_name: (encode-path-segment $support_ticket_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}/checkNameAvailability") $qp)
  let req_body = {"name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all communications (attachments not included) for a support ticket. You can also filter support ticket communications by CreatedDate�or CommunicationType using the $filter parameter. The only type of communication supported today is Web. Output will be a paged result with nextLink, using which you can retrieve the next set of Communication results. Support ticket data is available for 12 months after ticket creation. If a ticket was created more than 12 months ago, a request for data might cause an error.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}/communications
# operationId: Communications_List
export def "subscriptions-providers-microsoft-support-support-tickets-communications list" [
  subscription_id: string
  support_ticket_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of values to return in the collection. Default is 10 and max is 10.
  --filter: string # The filter to apply on the operation. You can filter by communicationType and createdDate properties. CommunicationType supports Equals ('eq') operator and createdDate supports Greater Than ('gt') and Greater Than or Equals ('ge') operators. You may combine the CommunicationType and CreatedDate filters by Logical And ('and') operator.
  --api-version: string # Api version
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($support_ticket_name | is-empty) { error make --unspanned { msg: "path parameter 'supportTicketName' must be non-empty" } }
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), support_ticket_name: (encode-path-segment $support_ticket_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}/communications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$top": $top, "$filter": $filter, "api-version": $api_version} | compact), body: null}
}

# Returns details of a specific communication in a support ticket.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}/communications/{communicationName}
# operationId: Communications_Get
export def "subscriptions-providers-microsoft-support-support-tickets-communications get" [
  subscription_id: string
  support_ticket_name: string
  communication_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<id: string, name: string, properties: record<body: string, communicationDirection: string, communicationType: string, createdDate: string, sender: string, subject: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($support_ticket_name | is-empty) { error make --unspanned { msg: "path parameter 'supportTicketName' must be non-empty" } }
  if ($communication_name | is-empty) { error make --unspanned { msg: "path parameter 'communicationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), support_ticket_name: (encode-path-segment $support_ticket_name), communication_name: (encode-path-segment $communication_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}/communications/{communication_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Adds a new customer communication to an Azure support ticket. Adding attachments are not currently supported via the API. To add a file to a support ticket, visit the Manage support ticket page in the Azure portal, select the support ticket, and use the file upload control to add a new file.
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}/communications/{communicationName}
# operationId: Communications_Create
# --properties shape: {body: string, sender?: string, subject: string}
export def "subscriptions-providers-microsoft-support-support-tickets-communications create" [
  subscription_id: string
  support_ticket_name: string
  communication_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  --properties: record # Describes the properties of a communication resource. — shape: {body: string, sender?: string, subject: string}
]: any -> record<id: string, name: string, properties: record<body: string, communicationDirection: string, communicationType: string, createdDate: string, sender: string, subject: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($support_ticket_name | is-empty) { error make --unspanned { msg: "path parameter 'supportTicketName' must be non-empty" } }
  if ($communication_name | is-empty) { error make --unspanned { msg: "path parameter 'communicationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), support_ticket_name: (encode-path-segment $support_ticket_name), communication_name: (encode-path-segment $communication_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}/communications/{communication_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}
