# Auto-generated client for Microsoft.Support v2019-05-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/support/2019-05-01-preview/swagger.json
# Auth: --token flag or $env.MICROSOFT_SUPPORT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MICROSOFT_SUPPORT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["Microsoft.Support/communications" "Microsoft.Support/supportTickets"] }
def severity-completer [] { ["critical" "minimal" "moderate"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Support/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the Azure services available for support ticket creation. Here are the Service Ids for **Billing**, **Subscription Management**, and **Service and subscription limits (Quotas)** issues: <br/><table><tr><td><u>Issue type</u></td><td><u>Service Id</u></td></tr><tr><td>Billing</td><td>'/providers/Microsoft.Support/services/517f2da6-78fd-0498-4e22-ad26996b1dfc'</td></tr><tr><td>Subscription Management</td><td>'/providers/Microsoft.Support/services/f3dc5421-79ef-1efa-41a5-42bf3cbb52c6'</td></tr><tr><td>Quota</td><td>'/providers/Microsoft.Support/services/06bfd9d3-516b-d5c6-5802-169c800dec89'</td></tr></table> <br/><br/> For **Technical** issues, select the Service Id that maps to the Azure service/product as displayed in the **Services** drop-down list on the Azure portal's <a target='_blank' href='https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade/overview'>New support request</a> page. <br/><br/> Always use the service and it's corresponding problem classification(s) obtained programmatically for support ticket creation. This practice ensures that you always have the most recent set of service and problem classification Ids.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Support/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<id: string, name: string, properties: record<displayName: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: $service_name} | format pattern "/providers/Microsoft.Support/services/{service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the problem classifications (categories) available for a specific Azure service.<br/><br/> Always use the service and problem classifications obtained programmatically. This practice ensures that you always have the most recent set of service and problem classification Ids.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: $service_name} | format pattern "/providers/Microsoft.Support/services/{service_name}/problemClassifications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<id: string, name: string, properties: record<displayName: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_name: $service_name, problem_classification_name: $problem_classification_name} | format pattern "/providers/Microsoft.Support/services/{service_name}/problemClassifications/{problem_classification_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check the availability of a resource name. This API should to be used to check the uniqueness of the name for support ticket creation for the selected subscription.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Support/checkNameAvailability
# operationId: SupportTickets_CheckNameAvailability
export def "subscriptions-providers-microsoft-support-check-name-availability check" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  name: string # The resource name to validate
  type: string@type-completer # The type of resource
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/checkNameAvailability") $qp)
  let body = {"name": $name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all the support tickets for an Azure subscription. <br/><br/>You can also filter the support tickets by <i>Status</i> or <i>CreatedDate</i> using the $filter parameter. Output will be a paged result with <i>nextLink</i>, using which you can retrieve the next set of support tickets. <br/><br/>Support ticket data is available for 12 months after ticket creation. If a ticket was created more than 12 months ago, a request for data might cause an error.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of values to return in the collection. Default is 25 and max is 100.
  --filter: string # The filter to apply on the operation. We support 'odata v4.0' filter semantics. <a target='_blank' href='https://docs.microsoft.com/odata/concepts/queryoptions-overview'>Learn more</a> <br/><i>Status</i> filter can only be used with 'eq' operator. For <i>CreatedDate</i> filter, the supported operators are 'gt' and 'ge'. When using both filters, combine them using the logical 'AND'.
  --api-version: string # Api version
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets details for a specific support ticket in an Azure subscription. <br/><br/>Support ticket data is available for 12 months after ticket creation. If a ticket was created more than 12 months ago, a request for data might cause an error.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<id: string, name: string, properties: record<contactDetails: record<additionalEmailAddresses: list, country: string, firstName: string, lastName: string, phoneNumber: string, preferredContactMethod: string, preferredSupportLanguage: string, preferredTimeZone: string, primaryEmailAddress: string>, createdDate: string, description: string, enrollmentId: string, modifiedDate: string, problemClassificationDisplayName: string, problemClassificationId: string, problemStartTime: string, productionOutage: bool, quotaTicketDetails: record<quotaChangeRequestSubType: string, quotaChangeRequestVersion: string, quotaChangeRequests: list>, require24X7Response: bool, serviceDisplayName: string, serviceId: string, serviceLevelAgreement: record<expirationTime: string, slaMinutes: int, startTime: string>, severity: string, status: string, supportEngineer: record<emailAddress: string>, supportPlanType: string, supportTicketId: string, technicalTicketDetails: record<resourceId: string>, title: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, support_ticket_name: $support_ticket_name} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This API allows you to update the severity level or your contact information in the support ticket. <br/><br/> Note: The severity levels cannot be changed if a support ticket is actively being worked upon by an Azure support engineer. In such a case, contact your support engineer to request severity update by adding a new communication using the Communications API.
#
# PATCH /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}
# operationId: SupportTickets_Update
# --contactDetails shape: {additionalEmailAddresses?: list, country?: string, firstName?: string, lastName?: string, phoneNumber?: string, preferredContactMethod?: "email"|"phone", preferredSupportLanguage?: string, preferredTimeZone?: string, primaryEmailAddress?: string}
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  --contact-details: record # Contact information associated with the support ticket. — shape: {additionalEmailAddresses?: list, country?: string, firstName?: string, lastName?: string, phoneNumber?: string, preferredContactMethod?: "email"|"phone", preferredSupportLanguage?: string, preferredTimeZone?: string, primaryEmailAddress?: string}
  --severity: string@severity-completer # Severity level
]: any -> record<id: string, name: string, properties: record<contactDetails: record<additionalEmailAddresses: list, country: string, firstName: string, lastName: string, phoneNumber: string, preferredContactMethod: string, preferredSupportLanguage: string, preferredTimeZone: string, primaryEmailAddress: string>, createdDate: string, description: string, enrollmentId: string, modifiedDate: string, problemClassificationDisplayName: string, problemClassificationId: string, problemStartTime: string, productionOutage: bool, quotaTicketDetails: record<quotaChangeRequestSubType: string, quotaChangeRequestVersion: string, quotaChangeRequests: list>, require24X7Response: bool, serviceDisplayName: string, serviceId: string, serviceLevelAgreement: record<expirationTime: string, slaMinutes: int, startTime: string>, severity: string, status: string, supportEngineer: record<emailAddress: string>, supportPlanType: string, supportTicketId: string, technicalTicketDetails: record<resourceId: string>, title: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, support_ticket_name: $support_ticket_name} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}") $qp)
  let body = {"contactDetails": $contact_details, "severity": $severity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new support ticket for Quota increase, Technical, Billing, and Subscription Management issues for the specified subscription. <br/><br/>A paid technical support plan is required to create a support ticket using this API. <a href='https://aka.ms/supportticketAPI'>Learn more</a> <br/><br/> Use the Services API to map the right Service Id to the issue type. For example: For billing tickets set *serviceId* to *'/providers/Microsoft.Support/services/517f2da6-78fd-0498-4e22-ad26996b1dfc'*. <br/> For Technical issues, the Service id will map to the Azure service you want to raise a support ticket for. <br/><br/>Always call the Services and ProblemClassifications API to get the most recent set of services and problem categories required for support ticket creation.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  --properties: record # Describes the properties of a support ticket. — shape: {contactDetails: record, description: string, problemClassificationId: string, problemStartTime?: string, quotaTicketDetails?: record, require24X7Response?: bool, serviceId: string, serviceLevelAgreement?: record, severity: "minimal"|"moderate"|"critical", supportEngineer?: record, supportTicketId?: string, technicalTicketDetails?: record, title: string}
]: any -> record<id: string, name: string, properties: record<contactDetails: record<additionalEmailAddresses: list, country: string, firstName: string, lastName: string, phoneNumber: string, preferredContactMethod: string, preferredSupportLanguage: string, preferredTimeZone: string, primaryEmailAddress: string>, createdDate: string, description: string, enrollmentId: string, modifiedDate: string, problemClassificationDisplayName: string, problemClassificationId: string, problemStartTime: string, productionOutage: bool, quotaTicketDetails: record<quotaChangeRequestSubType: string, quotaChangeRequestVersion: string, quotaChangeRequests: list>, require24X7Response: bool, serviceDisplayName: string, serviceId: string, serviceLevelAgreement: record<expirationTime: string, slaMinutes: int, startTime: string>, severity: string, status: string, supportEngineer: record<emailAddress: string>, supportPlanType: string, supportTicketId: string, technicalTicketDetails: record<resourceId: string>, title: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, support_ticket_name: $support_ticket_name} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check the availability of a resource name. This API should to be used to check the uniqueness of the name for adding a new communication to the support ticket.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Support/supportTickets/{supportTicketName}/checkNameAvailability
# operationId: Communications_CheckNameAvailability
export def "subscriptions-providers-microsoft-support-support-tickets-check-name-availability check" [
  subscription_id: string
  support_ticket_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  name: string # The resource name to validate
  type: string@type-completer # The type of resource
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, support_ticket_name: $support_ticket_name} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}/checkNameAvailability") $qp)
  let body = {"name": $name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all communications (attachments not included) for a support ticket. <br/></br> You can also filter support ticket communications by <i>CreatedDate</i>�or <i>CommunicationType</i> using the $filter parameter. The only type of communication supported today is <i>Web</i>. Output will be a paged result with <i>nextLink</i>, using which you can retrieve the next set of Communication results. <br/><br/> Support ticket data is available for 12 months after ticket creation. If a ticket was created more than 12 months ago, a request for data might cause an error.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # The number of values to return in the collection. Default is 10 and max is 10.
  --filter: string # The filter to apply on the operation. You can filter by communicationType and createdDate properties. CommunicationType supports Equals ('eq') operator and createdDate supports Greater Than ('gt') and Greater Than or Equals ('ge') operators. You may combine the CommunicationType and CreatedDate filters by Logical And ('and') operator.
  --api-version: string # Api version
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, support_ticket_name: $support_ticket_name} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}/communications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
]: nothing -> record<id: string, name: string, properties: record<body: string, communicationDirection: string, communicationType: string, createdDate: string, sender: string, subject: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, support_ticket_name: $support_ticket_name, communication_name: $communication_name} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}/communications/{communication_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new customer communication to an Azure support ticket. Adding attachments are not currently supported via the API. <br/>To add a file to a support ticket, visit the <a target='_blank' href='https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade/managesupportrequest'>Manage support ticket</a> page in the Azure portal, select the support ticket, and use the file upload control to add a new file.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Api version
  --properties: record # Describes the properties of a communication resource. — shape: {body: string, sender?: string, subject: string}
]: any -> record<id: string, name: string, properties: record<body: string, communicationDirection: string, communicationType: string, createdDate: string, sender: string, subject: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, support_ticket_name: $support_ticket_name, communication_name: $communication_name} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Support/supportTickets/{support_ticket_name}/communications/{communication_name}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
