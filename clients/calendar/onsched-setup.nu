# Auto-generated client for OnSched Setup API vv1
# Source: https://api.apis.guru/v2/specs/onsched.com/setup/v1/openapi.json
# Auth: --token flag or $env.ONSCHED_SETUP_API_TOKEN

const BASE_URL = "https://sandbox-api.onsched.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ONSCHED_SETUP_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox-api.onsched.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  --locationId: string # id of business location, defaults to primary business location
  --email: string # Filter appointments by email address
  --lastname: string # Filter appointments by lastname or part of
  --serviceId: string # Filter appointments by service
  --calendarId: string # Filter appointments by calendar
  --resourceId: string # Filter appointments by resource
  --customerId: string # Filter appointments by customer
  --serviceAllocationId: string # Filter appointments by service allocation
  --startDate: string # Format YYYY-MM-DD: Filter appointments by on/after startDate (format: date-time)
  --endDate: string # Format YYYY-MM-DD: Filter appointments on/before endDate (format: date-time)
  --status: string # Filter appointments by status: IN, BK, CN, RE, RS
  --bookedBy: string # Filter appointments by user email who booked
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "serviceId" $serviceId "scalar") (serialize-qp "calendarId" $calendarId "scalar") (serialize-qp "resourceId" $resourceId "scalar") (serialize-qp "customerId" $customerId "scalar") (serialize-qp "serviceAllocationId" $serviceAllocationId "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "bookedBy" $bookedBy "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/appointments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/appointments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reassign Appointment
#
# PUT /setup/v1/appointments/{id}/reassign/resource/{resourceId}
export def "setup-appointments-reassign-resource put" [
  id: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/appointments/($id)/reassign/resource/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --locationId: string # id of business location, defaults to primary business location
  --email: string # Filter by email address
  --role: string # Filter user role
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: list, resourceId: string, resourceName: string, role: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/businessusers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User
#
# POST /setup/v1/businessusers
export def "setup-businessusers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # nullable
  --locationId: string # nullable
  --name: string # nullable
  --resourceId: string # nullable
  --role: string # nullable
  --sendRegistrationInvite: oneof<nothing, bool>
]: any -> record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/businessusers")
  let body = {email: $email, locationId: $locationId, name: $name, resourceId: $resourceId, role: $role, sendRegistrationInvite: $sendRegistrationInvite} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --searchText: string # All or partial company name
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<id: string, name: string, object: string>, email: string, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchText" $searchText "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/businessusers/($email)/companies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/businessusers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/businessusers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User
#
# PUT /setup/v1/businessusers/{id}
export def "setup-businessusers put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # nullable
  --name: string # nullable
  --resourceId: string # nullable
  --role: string # nullable
  --sendRegistrationInvite: oneof<nothing, bool>
]: any -> record<accountId: string, businessName: string, email: string, id: string, identityAccount: bool, locationId: string, name: string, object: string, permissions: table<access: string, function: string, object: string>, resourceId: string, resourceName: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/businessusers/($id)")
  let body = {email: $email, name: $name, resourceId: $resourceId, role: $role, sendRegistrationInvite: $sendRegistrationInvite} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --locationId: string # id of business location, defaults to primary business location
  --deleted: oneof<nothing, bool> # Filter by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<availability: record, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/calendars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DEPRECATING: Create
#
# POST /setup/v1/calendars
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
export def "setup-calendars post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --bookingsPerSlot: int # format: int32
  --interval: int # format: int32
  --locationId: string # nullable
  --name: string # nullable
  --resourceGroupId: string # nullable
  --type: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/calendars")
  let body = {availability: $availability, bookingsPerSlot: $bookingsPerSlot, interval: $interval, locationId: $locationId, name: $name, resourceGroupId: $resourceGroupId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/calendars/block/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Calendar Block
#
# PUT /setup/v1/calendars/block/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-calendars-block put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/calendars/block/($id)")
  let body = {endDate: $endDate, endTime: $endTime, reason: $reason, repeat: $repeat, repeats: $repeats, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/calendars/blocks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/calendars/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/calendars/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Calendar
#
# PUT /setup/v1/calendars/{id}
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
export def "setup-calendars put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --bookingsPerSlot: int # format: int32
  --interval: int # format: int32
  --locationId: string # nullable
  --name: string # nullable
  --resourceGroupId: string # nullable
  --type: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/calendars/($id)")
  let body = {availability: $availability, bookingsPerSlot: $bookingsPerSlot, interval: $interval, locationId: $locationId, name: $name, resourceGroupId: $resourceGroupId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Calendar Block
#
# POST /setup/v1/calendars/{id}/block
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-calendars-block post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/calendars/($id)/block")
  let body = {endDate: $endDate, endTime: $endTime, reason: $reason, repeat: $repeat, repeats: $repeats, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<calendarId: string, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/calendars/($id)/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover Calendar
#
# PUT /setup/v1/calendars/{id}/recover
export def "setup-calendars-recover put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookingsPerSlot: int, deletedStatus: bool, deletedTime: string, id: string, interval: int, locationId: string, name: string, object: string, primary: bool, resourceGroupId: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/calendars/($id)/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/calendars/($id)/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Company
#
# POST /setup/v1/companies
export def "setup-companies post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addressLine1: string # nullable
  --addressLine2: string # nullable
  --bookingWebhookUrl: string # nullable
  --city: string # nullable
  --country: string # nullable
  --customerWebhookUrl: string # nullable
  --disableEmailAndSmsNotifications: oneof<nothing, bool> # nullable
  --email: string # nullable
  --fax: string # nullable
  --name: string # nullable
  --notificationFromEmailAddress: string # nullable
  --notificationFromName: string # nullable
  --phone: string # nullable
  --postalCode: string # nullable
  --registrationEmail: string # nullable
  --reminderWebhookUrl: string # nullable
  --resourceWebhookUrl: string # nullable
  --state: string # nullable
  --timezoneName: string # nullable
  --webhookSignatureHash: string # nullable
  --website: string # nullable
]: any -> record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies")
  let body = {addressLine1: $addressLine1, addressLine2: $addressLine2, bookingWebhookUrl: $bookingWebhookUrl, city: $city, country: $country, customerWebhookUrl: $customerWebhookUrl, disableEmailAndSmsNotifications: $disableEmailAndSmsNotifications, email: $email, fax: $fax, name: $name, notificationFromEmailAddress: $notificationFromEmailAddress, notificationFromName: $notificationFromName, phone: $phone, postalCode: $postalCode, registrationEmail: $registrationEmail, reminderWebhookUrl: $reminderWebhookUrl, resourceWebhookUrl: $resourceWebhookUrl, state: $state, timezoneName: $timezoneName, webhookSignatureHash: $webhookSignatureHash, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Company
#
# PUT /setup/v1/companies
export def "setup-companies put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addressLine1: string # nullable
  --addressLine2: string # nullable
  --bookingWebhookUrl: string # nullable
  --city: string # nullable
  --country: string # nullable
  --customerWebhookUrl: string # nullable
  --disableEmailAndSmsNotifications: oneof<nothing, bool> # nullable
  --email: string # nullable
  --fax: string # nullable
  --name: string # nullable
  --notificationFromEmailAddress: string # nullable
  --notificationFromName: string # nullable
  --phone: string # nullable
  --postalCode: string # nullable
  --registrationEmail: string # nullable
  --reminderWebhookUrl: string # nullable
  --resourceWebhookUrl: string # nullable
  --state: string # nullable
  --timezoneName: string # nullable
  --webhookSignatureHash: string # nullable
  --website: string # nullable
]: any -> record<addressLine1: string, addressLine2: string, bookingWebhookUrl: string, city: string, clientId: string, clientSecret: string, country: string, customerWebhookUrl: string, deletedStatus: bool, deletedTime: string, disableEmailAndSmsNotifications: bool, email: string, fax: string, id: string, name: string, notificationFromEmailAddress: string, notificationFromName: string, object: string, phone: string, postalCode: string, registrationDate: string, registrationEmail: string, reminderWebhookUrl: string, resourceWebhookUrl: string, state: string, timezoneId: string, timezoneName: string, webhookSignatureHash: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies")
  let body = {addressLine1: $addressLine1, addressLine2: $addressLine2, bookingWebhookUrl: $bookingWebhookUrl, city: $city, country: $country, customerWebhookUrl: $customerWebhookUrl, disableEmailAndSmsNotifications: $disableEmailAndSmsNotifications, email: $email, fax: $fax, name: $name, notificationFromEmailAddress: $notificationFromEmailAddress, notificationFromName: $notificationFromName, phone: $phone, postalCode: $postalCode, registrationEmail: $registrationEmail, reminderWebhookUrl: $reminderWebhookUrl, resourceWebhookUrl: $resourceWebhookUrl, state: $state, timezoneName: $timezoneName, webhookSignatureHash: $webhookSignatureHash, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<data: table<domain: string, id: string, object: string>, object: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Company Domain
#
# POST /setup/v1/companies/domains
export def "setup-companies-domains post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # nullable
]: any -> record<domain: string, id: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/domains")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<domain: string, id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/companies/domains/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<domain: string, id: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/companies/domains/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Company Domain
#
# PUT /setup/v1/companies/domains/{id}
export def "setup-companies-domains put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # nullable
]: any -> record<domain: string, id: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/companies/domains/($id)")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<data: table<customized: bool, description: string, name: string, object: string, scope: string>, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/email/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/email/templates/master")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/email/templates/master")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Master Template Settings
#
# POST /setup/v1/companies/email/templates/master
export def "setup-companies-email-templates-master post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --centerEmailContent: oneof<nothing, bool> # nullable
  --centerEmailContentPanel: oneof<nothing, bool> # nullable
  --centerEmailFooter: oneof<nothing, bool> # nullable
  --contentBackgroundColor: string # nullable
  --contentColor: string # nullable
  --contentLinkColor: string # nullable
  --emailBackgroundColor: string # nullable
  --emailColor: string # nullable
  --emailLinkColor: string # nullable
  --footerFontSize: string # nullable
  --footerLogoHeight: string # nullable
  --footerLogoPadding: string # nullable
  --footerPanelEmailContact: oneof<nothing, bool> # nullable
  --footerPanelPhoneContact: oneof<nothing, bool> # nullable
  --footerPanelWebsiteContact: oneof<nothing, bool> # nullable
  --headerLogoHeight: string # nullable
  --headerLogoPadding: string # nullable
  --panelBackgroundColor: string # nullable
  --panelColor: string # nullable
  --panelLinkColor: string # nullable
  --privacyPolicyLink: string # nullable
  --showContentPanel: oneof<nothing, bool> # nullable
  --showFooterLogo: oneof<nothing, bool> # nullable
  --showFooterPanel: oneof<nothing, bool> # nullable
  --showHeaderLogo: oneof<nothing, bool> # nullable
  --showHeaderPanel: oneof<nothing, bool> # nullable
]: any -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/email/templates/master")
  let body = {centerEmailContent: $centerEmailContent, centerEmailContentPanel: $centerEmailContentPanel, centerEmailFooter: $centerEmailFooter, contentBackgroundColor: $contentBackgroundColor, contentColor: $contentColor, contentLinkColor: $contentLinkColor, emailBackgroundColor: $emailBackgroundColor, emailColor: $emailColor, emailLinkColor: $emailLinkColor, footerFontSize: $footerFontSize, footerLogoHeight: $footerLogoHeight, footerLogoPadding: $footerLogoPadding, footerPanelEmailContact: $footerPanelEmailContact, footerPanelPhoneContact: $footerPanelPhoneContact, footerPanelWebsiteContact: $footerPanelWebsiteContact, headerLogoHeight: $headerLogoHeight, headerLogoPadding: $headerLogoPadding, panelBackgroundColor: $panelBackgroundColor, panelColor: $panelColor, panelLinkColor: $panelLinkColor, privacyPolicyLink: $privacyPolicyLink, showContentPanel: $showContentPanel, showFooterLogo: $showFooterLogo, showFooterPanel: $showFooterPanel, showHeaderLogo: $showHeaderLogo, showHeaderPanel: $showHeaderPanel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Email Template
#
# GET /setup/v1/companies/email/templates/{templateName}
export def "setup-companies-email-templates get" [
  templateName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<content: string, contentType: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/companies/email/templates/($templateName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<id: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/companies/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Region
#
# POST /setup/v1/companies/regions
export def "setup-companies-regions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # nullable
]: any -> record<id: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/companies/regions")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<id: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/companies/regions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/companies/regions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Region
#
# PUT /setup/v1/companies/regions/{id}
export def "setup-companies-regions put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # nullable
]: any -> record<id: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/companies/regions/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<object: string, regions: list<string>, timezones: table<name: string, region: string, timezoneIanna: string, tzOffset: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/companies/timezones/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --locationId: string # id of business location, defaults to primary business location
  --groupId: string # Filter by groupId
  --email: string # Filter by email address.
  --lastname: string # Search by lastname.
  --deleted: oneof<nothing, bool> # Filter by deleted status.
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, birthdate: string, businessName: string, companyName: string, contact: record, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/customers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<appointments: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, customer: record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/customers/($id)/privacy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --name: string # Location name(full or partial) to filter on
  --serviceId: string # Find locations that offer this service
  --friendlyId: string # friendlyId of location
  --deleted: oneof<nothing, bool> # Filter locations on deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, adminEmail: string, adminName: string, appointmentReminders: record, businessHolidays: list, businessHours: record, companyId: string, companyName: string, defaults: record, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list, settings: record, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record, website: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "serviceId" $serviceId "scalar") (serialize-qp "friendlyId" $friendlyId "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Location
#
# POST /setup/v1/locations
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --appointmentReminders shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
# --businessHours shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --defaults shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
# --settings shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
export def "setup-locations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --adminEmail: string # Field is required. (nullable)
  --adminName: string # This field is no longer required and has been deprecated. (nullable)
  --appointmentReminders: record # shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
  --businessHours: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --defaults: record # shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
  --email: string # nullable
  --fax: string # nullable
  --friendlyId: string # Use the friendlyId as an alternative to the assigned locationId Choose something easy and meaningful. Must be unique within your company. FriendlyId's are limited to maximum of 64 characters. (nullable)
  --name: string # nullable
  --phone: string # GroupSize Limits the number of people that can come along on a single appointment (nullable)
  --regionId: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
  --timezoneName: string # Field is required. It is in Iana format. e.g. America/New_York. Use moment.js in your client for ease of timezone detection and selection (nullable)
  --website: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/locations")
  let body = {address: $address, adminEmail: $adminEmail, adminName: $adminName, appointmentReminders: $appointmentReminders, businessHours: $businessHours, defaults: $defaults, email: $email, fax: $fax, friendlyId: $friendlyId, name: $name, phone: $phone, regionId: $regionId, settings: $settings, timezoneName: $timezoneName, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Locations Bulk
#
# POST /setup/v1/locations/bulk
# --locations item shape: {address?: record, adminEmail?: string, adminName?: string, appointmentReminders?: record, businessHours?: record, defaults?: record, email?: string, fax?: string, friendlyId?: string, name?: string, phone?: string, regionId?: string, settings?: record, timezoneName?: string, website?: string}
export def "setup-locations-bulk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locations: list # nullable — item shape: {address?: record, adminEmail?: string, adminName?: string, appointmentReminders?: record, businessHours?: record, defaults?: record, email?: string, fax?: string, friendlyId?: string, name?: string, phone?: string, regionId?: string, settings?: record, timezoneName?: string, website?: string}
]: any -> table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: list<record>, businessHours: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list<record>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/locations/bulk")
  let body = {locations: $locations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<id: int, object: string, serviceId: int, serviceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Location
#
# PUT /setup/v1/locations/{id}
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --appointmentReminders shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
# --businessHours shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --defaults shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
# --settings shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
export def "setup-locations put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --removeRegion: oneof<nothing, bool>
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --adminEmail: string # nullable
  --adminName: string # nullable
  --appointmentReminders: record # shape: {emailFirstReminder?: int, emailFirstReminderInterval?: int, emailSecondReminder?: int, emailSecondReminderInterval?: int, smsFirstReminder?: int, smsFirstReminderInterval?: int, smsSecondReminder?: int, smsSecondReminderInterval?: int}
  --businessHours: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --defaults: record # shape: {autoUpdateCustomer?: bool, businessNotification?: bool, customerCity?: bool, customerState?: bool, emailInfo?: bool, enableUtcTimezone?: bool}
  --email: string # nullable
  --fax: string # nullable
  --friendlyId: string # nullable
  --name: string # nullable
  --phone: string # nullable
  --regionId: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int, bookingTimerMins?: int, customerBookingsPerDay?: int, enableWorldTimezones?: bool}
  --timezoneName: string # nullable
  --website: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "removeRegion" $removeRegion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/locations/($id)" $qp)
  let body = {address: $address, adminEmail: $adminEmail, adminName: $adminName, appointmentReminders: $appointmentReminders, businessHours: $businessHours, defaults: $defaults, email: $email, fax: $fax, friendlyId: $friendlyId, name: $name, phone: $phone, regionId: $regionId, settings: $settings, timezoneName: $timezoneName, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/appointmentreminders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Reminders
#
# PUT /setup/v1/locations/{id}/appointmentreminders
export def "setup-locations-appointmentreminders put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emailFirstReminder: int # nullable, format: int32
  --emailFirstReminderInterval: int # format: int32
  --emailSecondReminder: int # nullable, format: int32
  --emailSecondReminderInterval: int # format: int32
  --smsFirstReminder: int # nullable, format: int32
  --smsFirstReminderInterval: int # format: int32
  --smsSecondReminder: int # nullable, format: int32
  --smsSecondReminderInterval: int # format: int32
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/appointmentreminders")
  let body = {emailFirstReminder: $emailFirstReminder, emailFirstReminderInterval: $emailFirstReminderInterval, emailSecondReminder: $emailSecondReminder, emailSecondReminderInterval: $emailSecondReminderInterval, smsFirstReminder: $smsFirstReminder, smsFirstReminderInterval: $smsFirstReminderInterval, smsSecondReminder: $smsSecondReminder, smsSecondReminderInterval: $smsSecondReminderInterval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --uppercase: oneof<nothing, bool>
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uppercase" $uppercase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/locations/($id)/deleteallimages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/deleteimage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<data: table<customized: bool, description: string, name: string, object: string, scope: string>, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/email/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Template
#
# POST /setup/v1/locations/{id}/email/templates
export def "setup-locations-email-templates post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --templateContent: string # nullable
  --templateName: string # nullable
]: any -> record<content: string, contentType: string, statusCode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/email/templates")
  let body = {templateContent: $templateContent, templateName: $templateName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/email/templates/master")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/email/templates/master")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Master Template Settings
#
# POST /setup/v1/locations/{id}/email/templates/master
export def "setup-locations-email-templates-master post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --centerEmailContent: oneof<nothing, bool> # nullable
  --centerEmailContentPanel: oneof<nothing, bool> # nullable
  --centerEmailFooter: oneof<nothing, bool> # nullable
  --contentBackgroundColor: string # nullable
  --contentColor: string # nullable
  --contentLinkColor: string # nullable
  --emailBackgroundColor: string # nullable
  --emailColor: string # nullable
  --emailLinkColor: string # nullable
  --footerFontSize: string # nullable
  --footerLogoHeight: string # nullable
  --footerLogoPadding: string # nullable
  --footerPanelEmailContact: oneof<nothing, bool> # nullable
  --footerPanelPhoneContact: oneof<nothing, bool> # nullable
  --footerPanelWebsiteContact: oneof<nothing, bool> # nullable
  --headerLogoHeight: string # nullable
  --headerLogoPadding: string # nullable
  --panelBackgroundColor: string # nullable
  --panelColor: string # nullable
  --panelLinkColor: string # nullable
  --privacyPolicyLink: string # nullable
  --showContentPanel: oneof<nothing, bool> # nullable
  --showFooterLogo: oneof<nothing, bool> # nullable
  --showFooterPanel: oneof<nothing, bool> # nullable
  --showHeaderLogo: oneof<nothing, bool> # nullable
  --showHeaderPanel: oneof<nothing, bool> # nullable
]: any -> record<centerEmailContent: bool, centerEmailContentPanel: bool, centerEmailFooter: bool, contentBackgroundColor: string, contentColor: string, contentLinkColor: string, emailBackgroundColor: string, emailColor: string, emailLinkColor: string, footerFontSize: string, footerLogoHeight: string, footerLogoPadding: string, footerPanelEmailContact: bool, footerPanelPhoneContact: bool, footerPanelWebsiteContact: bool, headerLogoHeight: string, headerLogoPadding: string, panelBackgroundColor: string, panelColor: string, panelLinkColor: string, privacyPolicyLink: string, showContentPanel: bool, showFooterLogo: bool, showFooterPanel: bool, showHeaderLogo: bool, showHeaderPanel: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/email/templates/master")
  let body = {centerEmailContent: $centerEmailContent, centerEmailContentPanel: $centerEmailContentPanel, centerEmailFooter: $centerEmailFooter, contentBackgroundColor: $contentBackgroundColor, contentColor: $contentColor, contentLinkColor: $contentLinkColor, emailBackgroundColor: $emailBackgroundColor, emailColor: $emailColor, emailLinkColor: $emailLinkColor, footerFontSize: $footerFontSize, footerLogoHeight: $footerLogoHeight, footerLogoPadding: $footerLogoPadding, footerPanelEmailContact: $footerPanelEmailContact, footerPanelPhoneContact: $footerPanelPhoneContact, footerPanelWebsiteContact: $footerPanelWebsiteContact, headerLogoHeight: $headerLogoHeight, headerLogoPadding: $headerLogoPadding, panelBackgroundColor: $panelBackgroundColor, panelColor: $panelColor, panelLinkColor: $panelLinkColor, privacyPolicyLink: $privacyPolicyLink, showContentPanel: $showContentPanel, showFooterLogo: $showFooterLogo, showFooterPanel: $showFooterPanel, showHeaderLogo: $showHeaderLogo, showHeaderPanel: $showHeaderPanel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Template
#
# DELETE /setup/v1/locations/{id}/email/templates/{templateName}
export def "setup-locations-email-templates delete" [
  id: string
  templateName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<content: string, contentType: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/email/templates/($templateName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Email Template
#
# GET /setup/v1/locations/{id}/email/templates/{templateName}
export def "setup-locations-email-templates get" [
  id: string
  templateName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<content: string, contentType: string, statusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/email/templates/($templateName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/google/service/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Google Cal Access
#
# POST /setup/v1/locations/{id}/google/service/account
export def "setup-locations-google-service-account post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base $"/setup/v1/locations/($id)/google/service/account")
  let body = {auth_provider_x509_cert_url: $auth_provider_x509_cert_url, auth_uri: $auth_uri, client_email: $client_email, client_id: $client_id, client_x509_cert_url: $client_x509_cert_url, private_key: $private_key, private_key_id: $private_key_id, project_id: $project_id, token_uri: $token_uri, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Location Holidays
#
# PUT /setup/v1/locations/{id}/holidays/{holidayId}/{closed}
export def "setup-locations-holidays put" [
  id: string
  holidayId: string
  closed: bool
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/holidays/($holidayId)/($closed)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover Location
#
# PUT /setup/v1/locations/{id}/recover
export def "setup-locations-recover put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<id: int, object: string, serviceId: int, serviceName: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/locations/($id)/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Linked Service
#
# POST /setup/v1/locations/{id}/services
export def "setup-locations-services post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/services")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Location Scope
#
# PUT /setup/v1/locations/{id}/settings/scope/{settingsScope}
export def "setup-locations-settings-scope put" [
  id: string
  settingsScope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/settings/scope/($settingsScope)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Location Image
#
# POST /setup/v1/locations/{id}/uploadimage
export def "setup-locations-uploadimage post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imageFileData: string # nullable
  --imageFileName: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/locations/($id)/uploadimage")
  let body = {imageFileData: $imageFileData, imageFileName: $imageFileName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --locationId: string # id of business location, defaults to primary business location
  --deleted: oneof<nothing, bool> # Filter results by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resourcegroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Resource Group
#
# POST /setup/v1/resourcegroups
export def "setup-resourcegroups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # nullable
  --email: string # nullable
  --locationId: string # nullable
  --name: string # nullable
]: any -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/resourcegroups")
  let body = {description: $description, email: $email, locationId: $locationId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resourcegroups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resourcegroups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Resource Group
#
# PUT /setup/v1/resourcegroups/{id}
export def "setup-resourcegroups put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # nullable
  --email: string # nullable
  --name: string # nullable
]: any -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resourcegroups/($id)")
  let body = {description: $description, email: $email, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recover Resource Group
#
# PUT /setup/v1/resourcegroups/{id}/recover
export def "setup-resourcegroups-recover put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resourcegroups/($id)/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --locationId: string # id of business location, defaults to primary business location
  --resourceGroupId: string # Filter by group Id
  --email: string # Filter by email address
  --name: string # Search by name
  --deleted: oneof<nothing, bool> # Show by deleted status, default is false
  --googleAuthReturnUrl: string # Google calendar authorization return url
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max is 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "resourceGroupId" $resourceGroupId "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar") (serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Resource
#
# POST /setup/v1/resources
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --contact shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --options shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
export def "setup-resources post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --googleAuthReturnUrl: string # Google calendar authorization return url
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --email: string # nullable
  --groupId: string # nullable
  --locationId: string # nullable
  --name: string # nullable
  --options: record # Options for the new resource — shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
  --recurringAvailability: oneof<nothing, bool> # nullable
  --serviceIds: list # nullable
  --timezoneId: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar") (serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resources" $qp)
  let body = {address: $address, availability: $availability, contact: $contact, customFields: $customFields, description: $description, email: $email, groupId: $groupId, locationId: $locationId, name: $name, options: $options, recurringAvailability: $recurringAvailability, serviceIds: $serviceIds, timezoneId: $timezoneId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/allocations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/allocations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Allocation
#
# PUT /setup/v1/resources/allocations/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-resources-allocations put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/allocations/($id)")
  let body = {endDate: $endDate, endTime: $endTime, reason: $reason, repeat: $repeat, repeats: $repeats, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/block/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Block
#
# PUT /setup/v1/resources/block/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-resources-block put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allDay: oneof<nothing, bool> # nullable
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/block/($id)")
  let body = {allDay: $allDay, endDate: $endDate, endTime: $endTime, reason: $reason, repeat: $repeat, repeats: $repeats, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/blocks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Resources Bulk
#
# POST /setup/v1/resources/bulk
# --resources item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, locationId?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list, timezoneId?: string}
export def "setup-resources-bulk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --googleAuthReturnUrl: string # Google calendar authorization return url
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
  --resources: list # nullable — item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, locationId?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list, timezoneId?: string}
]: any -> table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: list<record>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar") (serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resources/bulk" $qp)
  let body = {resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Resources Bulk
#
# PUT /setup/v1/resources/bulk
# --resources item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, id?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list, timezoneId?: string}
export def "setup-resources-bulk put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --googleAuthReturnUrl: string # Google calendar authorization return url
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
  --resources: list # nullable — item shape: {address?: record, availability?: record, contact?: record, customFields?: record, description?: string, email?: string, groupId?: string, id?: string, name?: string, options?: record, recurringAvailability?: bool, serviceIds?: list, timezoneId?: string}
]: any -> table<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record, mon: record, sat: record, sun: record, thu: record, tue: record, wed: record>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: list<record>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar") (serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/resources/bulk" $qp)
  let body = {resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<baseUtcOffset: int, daylightName: string, displayName: string, standardName: string, supportsDaylightSavingTime: bool, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/resources/timezones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --googleAuthReturnUrl: string # Google calendar authorization return url
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar") (serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/resources/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Resource
#
# PUT /setup/v1/resources/{id}
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --contact shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --options shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
export def "setup-resources put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --googleAuthReturnUrl: string # Google calendar authorization return url
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --email: string # nullable
  --groupId: string # nullable
  --locationId: string # nullable
  --name: string # nullable
  --options: record # shape: {bioLink?: string, bookingNotification?: int, calendarAvailability?: int, displayColor?: string, effectiveDate?: string, gender?: string, googleCalendarId?: string, hourly?: float, ignoreBusinessHours?: bool, notificationType?: int, outlookCalendarId?: string, sortKey?: int}
  --recurringAvailability: oneof<nothing, bool> # nullable
  --serviceIds: list # nullable
  --timezoneId: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar") (serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/resources/($id)" $qp)
  let body = {address: $address, availability: $availability, contact: $contact, customFields: $customFields, description: $description, email: $email, groupId: $groupId, locationId: $locationId, name: $name, options: $options, recurringAvailability: $recurringAvailability, serviceIds: $serviceIds, timezoneId: $timezoneId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --startDate: string # yyyy-mm-dd, filter allocations on/after startDate (format: date-time)
  --endDate: string # yyyy-mm-dd, filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record, repeats: bool, resourceId: int, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/resources/($id)/allocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Allocation
#
# POST /setup/v1/resources/{id}/allocations
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-resources-allocations post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)/allocations")
  let body = {endDate: $endDate, endTime: $endTime, reason: $reason, repeat: $repeat, repeats: $repeats, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<businessId: int, ignoreBusinessHours: bool, resourceId: int, resourceName: string, resourceTzo: int, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)/availability")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "setup-resources-availability put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base $"/setup/v1/resources/($id)/availability")
  let body = {fri: $fri, mon: $mon, sat: $sat, sun: $sun, thu: $thu, tue: $tue, wed: $wed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Block
#
# POST /setup/v1/resources/{id}/block
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-resources-block post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allDay: oneof<nothing, bool> # nullable
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)/block")
  let body = {allDay: $allDay, endDate: $endDate, endTime: $endTime, reason: $reason, repeat: $repeat, repeats: $repeats, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --startDate: string # YYYY-MM-DD, filter blocks on/after startDate (format: date-time)
  --endDate: string # YYYY-MM-DD, filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record, repeats: bool, resourceId: int, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/resources/($id)/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Resource Google URL
#
# GET /setup/v1/resources/{id}/calendar/auth/google/{googleEmailAddress}
export def "setup-resources-calendar-auth-google get" [
  id: string
  googleEmailAddress: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --googleAuthReturnUrl: string # Google calendar authorization return url
]: nothing -> record<calendarAuthUrl: string, calendarId: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/resources/($id)/calendar/auth/google/($googleEmailAddress)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Resource Outlook URL
#
# GET /setup/v1/resources/{id}/calendar/auth/outlook/{outlookEmailAddress}
export def "setup-resources-calendar-auth-outlook get" [
  id: string
  outlookEmailAddress: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
]: nothing -> record<calendarAuthUrl: string, calendarId: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/resources/($id)/calendar/auth/outlook/($outlookEmailAddress)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)/deleteimage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reassign Resource
#
# PUT /setup/v1/resources/{id}/reassign/appointments/{resourceId}
export def "setup-resources-reassign-appointments put" [
  id: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # YYYY-MM-DD, Appt range start date (format: date-time)
  --endDate: string # YYYY-MM-DD, Appt range end date (format: date-time)
  --calendarId: string # CalendarId of calendar containing appointments
]: nothing -> table<auditTrail: list<record>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list<record>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list<record>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "calendarId" $calendarId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/resources/($id)/reassign/appointments/($resourceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover Resource
#
# PUT /setup/v1/resources/{id}/recover
export def "setup-resources-recover put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --googleAuthReturnUrl: string # Google calendar authorization return url
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar") (serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/resources/($id)/recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Linked Services
#
# POST /setup/v1/resources/{id}/services
export def "setup-resources-services post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)/services")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Linked Services
#
# PUT /setup/v1/resources/{id}/services
export def "setup-resources-services put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)/services")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload Resource Image
#
# POST /setup/v1/resources/{id}/uploadimage
export def "setup-resources-uploadimage post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imageFileData: string # nullable
  --imageFileName: string # nullable
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record<bioLink: string, bookingNotification: int, calendarAvailability: int, displayColor: string, effectiveDate: string, gender: string, googleCalendarId: string, hourly: float, ignoreBusinessHours: bool, notificationType: int, outlookCalendarId: string, sortKey: int>, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, recurringAvailability: bool, services: table<object: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/resources/($id)/uploadimage")
  let body = {imageFileData: $imageFileData, imageFileName: $imageFileName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --locationId: string # id of business location, defaults to primary business location
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/servicegroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Service Group
#
# POST /setup/v1/servicegroups
export def "setup-servicegroups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # nullable
  --locationId: string # nullable
  --name: string # nullable
  --type: int # nullable, format: int32
]: any -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/servicegroups")
  let body = {description: $description, locationId: $locationId, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/servicegroups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/servicegroups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Service Group
#
# PUT /setup/v1/servicegroups/{id}
export def "setup-servicegroups put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # nullable
  --locationId: string # nullable
  --name: string # nullable
  --type: int # nullable, format: int32
]: any -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/servicegroups/($id)")
  let body = {description: $description, locationId: $locationId, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recover Service Group
#
# PUT /setup/v1/servicegroups/{id}/recover
export def "setup-servicegroups-recover put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/servicegroups/($id)/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --locationId: string # id of business location, defaults to primary business location
  --serviceGroupId: int # Filter services by groupId (format: int32)
  --deleted: oneof<nothing, bool> # Filter by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "serviceGroupId" $serviceGroupId "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setup/v1/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Service
#
# POST /setup/v1/services
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --fees shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
# --options shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
# --settings shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
export def "setup-services post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --bookingInterval: int # format: int32
  --bookingLimit: int # format: int32
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --duration: int # format: int32
  --fees: record # shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
  --locationId: string # nullable
  --maxCapacity: int # format: int32
  --maxGroupSize: int # format: int32
  --mediaPageUrl: string # nullable
  --name: string # nullable
  --options: record # shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
  --public: oneof<nothing, bool>
  --serviceGroupId: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
  --type: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/services")
  let body = {availability: $availability, bookingInterval: $bookingInterval, bookingLimit: $bookingLimit, customFields: $customFields, description: $description, duration: $duration, fees: $fees, locationId: $locationId, maxCapacity: $maxCapacity, maxGroupSize: $maxGroupSize, mediaPageUrl: $mediaPageUrl, name: $name, options: $options, public: $public, serviceGroupId: $serviceGroupId, settings: $settings, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/allocations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/allocations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Allocation
#
# PUT /setup/v1/services/allocations/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-services-allocations put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookingLimit: int # format: int32
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --locationId: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --resourceId: string # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/allocations/($id)")
  let body = {bookingLimit: $bookingLimit, endDate: $endDate, endTime: $endTime, locationId: $locationId, reason: $reason, repeat: $repeat, repeats: $repeats, resourceId: $resourceId, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/block/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Block
#
# PUT /setup/v1/services/block/{id}
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-services-block put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, serviceId: string, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/block/($id)")
  let body = {endDate: $endDate, endTime: $endTime, reason: $reason, repeat: $repeat, repeats: $repeats, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<businessId: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: int, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceId: int, startDate: string, startTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/blocks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link Service to Calendar
#
# POST /setup/v1/services/calendar
export def "setup-services-calendar post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --calendarId: string # nullable
  --locationId: string # nullable
  --serviceId: string # nullable
]: any -> record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setup/v1/services/calendar")
  let body = {calendarId: $calendarId, locationId: $locationId, serviceId: $serviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/calendar/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Service
#
# PUT /setup/v1/services/{id}
# --availability shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --fees shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
# --options shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
# --settings shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
export def "setup-services put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --availability: record # shape: {fri?: record, mon?: record, sat?: record, sun?: record, thu?: record, tue?: record, wed?: record}
  --bookingInterval: int # nullable, format: int32
  --bookingLimit: int # nullable, format: int32
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --description: string # nullable
  --duration: int # nullable, format: int32
  --fees: record # shape: {cancellationFeeAmount?: float, cancellationFeeTaxable?: bool, feeAmount?: float, feeTaxable?: bool, nonRefundable?: bool}
  --locationId: string # nullable
  --maxCapacity: int # nullable, format: int32
  --maxGroupSize: int # nullable, format: int32
  --mediaPageUrl: string # nullable
  --name: string # nullable
  --options: record # shape: {consumerPadding?: bool, defaultService?: bool, durationInterval?: int, durationMax?: int, durationMin?: int, durationSelect?: bool, padding?: int}
  --public: oneof<nothing, bool> # nullable
  --serviceGroupId: string # nullable
  --settings: record # shape: {bookAheadUnit?: int, bookAheadValue?: int, bookInAdvance?: int}
  --type: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)")
  let body = {availability: $availability, bookingInterval: $bookingInterval, bookingLimit: $bookingLimit, customFields: $customFields, description: $description, duration: $duration, fees: $fees, locationId: $locationId, maxCapacity: $maxCapacity, maxGroupSize: $maxGroupSize, mediaPageUrl: $mediaPageUrl, name: $name, options: $options, public: $public, serviceGroupId: $serviceGroupId, settings: $settings, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --locationId: string # The id of the location. Defaults to the primary location
  --resourceId: string # The id of the resource to filter on
  --startDate: string # Format YYYY-MM-DD. Filter appointments by on/after startDate (format: date-time)
  --endDate: string # Format YYYY-MM-DD. Filter appointments on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, resourceAddress: record, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "resourceId" $resourceId "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/services/($id)/allocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Allocation
#
# POST /setup/v1/services/{id}/allocations
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-services-allocations post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bookingLimit: int # format: int32
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --locationId: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool> # nullable
  --resourceId: string # nullable
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)/allocations")
  let body = {bookingLimit: $bookingLimit, endDate: $endDate, endTime: $endTime, locationId: $locationId, reason: $reason, repeat: $repeat, repeats: $repeats, resourceId: $resourceId, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Allocations Bulk
#
# POST /setup/v1/services/{id}/allocations/bulk
# --serviceAllocations item shape: {bookingLimit?: int, endDate?: string, endTime?: int, locationId?: string, reason?: string, repeat?: record, repeats?: bool, resourceId?: string, startDate?: string, startTime?: int}
export def "setup-services-allocations-bulk post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --serviceAllocations: list # nullable — item shape: {bookingLimit?: int, endDate?: string, endTime?: int, locationId?: string, reason?: string, repeat?: record, repeats?: bool, resourceId?: string, startDate?: string, startTime?: int}
]: any -> table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)/allocations/bulk")
  let body = {serviceAllocations: $serviceAllocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<ignoreBusinessHours: bool, serviceId: int, serviceName: string, weekdays: record<fri: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, mon: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sat: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, sun: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, thu: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, tue: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>, wed: record<displayEndTime: string, displayStartTime: string, endTime: int, startTime: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)/availability")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "setup-services-availability put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base $"/setup/v1/services/($id)/availability")
  let body = {fri: $fri, mon: $mon, sat: $sat, sun: $sun, thu: $thu, tue: $tue, wed: $wed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Block
#
# POST /setup/v1/services/{id}/block
# --repeat shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
export def "setup-services-block post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDate: string # nullable, format: date
  --endTime: int # nullable, format: int32
  --locationId: string # nullable
  --reason: string # nullable
  --repeat: record # shape: {frequency?: string, interval?: int, monthDay?: int, monthType?: string, weekdays?: string}
  --repeats: oneof<nothing, bool>
  --startDate: string # nullable, format: date
  --startTime: int # nullable, format: int32
]: any -> record<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, serviceId: string, startDate: string, startTime: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)/block")
  let body = {endDate: $endDate, endTime: $endTime, locationId: $locationId, reason: $reason, repeat: $repeat, repeats: $repeats, startDate: $startDate, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --startDate: string # Format YYYY-MM-DD. Filter blocks on/after startDate (format: date-time)
  --endDate: string # Format YYYY-MM-DD. Filter on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, serviceId: string, startDate: string, startTime: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/services/($id)/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --locationId: string # id of business location, defaults to primary business location
]: nothing -> record<calendarId: string, calendarName: string, id: string, locationId: string, serviceId: string, serviceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/services/($id)/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)/deleteimage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recover Service
#
# PUT /setup/v1/services/{id}/recover
export def "setup-services-recover put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)/recover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
  --googleAuthReturnUrl: string # Google calendar authorization return url
  --outlookAuthReturnUrl: string # Outlook calendar authorization return url
]: nothing -> record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarAuthUrl: string, googleCalendarAuthorized: bool, googleCalendarId: string, groupId: int, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, options: record, outlookCalendarAuthUrl: string, outlookCalendarAuthorized: bool, outlookCalendarId: string, phone: record, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "googleAuthReturnUrl" $googleAuthReturnUrl "scalar") (serialize-qp "outlookAuthReturnUrl" $outlookAuthReturnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/setup/v1/services/($id)/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Service Image
#
# POST /setup/v1/services/{id}/uploadimage
export def "setup-services-uploadimage post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --imageFileData: string # nullable
  --imageFileName: string # nullable
]: any -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/setup/v1/services/($id)/uploadimage")
  let body = {imageFileData: $imageFileData, imageFileName: $imageFileName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
