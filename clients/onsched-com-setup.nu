# Auto-generated client for OnSched Setup API vv1
# Source: https://api.apis.guru/v2/specs/onsched.com/setup/v1/openapi.json
# Auth: --token flag or $env.ONSCHED_SETUP_API_TOKEN

const BASE_URL = "https://sandbox-api.onsched.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ONSCHED_SETUP_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox-api.onsched.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "setup-appointments list" } } | get name | first)
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

# List Appointments
#
# GET /setup/v1/appointments
export def "setup-appointments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --email: string # Filter appointments by email address
  --lastname: string # Filter appointments by lastname or part of
  --service-id: string # Filter appointments by service
  --calendar-id: string # Filter appointments by calendar
  --resource-id: string # Filter appointments by resource
  --customer-id: string # Filter appointments by customer
  --service-allocation-id: string # Filter appointments by service allocation
  --start-date: string # Format YYYY-MM-DD: Filter appointments by on/after startDate (format: date-time)
  --end-date: string # Format YYYY-MM-DD: Filter appointments on/before endDate (format: date-time)
  --status: string # Filter appointments by status: IN, BK, CN, RE, RS
  --booked-by: string # Filter appointments by user email who booked
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "calendarId" $calendar_id "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "customerId" $customer_id "scalar") (serialize-qp "serviceAllocationId" $service_allocation_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "bookedBy" $booked_by "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/appointments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "email": $email, "lastname": $lastname, "serviceId": $service_id, "calendarId": $calendar_id, "resourceId": $resource_id, "customerId": $customer_id, "serviceAllocationId": $service_allocation_id, "startDate": $start_date, "endDate": $end_date, "status": $status, "bookedBy": $booked_by, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Get Appointment
#
# GET /setup/v1/appointments/{id}
export def "setup-appointments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/appointments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reassign Appointment
#
# PUT /setup/v1/appointments/{id}/reassign/resource/{resourceId}
export def "setup-appointments-reassign-resource update" [
  id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), resource_id: (encode-path-segment $resource_id)} | format pattern "/setup/v1/appointments/{id}/reassign/resource/{resource_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Users
#
# GET /setup/v1/businessusers
export def "setup-businessusers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --email: string # Filter by email address
  --role: string # Filter user role
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: list, resourceId: string, resourceName: string, role: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/businessusers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "email": $email, "role": $role, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Create User
#
# POST /setup/v1/businessusers
export def "setup-businessusers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --resource-id: string # nullable
  --role: string # nullable
  --send-registration-invite: oneof<nothing, bool>
]: any -> record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/businessusers")
  let req_body = {"email": $email, "locationId": $location_id, "name": $name, "resourceId": $resource_id, "role": $role, "sendRegistrationInvite": $send_registration_invite} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List User Permissions
#
# GET /setup/v1/businessusers/permissions
export def "setup-businessusers-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # Filter permissions by role
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<access: string, function: string, object: string, role: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/businessusers/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"role": $role, "offset": $offset, "limit": $limit} | compact), body: null}
}

# List User Companies
#
# GET /setup/v1/businessusers/{email}/companies
export def "setup-businessusers-companies get" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-text: string # All or partial company name
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<id: string, name: string, object: string>, email: string, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($email | is-empty) { error make --unspanned { msg: "path parameter 'email' must be non-empty" } }
  let qp = [(serialize-qp "searchText" $search_text "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({email: (encode-path-segment $email)} | format pattern "/setup/v1/businessusers/{email}/companies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"searchText": $search_text, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Delete User
#
# DELETE /setup/v1/businessusers/{id}
export def "setup-businessusers delete" [
  id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/businessusers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get User
#
# GET /setup/v1/businessusers/{id}
export def "setup-businessusers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/businessusers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update User
#
# PUT /setup/v1/businessusers/{id}
export def "setup-businessusers update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # nullable
  --name: string # nullable
  --resource-id: string # nullable
  --role: string # nullable
  --send-registration-invite: oneof<nothing, bool>
]: any -> record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/businessusers/{id}"))
  let req_body = {"email": $email, "name": $name, "resourceId": $resource_id, "role": $role, "sendRegistrationInvite": $send_registration_invite} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Calendars
#
# GET /setup/v1/calendars
export def "setup-calendars list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --deleted: oneof<nothing, bool> # Filter by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<availability: record, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/calendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "deleted": $deleted, "offset": $offset, "limit": $limit} | compact), body: null}
}

# DEPRECATING: Create
#
# POST /setup/v1/calendars
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
export def "setup-calendars create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --bookings-per-slot: int # format: int32
  --interval: int # format: int32
  --location-id: string # nullable
  --name: string # nullable
  --resource-group-id: string # nullable
  --type: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/calendars")
  let req_body = {"availability": $availability, "bookingsPerSlot": $bookings_per_slot, "interval": $interval, "locationId": $location_id, "name": $name, "resourceGroupId": $resource_group_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Calendar Block
#
# DELETE /setup/v1/calendars/block/{id}
export def "setup-calendars-block delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/block/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Calendar Block
#
# PUT /setup/v1/calendars/block/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-calendars-block update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/block/{id}"))
  let req_body = {"endDate": $end_date, "endTime": $end_time, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Calendar Block
#
# GET /setup/v1/calendars/blocks/{id}
export def "setup-calendars-blocks get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/blocks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Calendar
#
# DELETE /setup/v1/calendars/{id}
export def "setup-calendars delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Calendar
#
# GET /setup/v1/calendars/{id}
export def "setup-calendars get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Calendar
#
# PUT /setup/v1/calendars/{id}
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
export def "setup-calendars update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --bookings-per-slot: int # format: int32
  --interval: int # format: int32
  --location-id: string # nullable
  --name: string # nullable
  --resource-group-id: string # nullable
  --type: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/{id}"))
  let req_body = {"availability": $availability, "bookingsPerSlot": $bookings_per_slot, "interval": $interval, "locationId": $location_id, "name": $name, "resourceGroupId": $resource_group_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Calendar Block
#
# POST /setup/v1/calendars/{id}/block
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-calendars-block create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/{id}/block"))
  let req_body = {"endDate": $end_date, "endTime": $end_time, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Calendar Blocks
#
# GET /setup/v1/calendars/{id}/blocks
export def "setup-calendars-blocks get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/{id}/blocks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "limit": $limit} | compact), body: null}
}

# Recover Calendar
#
# PUT /setup/v1/calendars/{id}/recover
export def "setup-calendars-recover update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/{id}/recover"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Calendar Services
#
# GET /setup/v1/calendars/{id}/services
export def "setup-calendars-services get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/calendars/{id}/services") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "limit": $limit} | compact), body: null}
}

# Get Company
#
# GET /setup/v1/companies
export def "setup-companies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Company
#
# POST /setup/v1/companies
export def "setup-companies create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # nullable
  --address-line2: string # nullable
  --booking-webhook-url: string # nullable
  --city: string # nullable
  --country: string # nullable
  --customer-webhook-url: string # nullable
  --disable-email-and-sms-notifications: oneof<nothing, bool> # nullable
  --email: string # nullable
  --fax: string # nullable
  --name: string # nullable
  --notification-from-email-address: string # nullable
  --notification-from-name: string # nullable
  --phone: string # nullable
  --postal-code: string # nullable
  --registration-email: string # nullable
  --reminder-webhook-url: string # nullable
  --resource-webhook-url: string # nullable
  --state: string # nullable
  --timezone-name: string # nullable
  --webhook-signature-hash: string # nullable
  --website: string # nullable
]: any -> record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies")
  let req_body = {"addressLine1": $address_line1, "addressLine2": $address_line2, "bookingWebhookUrl": $booking_webhook_url, "city": $city, "country": $country, "customerWebhookUrl": $customer_webhook_url, "disableEmailAndSmsNotifications": $disable_email_and_sms_notifications, "email": $email, "fax": $fax, "name": $name, "notificationFromEmailAddress": $notification_from_email_address, "notificationFromName": $notification_from_name, "phone": $phone, "postalCode": $postal_code, "registrationEmail": $registration_email, "reminderWebhookUrl": $reminder_webhook_url, "resourceWebhookUrl": $resource_webhook_url, "state": $state, "timezoneName": $timezone_name, "webhookSignatureHash": $webhook_signature_hash, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Company
#
# PUT /setup/v1/companies
export def "setup-companies update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # nullable
  --address-line2: string # nullable
  --booking-webhook-url: string # nullable
  --city: string # nullable
  --country: string # nullable
  --customer-webhook-url: string # nullable
  --disable-email-and-sms-notifications: oneof<nothing, bool> # nullable
  --email: string # nullable
  --fax: string # nullable
  --name: string # nullable
  --notification-from-email-address: string # nullable
  --notification-from-name: string # nullable
  --phone: string # nullable
  --postal-code: string # nullable
  --registration-email: string # nullable
  --reminder-webhook-url: string # nullable
  --resource-webhook-url: string # nullable
  --state: string # nullable
  --timezone-name: string # nullable
  --webhook-signature-hash: string # nullable
  --website: string # nullable
]: any -> record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies")
  let req_body = {"addressLine1": $address_line1, "addressLine2": $address_line2, "bookingWebhookUrl": $booking_webhook_url, "city": $city, "country": $country, "customerWebhookUrl": $customer_webhook_url, "disableEmailAndSmsNotifications": $disable_email_and_sms_notifications, "email": $email, "fax": $fax, "name": $name, "notificationFromEmailAddress": $notification_from_email_address, "notificationFromName": $notification_from_name, "phone": $phone, "postalCode": $postal_code, "registrationEmail": $registration_email, "reminderWebhookUrl": $reminder_webhook_url, "resourceWebhookUrl": $resource_webhook_url, "state": $state, "timezoneName": $timezone_name, "webhookSignatureHash": $webhook_signature_hash, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Company Domains
#
# GET /setup/v1/companies/domains
export def "setup-companies-domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<domain: string, id: string, object: string>, object: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Company Domain
#
# POST /setup/v1/companies/domains
export def "setup-companies-domains create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # nullable
]: any -> record<domain: string, id: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/domains")
  let req_body = {"domain": $domain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Company Domain
#
# DELETE /setup/v1/companies/domains/{id}
export def "setup-companies-domains delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain: string, id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/companies/domains/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Company Domain
#
# GET /setup/v1/companies/domains/{id}
export def "setup-companies-domains get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain: string, id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/companies/domains/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Company Domain
#
# PUT /setup/v1/companies/domains/{id}
export def "setup-companies-domains update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # nullable
]: any -> record<domain: string, id: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/companies/domains/{id}"))
  let req_body = {"domain": $domain} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Email Templates
#
# GET /setup/v1/companies/email/templates
export def "setup-companies-email-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<customized: bool, description: string, name: string, object: string, scope: string>, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/email/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Master Template Settings
#
# DELETE /setup/v1/companies/email/templates/master
export def "setup-companies-email-templates-master delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/email/templates/master")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Master Template Settings
#
# GET /setup/v1/companies/email/templates/master
export def "setup-companies-email-templates-master get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/email/templates/master")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Master Template Settings
#
# POST /setup/v1/companies/email/templates/master
export def "setup-companies-email-templates-master create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --center-email-content: oneof<nothing, bool> # nullable
  --center-email-content-panel: oneof<nothing, bool> # nullable
  --center-email-footer: oneof<nothing, bool> # nullable
  --content-background-color: string # nullable
  --content-color: string # nullable
  --content-link-color: string # nullable
  --email-background-color: string # nullable
  --email-color: string # nullable
  --email-link-color: string # nullable
  --footer-font-size: string # nullable
  --footer-logo-height: string # nullable
  --footer-logo-padding: string # nullable
  --footer-panel-email-contact: oneof<nothing, bool> # nullable
  --footer-panel-phone-contact: oneof<nothing, bool> # nullable
  --footer-panel-website-contact: oneof<nothing, bool> # nullable
  --header-logo-height: string # nullable
  --header-logo-padding: string # nullable
  --panel-background-color: string # nullable
  --panel-color: string # nullable
  --panel-link-color: string # nullable
  --privacy-policy-link: string # nullable
  --show-content-panel: oneof<nothing, bool> # nullable
  --show-footer-logo: oneof<nothing, bool> # nullable
  --show-footer-panel: oneof<nothing, bool> # nullable
  --show-header-logo: oneof<nothing, bool> # nullable
  --show-header-panel: oneof<nothing, bool> # nullable
]: any -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/email/templates/master")
  let req_body = {"centerEmailContent": $center_email_content, "centerEmailContentPanel": $center_email_content_panel, "centerEmailFooter": $center_email_footer, "contentBackgroundColor": $content_background_color, "contentColor": $content_color, "contentLinkColor": $content_link_color, "emailBackgroundColor": $email_background_color, "emailColor": $email_color, "emailLinkColor": $email_link_color, "footerFontSize": $footer_font_size, "footerLogoHeight": $footer_logo_height, "footerLogoPadding": $footer_logo_padding, "footerPanelEmailContact": $footer_panel_email_contact, "footerPanelPhoneContact": $footer_panel_phone_contact, "footerPanelWebsiteContact": $footer_panel_website_contact, "headerLogoHeight": $header_logo_height, "headerLogoPadding": $header_logo_padding, "panelBackgroundColor": $panel_background_color, "panelColor": $panel_color, "panelLinkColor": $panel_link_color, "privacyPolicyLink": $privacy_policy_link, "showContentPanel": $show_content_panel, "showFooterLogo": $show_footer_logo, "showFooterPanel": $show_footer_panel, "showHeaderLogo": $show_header_logo, "showHeaderPanel": $show_header_panel} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Email Template
#
# GET /setup/v1/companies/email/templates/{templateName}
export def "setup-companies-email-templates get" [
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, contentType: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'templateName' must be non-empty" } }
  let full_url = (build-url $base ({template_name: (encode-path-segment $template_name)} | format pattern "/setup/v1/companies/email/templates/{template_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Regions
#
# GET /setup/v1/companies/regions
export def "setup-companies-regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<id: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/companies/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Region
#
# POST /setup/v1/companies/regions
export def "setup-companies-regions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
]: any -> record<id: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/regions")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Region
#
# DELETE /setup/v1/companies/regions/{id}
export def "setup-companies-regions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/companies/regions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Region
#
# GET /setup/v1/companies/regions/{id}
export def "setup-companies-regions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/companies/regions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Region
#
# PUT /setup/v1/companies/regions/{id}
export def "setup-companies-regions update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
]: any -> record<id: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/companies/regions/{id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Time Zones
#
# GET /setup/v1/companies/timezones/{date}
export def "setup-companies-timezones get" [
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
]: nothing -> record<object: string, regions: list<string>, timezones: table<name: string, region: string, timezoneIanna: string, tzOffset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({date: (encode-path-segment $date)} | format pattern "/setup/v1/companies/timezones/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Customers
#
# GET /setup/v1/customers
export def "setup-customers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --group-id: string # Filter by groupId
  --email: string # Filter by email address.
  --lastname: string # Search by lastname.
  --deleted: oneof<nothing, bool> # Filter by deleted status.
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, birthdate: string, businessName: string, companyName: string, contact: record, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "groupId": $group_id, "email": $email, "lastname": $lastname, "deleted": $deleted, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Get Customer
#
# GET /setup/v1/customers/{id}
export def "setup-customers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/customers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Customer Data
#
# GET /setup/v1/customers/{id}/privacy
export def "setup-customers-privacy get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appointments: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, customer: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/customers/{id}/privacy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Locations
#
# GET /setup/v1/locations
export def "setup-locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Location name(full or partial) to filter on
  --service-id: string # Find locations that offer this service
  --friendly-id: string # friendlyId of location
  --deleted: oneof<nothing, bool> # Filter locations on deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, adminEmail: string, adminName: string, appointmentReminders: record, businessHolidays: list, businessHours: record, companyId: string, companyName: string, defaults: record, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list, settings: record, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record, website: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "friendlyId" $friendly_id "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "serviceId": $service_id, "friendlyId": $friendly_id, "deleted": $deleted, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Location
#
# POST /setup/v1/locations
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --appointmentReminders shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
# --businessHours shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --defaults shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
# --settings shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
export def "setup-locations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --admin-email: string # Field is required. (nullable)
  --admin-name: string # This field is no longer required and has been deprecated. (nullable)
  --appointment-reminders: record # shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
  --business-hours: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --defaults: record # shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
  --email: string # nullable
  --fax: string # nullable
  --friendly-id: string # Use the friendlyId as an alternative to the assigned locationId Choose something easy and meaningful. Must be unique within your company. FriendlyId's are limited to maximum of 64 characters. (nullable)
  --name: string # nullable
  --phone: string # GroupSize Limits the number of people that can come along on a single appointment (nullable)
  --region-id: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
  --timezone-name: string # Field is required. It is in Iana format. e.g. America/New_York. Use moment.js in your client for ease of timezone detection and selection (nullable)
  --website: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/locations")
  let req_body = {"address": $address, "adminEmail": $admin_email, "adminName": $admin_name, "appointmentReminders": $appointment_reminders, "businessHours": $business_hours, "defaults": $defaults, "email": $email, "fax": $fax, "friendlyId": $friendly_id, "name": $name, "phone": $phone, "regionId": $region_id, "settings": $settings, "timezoneName": $timezone_name, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Locations Bulk
#
# POST /setup/v1/locations/bulk
# --locations item shape: {address?: record, adminEmail?: string, adminName?: string, appointmentReminders?: record, businessHours?: record, defaults?: record, email?: string, fax?: string, friendlyId?: string, name?: string, phone?: string, regionId?: string, settings?: record, timezoneName?: string, website?: string}
export def "setup-locations-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locations: list # nullable — item shape: {address?: record, adminEmail?: string, adminName?: string, appointmentReminders?: record, businessHours?: record, defaults?: record, email?: string, fax?: string, friendlyId?: string, name?: string, phone?: string, regionId?: string, settings?: record, timezoneName?: string, website?: string}
]: any -> table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: list<record>, businessHours: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list<record>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/locations/bulk")
  let req_body = {"locations": $locations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unlink Service
#
# DELETE /setup/v1/locations/services/{id}
export def "setup-locations-services delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/services/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Linked Service
#
# GET /setup/v1/locations/services/{id}
export def "setup-locations-services get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, object: string, serviceId: int, serviceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/services/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Location
#
# DELETE /setup/v1/locations/{id}
export def "setup-locations delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Location
#
# GET /setup/v1/locations/{id}
export def "setup-locations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Location
#
# PUT /setup/v1/locations/{id}
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --appointmentReminders shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
# --businessHours shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --defaults shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
# --settings shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
export def "setup-locations update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --remove-region: oneof<nothing, bool>
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --admin-email: string # nullable
  --admin-name: string # nullable
  --appointment-reminders: record # shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
  --business-hours: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --defaults: record # shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
  --email: string # nullable
  --fax: string # nullable
  --friendly-id: string # nullable
  --name: string # nullable
  --phone: string # nullable
  --region-id: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
  --timezone-name: string # nullable
  --website: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "removeRegion" $remove_region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}") $qp)
  let req_body = {"address": $address, "adminEmail": $admin_email, "adminName": $admin_name, "appointmentReminders": $appointment_reminders, "businessHours": $business_hours, "defaults": $defaults, "email": $email, "fax": $fax, "friendlyId": $friendly_id, "name": $name, "phone": $phone, "regionId": $region_id, "settings": $settings, "timezoneName": $timezone_name, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"removeRegion": $remove_region} | compact), body: $req_body}
}

# Get Reminders
#
# GET /setup/v1/locations/{id}/appointmentreminders
export def "setup-locations-appointmentreminders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/appointmentreminders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Reminders
#
# PUT /setup/v1/locations/{id}/appointmentreminders
export def "setup-locations-appointmentreminders update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-first-reminder: int # nullable, format: int32
  --email-first-reminder-interval: int # format: int32
  --email-second-reminder: int # nullable, format: int32
  --email-second-reminder-interval: int # format: int32
  --sms-first-reminder: int # nullable, format: int32
  --sms-first-reminder-interval: int # format: int32
  --sms-second-reminder: int # nullable, format: int32
  --sms-second-reminder-interval: int # format: int32
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/appointmentreminders"))
  let req_body = {"emailFirstReminder": $email_first_reminder, "emailFirstReminderInterval": $email_first_reminder_interval, "emailSecondReminder": $email_second_reminder, "emailSecondReminderInterval": $email_second_reminder_interval, "smsFirstReminder": $sms_first_reminder, "smsFirstReminderInterval": $sms_first_reminder_interval, "smsSecondReminder": $sms_second_reminder, "smsSecondReminderInterval": $sms_second_reminder_interval} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete All Location Images
#
# DELETE /setup/v1/locations/{id}/deleteallimages
export def "setup-locations-deleteallimages delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uppercase: oneof<nothing, bool>
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "uppercase" $uppercase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/deleteallimages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"uppercase": $uppercase} | compact), body: null}
}

# Delete Location Image
#
# DELETE /setup/v1/locations/{id}/deleteimage
export def "setup-locations-deleteimage delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/deleteimage"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Email Templates
#
# GET /setup/v1/locations/{id}/email/templates
export def "setup-locations-email-templates list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<customized: bool, description: string, name: string, object: string, scope: string>, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/email/templates"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Custom Template
#
# POST /setup/v1/locations/{id}/email/templates
export def "setup-locations-email-templates create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --template-content: string # nullable
  --template-name: string # nullable
]: any -> record<content: string, contentType: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/email/templates"))
  let req_body = {"templateContent": $template_content, "templateName": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Master Template Settings
#
# DELETE /setup/v1/locations/{id}/email/templates/master
export def "setup-locations-email-templates-master delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/email/templates/master"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Master Template Settings
#
# GET /setup/v1/locations/{id}/email/templates/master
export def "setup-locations-email-templates-master get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/email/templates/master"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Master Template Settings
#
# POST /setup/v1/locations/{id}/email/templates/master
export def "setup-locations-email-templates-master create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --center-email-content: oneof<nothing, bool> # nullable
  --center-email-content-panel: oneof<nothing, bool> # nullable
  --center-email-footer: oneof<nothing, bool> # nullable
  --content-background-color: string # nullable
  --content-color: string # nullable
  --content-link-color: string # nullable
  --email-background-color: string # nullable
  --email-color: string # nullable
  --email-link-color: string # nullable
  --footer-font-size: string # nullable
  --footer-logo-height: string # nullable
  --footer-logo-padding: string # nullable
  --footer-panel-email-contact: oneof<nothing, bool> # nullable
  --footer-panel-phone-contact: oneof<nothing, bool> # nullable
  --footer-panel-website-contact: oneof<nothing, bool> # nullable
  --header-logo-height: string # nullable
  --header-logo-padding: string # nullable
  --panel-background-color: string # nullable
  --panel-color: string # nullable
  --panel-link-color: string # nullable
  --privacy-policy-link: string # nullable
  --show-content-panel: oneof<nothing, bool> # nullable
  --show-footer-logo: oneof<nothing, bool> # nullable
  --show-footer-panel: oneof<nothing, bool> # nullable
  --show-header-logo: oneof<nothing, bool> # nullable
  --show-header-panel: oneof<nothing, bool> # nullable
]: any -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/email/templates/master"))
  let req_body = {"centerEmailContent": $center_email_content, "centerEmailContentPanel": $center_email_content_panel, "centerEmailFooter": $center_email_footer, "contentBackgroundColor": $content_background_color, "contentColor": $content_color, "contentLinkColor": $content_link_color, "emailBackgroundColor": $email_background_color, "emailColor": $email_color, "emailLinkColor": $email_link_color, "footerFontSize": $footer_font_size, "footerLogoHeight": $footer_logo_height, "footerLogoPadding": $footer_logo_padding, "footerPanelEmailContact": $footer_panel_email_contact, "footerPanelPhoneContact": $footer_panel_phone_contact, "footerPanelWebsiteContact": $footer_panel_website_contact, "headerLogoHeight": $header_logo_height, "headerLogoPadding": $header_logo_padding, "panelBackgroundColor": $panel_background_color, "panelColor": $panel_color, "panelLinkColor": $panel_link_color, "privacyPolicyLink": $privacy_policy_link, "showContentPanel": $show_content_panel, "showFooterLogo": $show_footer_logo, "showFooterPanel": $show_footer_panel, "showHeaderLogo": $show_header_logo, "showHeaderPanel": $show_header_panel} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Custom Template
#
# DELETE /setup/v1/locations/{id}/email/templates/{templateName}
export def "setup-locations-email-templates delete" [
  id: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, contentType: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'templateName' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), template_name: (encode-path-segment $template_name)} | format pattern "/setup/v1/locations/{id}/email/templates/{template_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Email Template
#
# GET /setup/v1/locations/{id}/email/templates/{templateName}
export def "setup-locations-email-templates get" [
  id: string
  template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, contentType: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($template_name | is-empty) { error make --unspanned { msg: "path parameter 'templateName' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), template_name: (encode-path-segment $template_name)} | format pattern "/setup/v1/locations/{id}/email/templates/{template_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Google Cal Access
#
# DELETE /setup/v1/locations/{id}/google/service/account
export def "setup-locations-google-service-account delete" [
  id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/google/service/account"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Google Cal Access
#
# POST /setup/v1/locations/{id}/google/service/account
export def "setup-locations-google-service-account create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-provider-x509-cert-url: string # nullable
  --auth-uri: string # nullable
  --client-email: string # nullable
  --client-id: string # nullable
  --client-x509-cert-url: string # nullable
  --private-key: string # nullable
  --private-key-id: string # nullable
  --project-id: string # nullable
  --token-uri: string # nullable
  --type: string # nullable
]: any -> record<auth_provider_x509_cert_url: string, auth_uri: string, client_email: string, client_id: string, client_x509_cert_url: string, private_key: string, private_key_id: string, project_id: string, token_uri: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/google/service/account"))
  let req_body = {"auth_provider_x509_cert_url": $auth_provider_x509_cert_url, "auth_uri": $auth_uri, "client_email": $client_email, "client_id": $client_id, "client_x509_cert_url": $client_x509_cert_url, "private_key": $private_key, "private_key_id": $private_key_id, "project_id": $project_id, "token_uri": $token_uri, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Location Holidays
#
# PUT /setup/v1/locations/{id}/holidays/{holidayId}/{closed}
export def "setup-locations-holidays update" [
  id: string
  holiday_id: string
  closed: bool
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($holiday_id | is-empty) { error make --unspanned { msg: "path parameter 'holidayId' must be non-empty" } }
  if ($closed | is-empty) { error make --unspanned { msg: "path parameter 'closed' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), holiday_id: (encode-path-segment $holiday_id), closed: (encode-path-segment $closed)} | format pattern "/setup/v1/locations/{id}/holidays/{holiday_id}/{closed}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Recover Location
#
# PUT /setup/v1/locations/{id}/recover
export def "setup-locations-recover update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/recover"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Linked Services
#
# DELETE /setup/v1/locations/{id}/services
export def "setup-locations-services delete-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/services"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Location Linked Services
#
# GET /setup/v1/locations/{id}/services
export def "setup-locations-services get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<id: int, object: string, serviceId: int, serviceName: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/services") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Linked Service
#
# POST /setup/v1/locations/{id}/services
export def "setup-locations-services create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/services"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Location Scope
#
# PUT /setup/v1/locations/{id}/settings/scope/{settingsScope}
export def "setup-locations-settings-scope update" [
  id: string
  settings_scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($settings_scope | is-empty) { error make --unspanned { msg: "path parameter 'settingsScope' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), settings_scope: (encode-path-segment $settings_scope)} | format pattern "/setup/v1/locations/{id}/settings/scope/{settings_scope}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload Location Image
#
# POST /setup/v1/locations/{id}/uploadimage
export def "setup-locations-uploadimage create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-file-data: string # nullable
  --image-file-name: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/locations/{id}/uploadimage"))
  let req_body = {"imageFileData": $image_file_data, "imageFileName": $image_file_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Resource Groups
#
# GET /setup/v1/resourcegroups
export def "setup-resourcegroups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --deleted: oneof<nothing, bool> # Filter results by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resourcegroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "deleted": $deleted, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Resource Group
#
# POST /setup/v1/resourcegroups
export def "setup-resourcegroups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # nullable
  --email: string # nullable
  --location-id: string # nullable
  --name: string # nullable
]: any -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/resourcegroups")
  let req_body = {"description": $description, "email": $email, "locationId": $location_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Resource Group
#
# DELETE /setup/v1/resourcegroups/{id}
export def "setup-resourcegroups delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resourcegroups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Resource Group
#
# GET /setup/v1/resourcegroups/{id}
export def "setup-resourcegroups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resourcegroups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Resource Group
#
# PUT /setup/v1/resourcegroups/{id}
export def "setup-resourcegroups update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # nullable
  --email: string # nullable
  --name: string # nullable
]: any -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resourcegroups/{id}"))
  let req_body = {"description": $description, "email": $email, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Recover Resource Group
#
# PUT /setup/v1/resourcegroups/{id}/recover
export def "setup-resourcegroups-recover update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resourcegroups/{id}/recover"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Resources
#
# GET /setup/v1/resources
export def "setup-resources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --resource-group-id: string # Filter by group Id
  --email: string # Filter by email address
  --name: string # Search by name
  --deleted: oneof<nothing, bool> # Show by deleted status, default is false
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max is 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "resourceGroupId" $resource_group_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar") (serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "resourceGroupId": $resource_group_id, "email": $email, "name": $name, "deleted": $deleted, "googleAuthReturnUrl": $google_auth_return_url, "outlookAuthReturnUrl": $outlook_auth_return_url, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Resource
#
# POST /setup/v1/resources
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --contact shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --options shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
export def "setup-resources create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --email: string # nullable
  --group-id: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --options: record # Options for the new resource — shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
  --recurring-availability: oneof<nothing, bool> # nullable
  --service-ids: list<string> # nullable
  --timezone-id: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar") (serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resources" $qp)
  let req_body = {"address": $address, "availability": $availability, "contact": $contact, "customFields": $custom_fields, "description": $description, "email": $email, "groupId": $group_id, "locationId": $location_id, "name": $name, "options": $options, "recurringAvailability": $recurring_availability, "serviceIds": $service_ids, "timezoneId": $timezone_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"googleAuthReturnUrl": $google_auth_return_url, "outlookAuthReturnUrl": $outlook_auth_return_url} | compact), body: $req_body}
}

# Delete Allocation
#
# DELETE /setup/v1/resources/allocations/{id}
export def "setup-resources-allocations delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/allocations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Allocation
#
# GET /setup/v1/resources/allocations/{id}
export def "setup-resources-allocations get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/allocations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Allocation
#
# PUT /setup/v1/resources/allocations/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-resources-allocations update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/allocations/{id}"))
  let req_body = {"endDate": $end_date, "endTime": $end_time, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Block
#
# DELETE /setup/v1/resources/block/{id}
export def "setup-resources-block delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/block/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Block
#
# PUT /setup/v1/resources/block/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-resources-block update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all-day: oneof<nothing, bool> # nullable
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/block/{id}"))
  let req_body = {"allDay": $all_day, "endDate": $end_date, "endTime": $end_time, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Block
#
# GET /setup/v1/resources/blocks/{id}
export def "setup-resources-blocks get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/blocks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Resources Bulk
#
# POST /setup/v1/resources/bulk
# --resources item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, locationId?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list<string>, timezoneId?: string}
export def "setup-resources-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --resources: list # nullable — item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, locationId?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list<string>, timezoneId?: string}
]: any -> table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: list<record>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar") (serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resources/bulk" $qp)
  let req_body = {"resources": $resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"googleAuthReturnUrl": $google_auth_return_url, "outlookAuthReturnUrl": $outlook_auth_return_url} | compact), body: $req_body}
}

# Update Resources Bulk
#
# PUT /setup/v1/resources/bulk
# --resources item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, id?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list<string>, timezoneId?: string}
export def "setup-resources-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --resources: list # nullable — item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, id?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list<string>, timezoneId?: string}
]: any -> table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: list<record>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar") (serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resources/bulk" $qp)
  let req_body = {"resources": $resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"googleAuthReturnUrl": $google_auth_return_url, "outlookAuthReturnUrl": $outlook_auth_return_url} | compact), body: $req_body}
}

# Get Time Zones
#
# GET /setup/v1/resources/timezones
export def "setup-resources-timezones get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<baseUtcOffset: int, daylightName: string, displayName: string, standardName: string, supportsDaylightSavingTime: bool, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/resources/timezones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Resource
#
# DELETE /setup/v1/resources/{id}
export def "setup-resources delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Resource
#
# GET /setup/v1/resources/{id}
export def "setup-resources get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar") (serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"googleAuthReturnUrl": $google_auth_return_url, "outlookAuthReturnUrl": $outlook_auth_return_url} | compact), body: null}
}

# Update Resource
#
# PUT /setup/v1/resources/{id}
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --contact shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --options shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
export def "setup-resources update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --email: string # nullable
  --group-id: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --options: record # shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
  --recurring-availability: oneof<nothing, bool> # nullable
  --service-ids: list<string> # nullable
  --timezone-id: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar") (serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}") $qp)
  let req_body = {"address": $address, "availability": $availability, "contact": $contact, "customFields": $custom_fields, "description": $description, "email": $email, "groupId": $group_id, "locationId": $location_id, "name": $name, "options": $options, "recurringAvailability": $recurring_availability, "serviceIds": $service_ids, "timezoneId": $timezone_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"googleAuthReturnUrl": $google_auth_return_url, "outlookAuthReturnUrl": $outlook_auth_return_url} | compact), body: $req_body}
}

# List Resource Allocations
#
# GET /setup/v1/resources/{id}/allocations
export def "setup-resources-allocations get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # yyyy-mm-dd, filter allocations on/after startDate (format: date-time)
  --end-date: string # yyyy-mm-dd, filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record, repeats: bool, resourceId: int, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/allocations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Allocation
#
# POST /setup/v1/resources/{id}/allocations
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-resources-allocations create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/allocations"))
  let req_body = {"endDate": $end_date, "endTime": $end_time, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Weekly Availability
#
# GET /setup/v1/resources/{id}/availability
export def "setup-resources-availability get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<businessId: int, ignoreBusinessHours: bool, resourceId: int, resourceName: string, resourceTzo: int, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/availability"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Weekly Availability
#
# PUT /setup/v1/resources/{id}/availability
# --fri shape: {endTime?: int, startTime?: int}
# --mon shape: {endTime?: int, startTime?: int}
# --sat shape: {endTime?: int, startTime?: int}
# --sun shape: {endTime?: int, startTime?: int}
# --thu shape: {endTime?: int, startTime?: int}
# --tue shape: {endTime?: int, startTime?: int}
# --wed shape: {endTime?: int, startTime?: int}
export def "setup-resources-availability update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fri: record # shape: {endTime?: int, startTime?: int}
  --mon: record # shape: {endTime?: int, startTime?: int}
  --sat: record # shape: {endTime?: int, startTime?: int}
  --sun: record # shape: {endTime?: int, startTime?: int}
  --thu: record # shape: {endTime?: int, startTime?: int}
  --tue: record # shape: {endTime?: int, startTime?: int}
  --wed: record # shape: {endTime?: int, startTime?: int}
]: any -> record<businessId: int, ignoreBusinessHours: bool, resourceId: int, resourceName: string, resourceTzo: int, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/availability"))
  let req_body = {"fri": $fri, "mon": $mon, "sat": $sat, "sun": $sun, "thu": $thu, "tue": $tue, "wed": $wed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Block
#
# POST /setup/v1/resources/{id}/block
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-resources-block create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all-day: oneof<nothing, bool> # nullable
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/block"))
  let req_body = {"allDay": $all_day, "endDate": $end_date, "endTime": $end_time, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Resource Blocks
#
# GET /setup/v1/resources/{id}/blocks
export def "setup-resources-blocks get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # YYYY-MM-DD, filter blocks on/after startDate (format: date-time)
  --end-date: string # YYYY-MM-DD, filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record, repeats: bool, resourceId: int, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/blocks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Get Resource Google URL
#
# GET /setup/v1/resources/{id}/calendar/auth/google/{googleEmailAddress}
export def "setup-resources-calendar-auth-google get" [
  id: string
  google_email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
]: nothing -> record<calendarAuthUrl: string, calendarId: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($google_email_address | is-empty) { error make --unspanned { msg: "path parameter 'googleEmailAddress' must be non-empty" } }
  let qp = [(serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), google_email_address: (encode-path-segment $google_email_address)} | format pattern "/setup/v1/resources/{id}/calendar/auth/google/{google_email_address}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"googleAuthReturnUrl": $google_auth_return_url} | compact), body: null}
}

# Get Resource Outlook URL
#
# GET /setup/v1/resources/{id}/calendar/auth/outlook/{outlookEmailAddress}
export def "setup-resources-calendar-auth-outlook get" [
  id: string
  outlook_email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --outlook-auth-return-url: string # Outlook calendar authorization return url
]: nothing -> record<calendarAuthUrl: string, calendarId: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($outlook_email_address | is-empty) { error make --unspanned { msg: "path parameter 'outlookEmailAddress' must be non-empty" } }
  let qp = [(serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), outlook_email_address: (encode-path-segment $outlook_email_address)} | format pattern "/setup/v1/resources/{id}/calendar/auth/outlook/{outlook_email_address}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outlookAuthReturnUrl": $outlook_auth_return_url} | compact), body: null}
}

# Delete Resource Image
#
# DELETE /setup/v1/resources/{id}/deleteimage
export def "setup-resources-deleteimage delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/deleteimage"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reassign Resource
#
# PUT /setup/v1/resources/{id}/reassign/appointments/{resourceId}
export def "setup-resources-reassign-appointments update" [
  id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # YYYY-MM-DD, Appt range start date (format: date-time)
  --end-date: string # YYYY-MM-DD, Appt range end date (format: date-time)
  --calendar-id: string # CalendarId of calendar containing appointments
]: nothing -> table<auditTrail: list<record>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list<record>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list<record>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "calendarId" $calendar_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), resource_id: (encode-path-segment $resource_id)} | format pattern "/setup/v1/resources/{id}/reassign/appointments/{resource_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date, "calendarId": $calendar_id} | compact), body: null}
}

# Recover Resource
#
# PUT /setup/v1/resources/{id}/recover
export def "setup-resources-recover update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar") (serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/recover") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"googleAuthReturnUrl": $google_auth_return_url, "outlookAuthReturnUrl": $outlook_auth_return_url} | compact), body: null}
}

# Delete Linked Services
#
# DELETE /setup/v1/resources/{id}/services
export def "setup-resources-services delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/services"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Linked Services
#
# POST /setup/v1/resources/{id}/services
export def "setup-resources-services create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/services"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Linked Services
#
# PUT /setup/v1/resources/{id}/services
export def "setup-resources-services update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/services"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Upload Resource Image
#
# POST /setup/v1/resources/{id}/uploadimage
export def "setup-resources-uploadimage create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-file-data: string # nullable
  --image-file-name: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/resources/{id}/uploadimage"))
  let req_body = {"imageFileData": $image_file_data, "imageFileName": $image_file_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Service Groups
#
# GET /setup/v1/servicegroups
export def "setup-servicegroups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/servicegroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Service Group
#
# POST /setup/v1/servicegroups
export def "setup-servicegroups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --type: int # nullable, format: int32
]: any -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/servicegroups")
  let req_body = {"description": $description, "locationId": $location_id, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Service Group
#
# DELETE /setup/v1/servicegroups/{id}
export def "setup-servicegroups delete" [
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
]: nothing -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/servicegroups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Service Group
#
# GET /setup/v1/servicegroups/{id}
export def "setup-servicegroups get" [
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
]: nothing -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/servicegroups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Service Group
#
# PUT /setup/v1/servicegroups/{id}
export def "setup-servicegroups update" [
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
  --description: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --type: int # nullable, format: int32
]: any -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/servicegroups/{id}"))
  let req_body = {"description": $description, "locationId": $location_id, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Recover Service Group
#
# PUT /setup/v1/servicegroups/{id}/recover
export def "setup-servicegroups-recover update" [
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
]: nothing -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/servicegroups/{id}/recover"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Services
#
# GET /setup/v1/services
export def "setup-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --service-group-id: int # Filter services by groupId (format: int32)
  --deleted: oneof<nothing, bool> # Filter by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "serviceGroupId" $service_group_id "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "serviceGroupId": $service_group_id, "deleted": $deleted, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Service
#
# POST /setup/v1/services
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --fees shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
# --options shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
# --settings shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
export def "setup-services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --booking-interval: int # format: int32
  --booking-limit: int # format: int32
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --duration: int # format: int32
  --fees: record # shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
  --location-id: string # nullable
  --max-capacity: int # format: int32
  --max-group-size: int # format: int32
  --media-page-url: string # nullable
  --name: string # nullable
  --options: record # shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
  --public: oneof<nothing, bool>
  --service-group-id: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
  --type: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/services")
  let req_body = {"availability": $availability, "bookingInterval": $booking_interval, "bookingLimit": $booking_limit, "customFields": $custom_fields, "description": $description, "duration": $duration, "fees": $fees, "locationId": $location_id, "maxCapacity": $max_capacity, "maxGroupSize": $max_group_size, "mediaPageUrl": $media_page_url, "name": $name, "options": $options, "public": $public, "serviceGroupId": $service_group_id, "settings": $settings, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Allocation
#
# DELETE /setup/v1/services/allocations/{id}
export def "setup-services-allocations delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/allocations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Allocation
#
# GET /setup/v1/services/allocations/{id}
export def "setup-services-allocations get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/allocations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Allocation
#
# PUT /setup/v1/services/allocations/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-services-allocations update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --booking-limit: int # format: int32
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --location-id: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --resource-id: string # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/allocations/{id}"))
  let req_body = {"bookingLimit": $booking_limit, "endDate": $end_date, "endTime": $end_time, "locationId": $location_id, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "resourceId": $resource_id, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Block
#
# DELETE /setup/v1/services/block/{id}
export def "setup-services-block delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/block/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Block
#
# PUT /setup/v1/services/block/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-services-block update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, serviceId: string, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/block/{id}"))
  let req_body = {"endDate": $end_date, "endTime": $end_time, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Block
#
# GET /setup/v1/services/blocks/{id}
export def "setup-services-blocks get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/blocks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Link Service to Calendar
#
# POST /setup/v1/services/calendar
export def "setup-services-calendar create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --calendar-id: string # nullable
  --location-id: string # nullable
  --service-id: string # nullable
]: any -> record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/services/calendar")
  let req_body = {"calendarId": $calendar_id, "locationId": $location_id, "serviceId": $service_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Service Links
#
# DELETE /setup/v1/services/calendar/{id}
export def "setup-services-calendar delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/calendar/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Service
#
# DELETE /setup/v1/services/{id}
export def "setup-services delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Service
#
# GET /setup/v1/services/{id}
export def "setup-services get" [
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
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Service
#
# PUT /setup/v1/services/{id}
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --fees shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
# --options shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
# --settings shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
export def "setup-services update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --booking-interval: int # nullable, format: int32
  --booking-limit: int # nullable, format: int32
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --duration: int # nullable, format: int32
  --fees: record # shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
  --location-id: string # nullable
  --max-capacity: int # nullable, format: int32
  --max-group-size: int # nullable, format: int32
  --media-page-url: string # nullable
  --name: string # nullable
  --options: record # shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
  --public: oneof<nothing, bool> # nullable
  --service-group-id: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
  --type: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}"))
  let req_body = {"availability": $availability, "bookingInterval": $booking_interval, "bookingLimit": $booking_limit, "customFields": $custom_fields, "description": $description, "duration": $duration, "fees": $fees, "locationId": $location_id, "maxCapacity": $max_capacity, "maxGroupSize": $max_group_size, "mediaPageUrl": $media_page_url, "name": $name, "options": $options, "public": $public, "serviceGroupId": $service_group_id, "settings": $settings, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Service Allocations
#
# GET /setup/v1/services/{id}/allocations
export def "setup-services-allocations get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # The id of the location. Defaults to the primary location
  --resource-id: string # The id of the resource to filter on
  --start-date: string # Format YYYY-MM-DD. Filter appointments by on/after startDate (format: date-time)
  --end-date: string # Format YYYY-MM-DD. Filter appointments on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, resourceAddress: record, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/allocations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id, "resourceId": $resource_id, "startDate": $start_date, "endDate": $end_date, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Create Allocation
#
# POST /setup/v1/services/{id}/allocations
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-services-allocations create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --booking-limit: int # format: int32
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --location-id: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --resource-id: string # nullable
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/allocations"))
  let req_body = {"bookingLimit": $booking_limit, "endDate": $end_date, "endTime": $end_time, "locationId": $location_id, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "resourceId": $resource_id, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Allocations Bulk
#
# POST /setup/v1/services/{id}/allocations/bulk
# --serviceAllocations item shape: {bookingLimit?: int, endDate?: string, endTime?: int, locationId?: string, reason?: string, repeat?: record, repeats?: bool, resourceId?: string, startDate?: string, startTime?: int}
export def "setup-services-allocations-bulk create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-allocations: list # nullable — item shape: {bookingLimit?: int, endDate?: string, endTime?: int, locationId?: string, reason?: string, repeat?: record, repeats?: bool, resourceId?: string, startDate?: string, startTime?: int}
]: any -> table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/allocations/bulk"))
  let req_body = {"serviceAllocations": $service_allocations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Weekly Availability
#
# GET /setup/v1/services/{id}/availability
export def "setup-services-availability get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ignoreBusinessHours: bool, serviceId: int, serviceName: string, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/availability"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Weekly Availability
#
# PUT /setup/v1/services/{id}/availability
# --fri shape: {endTime?: int, startTime?: int}
# --mon shape: {endTime?: int, startTime?: int}
# --sat shape: {endTime?: int, startTime?: int}
# --sun shape: {endTime?: int, startTime?: int}
# --thu shape: {endTime?: int, startTime?: int}
# --tue shape: {endTime?: int, startTime?: int}
# --wed shape: {endTime?: int, startTime?: int}
export def "setup-services-availability update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fri: record # shape: {endTime?: int, startTime?: int}
  --mon: record # shape: {endTime?: int, startTime?: int}
  --sat: record # shape: {endTime?: int, startTime?: int}
  --sun: record # shape: {endTime?: int, startTime?: int}
  --thu: record # shape: {endTime?: int, startTime?: int}
  --tue: record # shape: {endTime?: int, startTime?: int}
  --wed: record # shape: {endTime?: int, startTime?: int}
]: any -> record<ignoreBusinessHours: bool, serviceId: int, serviceName: string, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/availability"))
  let req_body = {"fri": $fri, "mon": $mon, "sat": $sat, "sun": $sun, "thu": $thu, "tue": $tue, "wed": $wed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Block
#
# POST /setup/v1/services/{id}/block
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-services-block create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-date: string # nullable, format: date
  --end-time: int # nullable, format: int32
  --location-id: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool>
  --start-date: string # nullable, format: date
  --start-time: int # nullable, format: int32
]: any -> record<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, serviceId: string, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/block"))
  let req_body = {"endDate": $end_date, "endTime": $end_time, "locationId": $location_id, "reason": $reason, "repeat": $repeat, "repeats": $repeats, "startDate": $start_date, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Service Blocks
#
# GET /setup/v1/services/{id}/blocks
export def "setup-services-blocks get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Format YYYY-MM-DD. Filter blocks on/after startDate (format: date-time)
  --end-date: string # Format YYYY-MM-DD. Filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, serviceId: string, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/blocks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date, "offset": $offset, "limit": $limit} | compact), body: null}
}

# Get Linked Calendar
#
# GET /setup/v1/services/{id}/calendar
export def "setup-services-calendar get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
]: nothing -> record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locationId" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/calendar") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locationId": $location_id} | compact), body: null}
}

# Delete Service Image
#
# DELETE /setup/v1/services/{id}/deleteimage
export def "setup-services-deleteimage delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/deleteimage"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Recover Service
#
# PUT /setup/v1/services/{id}/recover
export def "setup-services-recover update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/recover"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List Resources for Service
#
# GET /setup/v1/services/{id}/resources
export def "setup-services-resources get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
  --google-auth-return-url: string # Google calendar authorization return url
  --outlook-auth-return-url: string # Outlook calendar authorization return url
]: nothing -> record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "googleAuthReturnUrl" $google_auth_return_url "scalar") (serialize-qp "outlookAuthReturnUrl" $outlook_auth_return_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/resources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "limit": $limit, "googleAuthReturnUrl": $google_auth_return_url, "outlookAuthReturnUrl": $outlook_auth_return_url} | compact), body: null}
}

# Upload Service Image
#
# POST /setup/v1/services/{id}/uploadimage
export def "setup-services-uploadimage create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-file-data: string # nullable
  --image-file-name: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/setup/v1/services/{id}/uploadimage"))
  let req_body = {"imageFileData": $image_file_data, "imageFileName": $image_file_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
