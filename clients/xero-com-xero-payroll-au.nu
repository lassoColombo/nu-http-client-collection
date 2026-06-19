# Auto-generated client for Xero Payroll AU API v2.9.4
# Source: https://api.apis.guru/v2/specs/xero.com/xero-payroll-au/2.9.4/openapi.json
# Auth: --token flag or $env.XERO_PAYROLL_AU_API_TOKEN

const BASE_URL = "https://api.xero.com/payroll.xro/1.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o XERO_PAYROLL_AU_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.xero.com/payroll.xro/1.0"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "employees list" } } | get name | first)
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

# Searches payroll employees
#
# GET /Employees
# operationId: getEmployees
export def "employees list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. EmailAddress%20DESC)
  --page: int # e.g. page=1 – Up to 100 employees will be returned in a single API call
  --xero-tenant-id: string # Xero identifier for Tenant
  --if-modified-since: string # Only records created or modified since this timestamp will be returned
]: nothing -> record<Employees: table<BankAccounts: list, Classification: string, DateOfBirth: string, Email: string, EmployeeGroupName: string, EmployeeID: string, FirstName: string, Gender: string, HomeAddress: record, IsAuthorisedToApproveLeave: bool, IsAuthorisedToApproveTimesheets: bool, JobTitle: string, LastName: string, LeaveBalances: list, LeaveLines: list, MiddleNames: string, Mobile: string, OpeningBalances: record, OrdinaryEarningsRateID: string, PayTemplate: record, PayrollCalendarID: string, Phone: string, StartDate: string, Status: string, SuperMemberships: list, TaxDeclaration: record, TerminationDate: string, Title: string, TwitterUserName: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Employees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id, "If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"where": $qp_where, "order": $order, "page": $page} | compact), body: null}
}

# Creates a payroll employee
#
# POST /Employees
# operationId: createEmployee
export def "employees create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<Employees: table<BankAccounts: list, Classification: string, DateOfBirth: string, Email: string, EmployeeGroupName: string, EmployeeID: string, FirstName: string, Gender: string, HomeAddress: record, IsAuthorisedToApproveLeave: bool, IsAuthorisedToApproveTimesheets: bool, JobTitle: string, LastName: string, LeaveBalances: list, LeaveLines: list, MiddleNames: string, Mobile: string, OpeningBalances: record, OrdinaryEarningsRateID: string, PayTemplate: record, PayrollCalendarID: string, Phone: string, StartDate: string, Status: string, SuperMemberships: list, TaxDeclaration: record, TerminationDate: string, Title: string, TwitterUserName: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employees")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves an employee's detail by unique employee id
#
# GET /Employees/{EmployeeID}
# operationId: getEmployee
export def "employees get" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<Employees: table<BankAccounts: list, Classification: string, DateOfBirth: string, Email: string, EmployeeGroupName: string, EmployeeID: string, FirstName: string, Gender: string, HomeAddress: record, IsAuthorisedToApproveLeave: bool, IsAuthorisedToApproveTimesheets: bool, JobTitle: string, LastName: string, LeaveBalances: list, LeaveLines: list, MiddleNames: string, Mobile: string, OpeningBalances: record, OrdinaryEarningsRateID: string, PayTemplate: record, PayrollCalendarID: string, Phone: string, StartDate: string, Status: string, SuperMemberships: list, TaxDeclaration: record, TerminationDate: string, Title: string, TwitterUserName: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeID' must be non-empty" } }
  let full_url = (build-url $base ({employee_id: (encode-path-segment $employee_id)} | format pattern "/Employees/{employee_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an employee's detail
#
# POST /Employees/{EmployeeID}
# operationId: updateEmployee
export def "employees update" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<Employees: table<BankAccounts: list, Classification: string, DateOfBirth: string, Email: string, EmployeeGroupName: string, EmployeeID: string, FirstName: string, Gender: string, HomeAddress: record, IsAuthorisedToApproveLeave: bool, IsAuthorisedToApproveTimesheets: bool, JobTitle: string, LastName: string, LeaveBalances: list, LeaveLines: list, MiddleNames: string, Mobile: string, OpeningBalances: record, OrdinaryEarningsRateID: string, PayTemplate: record, PayrollCalendarID: string, Phone: string, StartDate: string, Status: string, SuperMemberships: list, TaxDeclaration: record, TerminationDate: string, Title: string, TwitterUserName: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'EmployeeID' must be non-empty" } }
  let full_url = (build-url $base ({employee_id: (encode-path-segment $employee_id)} | format pattern "/Employees/{employee_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves leave applications
#
# GET /LeaveApplications
# operationId: getLeaveApplications
export def "leave-applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. EmailAddress%20DESC)
  --page: int # e.g. page=1 – Up to 100 objects will be returned in a single API call
  --xero-tenant-id: string # Xero identifier for Tenant
  --if-modified-since: string # Only records created or modified since this timestamp will be returned
]: nothing -> record<LeaveApplications: table<Description: string, EmployeeID: string, EndDate: string, LeaveApplicationID: string, LeavePeriods: list, LeaveTypeID: string, StartDate: string, Title: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/LeaveApplications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id, "If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"where": $qp_where, "order": $order, "page": $page} | compact), body: null}
}

# Creates a leave application
#
# POST /LeaveApplications
# operationId: createLeaveApplication
export def "leave-applications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<LeaveApplications: table<Description: string, EmployeeID: string, EndDate: string, LeaveApplicationID: string, LeavePeriods: list, LeaveTypeID: string, StartDate: string, Title: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/LeaveApplications")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves a leave application by a unique leave application id
#
# GET /LeaveApplications/{LeaveApplicationID}
# operationId: getLeaveApplication
export def "leave-applications get" [
  leave_application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<LeaveApplications: table<Description: string, EmployeeID: string, EndDate: string, LeaveApplicationID: string, LeavePeriods: list, LeaveTypeID: string, StartDate: string, Title: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($leave_application_id | is-empty) { error make --unspanned { msg: "path parameter 'LeaveApplicationID' must be non-empty" } }
  let full_url = (build-url $base ({leave_application_id: (encode-path-segment $leave_application_id)} | format pattern "/LeaveApplications/{leave_application_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a specific leave application
#
# POST /LeaveApplications/{LeaveApplicationID}
# operationId: updateLeaveApplication
export def "leave-applications update" [
  leave_application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<LeaveApplications: table<Description: string, EmployeeID: string, EndDate: string, LeaveApplicationID: string, LeavePeriods: list, LeaveTypeID: string, StartDate: string, Title: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($leave_application_id | is-empty) { error make --unspanned { msg: "path parameter 'LeaveApplicationID' must be non-empty" } }
  let full_url = (build-url $base ({leave_application_id: (encode-path-segment $leave_application_id)} | format pattern "/LeaveApplications/{leave_application_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves pay items
#
# GET /PayItems
# operationId: getPayItems
export def "pay-items get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. EmailAddress%20DESC)
  --page: int # e.g. page=1 – Up to 100 objects will be returned in a single API call
  --xero-tenant-id: string # Xero identifier for Tenant
  --if-modified-since: string # Only records created or modified since this timestamp will be returned
]: nothing -> record<PayItems: record<DeductionTypes: list<record>, EarningsRates: list<record>, LeaveTypes: list<record>, ReimbursementTypes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PayItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id, "If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"where": $qp_where, "order": $order, "page": $page} | compact), body: null}
}

# Creates a pay item
#
# POST /PayItems
# operationId: createPayItem
# --DeductionTypes item shape: {AccountCode?: string, CurrentRecord?: bool, DeductionCategory?: "NONE"|"UNIONFEES"|"WORKPLACEGIVING", DeductionTypeID?: string, IsExemptFromW1?: bool, Name?: string, ReducesSuper?: bool, ReducesTax?: bool}
# --EarningsRates item shape: {AccountCode?: string, AccrueLeave?: bool, AllowanceType?: "CAR"|"TRANSPORT"|"TRAVEL"|"LAUNDRY"|"MEALS"|"JOBKEEPER"|"OTHER", Amount?: float, CurrentRecord?: bool, EarningsRateID?: string, EarningsType?: "FIXED"|"ORDINARYTIMEEARNINGS"|"OVERTIMEEARNINGS"|"ALLOWANCE"|"LUMPSUMD"|"EMPLOYMENTTERMINATIONPAYMENT"|"LUMPSUMA"|"LUMPSUMB"|"BONUSESANDCOMMISSIONS"|"LUMPSUME", EmploymentTerminationPaymentType?: "O"|"R", IsExemptFromSuper?: bool, IsExemptFromTax?: bool, IsReportableAsW1?: bool, ... (5 more fields)}
# --LeaveTypes item shape: {CurrentRecord?: bool, IsPaidLeave?: bool, LeaveLoadingRate?: float, LeaveTypeID?: string, Name?: string, NormalEntitlement?: float, ShowOnPayslip?: bool, TypeOfUnits?: string}
# --ReimbursementTypes item shape: {AccountCode?: string, CurrentRecord?: bool, Name?: string, ReimbursementTypeID?: string}
export def "pay-items create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --deduction-types: list # item shape: {AccountCode?: string, CurrentRecord?: bool, DeductionCategory?: "NONE"|"UNIONFEES"|"WORKPLACEGIVING", DeductionTypeID?: string, IsExemptFromW1?: bool, Name?: string, ReducesSuper?: bool, ReducesTax?: bool}
  --earnings-rates: list # item shape: {AccountCode?: string, AccrueLeave?: bool, AllowanceType?: "CAR"|"TRANSPORT"|"TRAVEL"|"LAUNDRY"|"MEALS"|"JOBKEEPER"|"OTHER", Amount?: float, CurrentRecord?: bool, EarningsRateID?: string, EarningsType?: "FIXED"|"ORDINARYTIMEEARNINGS"|"OVERTIMEEARNINGS"|"ALLOWANCE"|"LUMPSUMD"|"EMPLOYMENTTERMINATIONPAYMENT"|"LUMPSUMA"|"LUMPSUMB"|"BONUSESANDCOMMISSIONS"|"LUMPSUME", EmploymentTerminationPaymentType?: "O"|"R", IsExemptFromSuper?: bool, IsExemptFromTax?: bool, IsReportableAsW1?: bool, ... (5 more fields)}
  --leave-types: list # item shape: {CurrentRecord?: bool, IsPaidLeave?: bool, LeaveLoadingRate?: float, LeaveTypeID?: string, Name?: string, NormalEntitlement?: float, ShowOnPayslip?: bool, TypeOfUnits?: string}
  --reimbursement-types: list # item shape: {AccountCode?: string, CurrentRecord?: bool, Name?: string, ReimbursementTypeID?: string}
]: any -> record<PayItems: record<DeductionTypes: list<record>, EarningsRates: list<record>, LeaveTypes: list<record>, ReimbursementTypes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PayItems")
  let req_body = {"DeductionTypes": $deduction_types, "EarningsRates": $earnings_rates, "LeaveTypes": $leave_types, "ReimbursementTypes": $reimbursement_types} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves pay runs
#
# GET /PayRuns
# operationId: getPayRuns
export def "pay-runs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. EmailAddress%20DESC)
  --page: int # e.g. page=1 – Up to 100 PayRuns will be returned in a single API call
  --xero-tenant-id: string # Xero identifier for Tenant
  --if-modified-since: string # Only records created or modified since this timestamp will be returned
]: nothing -> record<PayRuns: table<Deductions: float, NetPay: float, PayRunID: string, PayRunPeriodEndDate: string, PayRunPeriodStartDate: string, PayRunStatus: string, PaymentDate: string, PayrollCalendarID: string, PayslipMessage: string, Payslips: list, Reimbursement: float, Super: float, Tax: float, UpdatedDateUTC: string, ValidationErrors: list, Wages: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PayRuns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id, "If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"where": $qp_where, "order": $order, "page": $page} | compact), body: null}
}

# Creates a pay run
#
# POST /PayRuns
# operationId: createPayRun
export def "pay-runs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<PayRuns: table<Deductions: float, NetPay: float, PayRunID: string, PayRunPeriodEndDate: string, PayRunPeriodStartDate: string, PayRunStatus: string, PaymentDate: string, PayrollCalendarID: string, PayslipMessage: string, Payslips: list, Reimbursement: float, Super: float, Tax: float, UpdatedDateUTC: string, ValidationErrors: list, Wages: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PayRuns")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves a pay run by using a unique pay run id
#
# GET /PayRuns/{PayRunID}
# operationId: getPayRun
export def "pay-runs get" [
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<PayRuns: table<Deductions: float, NetPay: float, PayRunID: string, PayRunPeriodEndDate: string, PayRunPeriodStartDate: string, PayRunStatus: string, PaymentDate: string, PayrollCalendarID: string, PayslipMessage: string, Payslips: list, Reimbursement: float, Super: float, Tax: float, UpdatedDateUTC: string, ValidationErrors: list, Wages: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunID' must be non-empty" } }
  let full_url = (build-url $base ({pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/PayRuns/{pay_run_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a pay run
#
# POST /PayRuns/{PayRunID}
# operationId: updatePayRun
export def "pay-runs update" [
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<PayRuns: table<Deductions: float, NetPay: float, PayRunID: string, PayRunPeriodEndDate: string, PayRunPeriodStartDate: string, PayRunStatus: string, PaymentDate: string, PayrollCalendarID: string, PayslipMessage: string, Payslips: list, Reimbursement: float, Super: float, Tax: float, UpdatedDateUTC: string, ValidationErrors: list, Wages: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pay_run_id | is-empty) { error make --unspanned { msg: "path parameter 'PayRunID' must be non-empty" } }
  let full_url = (build-url $base ({pay_run_id: (encode-path-segment $pay_run_id)} | format pattern "/PayRuns/{pay_run_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves payroll calendars
#
# GET /PayrollCalendars
# operationId: getPayrollCalendars
export def "payroll-calendars list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. EmailAddress%20DESC)
  --page: int # e.g. page=1 – Up to 100 objects will be returned in a single API call
  --xero-tenant-id: string # Xero identifier for Tenant
  --if-modified-since: string # Only records created or modified since this timestamp will be returned
]: nothing -> record<PayrollCalendars: table<CalendarType: string, Name: string, PaymentDate: string, PayrollCalendarID: string, StartDate: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PayrollCalendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id, "If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"where": $qp_where, "order": $order, "page": $page} | compact), body: null}
}

# Creates a Payroll Calendar
#
# POST /PayrollCalendars
# operationId: createPayrollCalendar
export def "payroll-calendars create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<PayrollCalendars: table<CalendarType: string, Name: string, PaymentDate: string, PayrollCalendarID: string, StartDate: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PayrollCalendars")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves payroll calendar by using a unique payroll calendar ID
#
# GET /PayrollCalendars/{PayrollCalendarID}
# operationId: getPayrollCalendar
export def "payroll-calendars get" [
  payroll_calendar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<PayrollCalendars: table<CalendarType: string, Name: string, PaymentDate: string, PayrollCalendarID: string, StartDate: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payroll_calendar_id | is-empty) { error make --unspanned { msg: "path parameter 'PayrollCalendarID' must be non-empty" } }
  let full_url = (build-url $base ({payroll_calendar_id: (encode-path-segment $payroll_calendar_id)} | format pattern "/PayrollCalendars/{payroll_calendar_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves for a payslip by a unique payslip id
#
# GET /Payslip/{PayslipID}
# operationId: getPayslip
export def "payslip get" [
  payslip_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<Payslip: record<DeductionLines: list<record>, Deductions: float, EarningsLines: list<record>, EmployeeID: string, FirstName: string, LastName: string, LeaveAccrualLines: list<record>, LeaveEarningsLines: list<record>, NetPay: float, PayslipID: string, ReimbursementLines: list<record>, Reimbursements: float, Super: float, SuperannuationLines: list<record>, Tax: float, TaxLines: list<record>, TimesheetEarningsLines: list<record>, UpdatedDateUTC: string, Wages: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payslip_id | is-empty) { error make --unspanned { msg: "path parameter 'PayslipID' must be non-empty" } }
  let full_url = (build-url $base ({payslip_id: (encode-path-segment $payslip_id)} | format pattern "/Payslip/{payslip_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a payslip
#
# POST /Payslip/{PayslipID}
# operationId: updatePayslip
export def "payslip update" [
  payslip_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<Payslips: table<DeductionLines: list, Deductions: float, EarningsLines: list, EmployeeID: string, FirstName: string, LastName: string, LeaveAccrualLines: list, LeaveEarningsLines: list, NetPay: float, PayslipID: string, ReimbursementLines: list, Reimbursements: float, Super: float, SuperannuationLines: list, Tax: float, TaxLines: list, TimesheetEarningsLines: list, UpdatedDateUTC: string, Wages: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payslip_id | is-empty) { error make --unspanned { msg: "path parameter 'PayslipID' must be non-empty" } }
  let full_url = (build-url $base ({payslip_id: (encode-path-segment $payslip_id)} | format pattern "/Payslip/{payslip_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves payroll settings
#
# GET /Settings
# operationId: getSettings
export def "settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<Settings: record<Accounts: list<record>, DaysInPayrollYear: int, TrackingCategories: record<EmployeeGroups: record, TimesheetCategories: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves superfund products
#
# GET /SuperfundProducts
# operationId: getSuperfundProducts
export def "superfund-products get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --abn: string # The ABN of the Regulated SuperFund (e.g. 40022701955)
  --usi: string # The USI of the Regulated SuperFund (e.g. OSF0001AU)
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<SuperFundProducts: table<ABN: string, ProductName: string, SPIN: string, USI: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ABN" $abn "scalar") (serialize-qp "USI" $usi "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/SuperfundProducts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ABN": $abn, "USI": $usi} | compact), body: null}
}

# Retrieves superfunds
#
# GET /Superfunds
# operationId: getSuperfunds
export def "superfunds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. EmailAddress%20DESC)
  --page: int # e.g. page=1 – Up to 100 SuperFunds will be returned in a single API call
  --xero-tenant-id: string # Xero identifier for Tenant
  --if-modified-since: string # Only records created or modified since this timestamp will be returned
]: nothing -> record<SuperFunds: table<ABN: string, AccountName: string, AccountNumber: string, BSB: string, ElectronicServiceAddress: string, EmployerNumber: string, Name: string, SPIN: string, SuperFundID: string, Type: string, USI: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Superfunds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id, "If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"where": $qp_where, "order": $order, "page": $page} | compact), body: null}
}

# Creates a superfund
#
# POST /Superfunds
# operationId: createSuperfund
export def "superfunds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<SuperFunds: table<ABN: string, AccountName: string, AccountNumber: string, BSB: string, ElectronicServiceAddress: string, EmployerNumber: string, Name: string, SPIN: string, SuperFundID: string, Type: string, USI: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Superfunds")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves a superfund by using a unique superfund ID
#
# GET /Superfunds/{SuperFundID}
# operationId: getSuperfund
export def "superfunds get" [
  super_fund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<SuperFunds: table<ABN: string, AccountName: string, AccountNumber: string, BSB: string, ElectronicServiceAddress: string, EmployerNumber: string, Name: string, SPIN: string, SuperFundID: string, Type: string, USI: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($super_fund_id | is-empty) { error make --unspanned { msg: "path parameter 'SuperFundID' must be non-empty" } }
  let full_url = (build-url $base ({super_fund_id: (encode-path-segment $super_fund_id)} | format pattern "/Superfunds/{super_fund_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a superfund
#
# POST /Superfunds/{SuperFundID}
# operationId: updateSuperfund
export def "superfunds update" [
  super_fund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<SuperFunds: table<ABN: string, AccountName: string, AccountNumber: string, BSB: string, ElectronicServiceAddress: string, EmployerNumber: string, Name: string, SPIN: string, SuperFundID: string, Type: string, USI: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($super_fund_id | is-empty) { error make --unspanned { msg: "path parameter 'SuperFundID' must be non-empty" } }
  let full_url = (build-url $base ({super_fund_id: (encode-path-segment $super_fund_id)} | format pattern "/Superfunds/{super_fund_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves timesheets
#
# GET /Timesheets
# operationId: getTimesheets
export def "timesheets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. EmailAddress%20DESC)
  --page: int # e.g. page=1 – Up to 100 timesheets will be returned in a single API call
  --xero-tenant-id: string # Xero identifier for Tenant
  --if-modified-since: string # Only records created or modified since this timestamp will be returned
]: nothing -> record<Timesheets: table<EmployeeID: string, EndDate: string, Hours: float, StartDate: string, Status: string, TimesheetID: string, TimesheetLines: list, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Timesheets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id, "If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"where": $qp_where, "order": $order, "page": $page} | compact), body: null}
}

# Creates a timesheet
#
# POST /Timesheets
# operationId: createTimesheet
export def "timesheets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<Timesheets: table<EmployeeID: string, EndDate: string, Hours: float, StartDate: string, Status: string, TimesheetID: string, TimesheetLines: list, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Timesheets")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves a timesheet by using a unique timesheet id
#
# GET /Timesheets/{TimesheetID}
# operationId: getTimesheet
export def "timesheets get" [
  timesheet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
]: nothing -> record<Timesheet: record<EmployeeID: string, EndDate: string, Hours: float, StartDate: string, Status: string, TimesheetID: string, TimesheetLines: list<record>, UpdatedDateUTC: string, ValidationErrors: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($timesheet_id | is-empty) { error make --unspanned { msg: "path parameter 'TimesheetID' must be non-empty" } }
  let full_url = (build-url $base ({timesheet_id: (encode-path-segment $timesheet_id)} | format pattern "/Timesheets/{timesheet_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a timesheet
#
# POST /Timesheets/{TimesheetID}
# operationId: updateTimesheet
export def "timesheets update" [
  timesheet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant
  --body: list
]: any -> record<Timesheets: table<EmployeeID: string, EndDate: string, Hours: float, StartDate: string, Status: string, TimesheetID: string, TimesheetLines: list, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($timesheet_id | is-empty) { error make --unspanned { msg: "path parameter 'TimesheetID' must be non-empty" } }
  let full_url = (build-url $base ({timesheet_id: (encode-path-segment $timesheet_id)} | format pattern "/Timesheets/{timesheet_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Xero-Tenant-Id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
