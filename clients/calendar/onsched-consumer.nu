# Auto-generated client for OnSched Consumer API vv1
# Source: https://api.apis.guru/v2/specs/onsched.com/consumer/v1/openapi.json
# Auth: --token flag or $env.ONSCHED_CONSUMER_API_TOKEN

const BASE_URL = "https://sandbox-api.onsched.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ONSCHED_CONSUMER_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://sandbox-api.onsched.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def scope-completer [] { ["all" "company" "location"] }
def sortOrder-completer [] { ["name" "natural"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "consumer-appointments list" } } | get name | first)
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

# Get Appointments
#
# GET /consumer/v1/appointments
export def "consumer-appointments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location
  --email: string # Filter by email address
  --lastname: string # Filter by lastname or part of it
  --phone: string # Filter by phone number or part of it
  --serviceId: string # Filter by service
  --calendarId: string # Filter by calendar
  --resourceId: string # Filter by resource
  --customerId: string # Filter by customer
  --serviceAllocationId: string # Filter by service allocation
  --startDate: string # Format YYYY-MM-DD. Filter by on/after startDate (format: date-time)
  --endDate: string # Format YYYY-MM-DD. Filter on/before endDate (format: date-time)
  --status: string # Filter by status: IN, BK, CN, RE, RS
  --bookedBy: string # Filter by the email of who booked
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit, default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "phone" $phone "scalar") (serialize-qp "serviceId" $serviceId "scalar") (serialize-qp "calendarId" $calendarId "scalar") (serialize-qp "resourceId" $resourceId "scalar") (serialize-qp "customerId" $customerId "scalar") (serialize-qp "serviceAllocationId" $serviceAllocationId "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "bookedBy" $bookedBy "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/appointments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Appointment
#
# POST /consumer/v1/appointments
# --appointmentBookingFields item shape: {name?: string, value?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --customerBookingFields item shape: {name?: string, value?: string}
export def "consumer-appointments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --completeBooking: string # Options are "BK", "RS" or "IN"
  --appointmentBookingFields: list # nullable — item shape: {name?: string, value?: string}
  --bookedBy: string # nullable
  --bookingWindowId: string # nullable
  --calendarId: string # nullable
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --customerBookingFields: list # nullable — item shape: {name?: string, value?: string}
  --customerId: string # nullable
  --customerMessage: string # nullable
  --email: string # nullable
  --endDateTime: string # format: date-time
  --groupSize: int # nullable, format: int32
  --location: string # nullable
  --locationId: string # nullable
  --name: string # nullable
  --notes: string # nullable
  --phone: string # nullable
  --phoneType: string # nullable
  --resourceGroupId: string # nullable
  --resourceId: string # nullable
  --resourceIds: string # nullable
  --serviceAllocationId: string # nullable
  --serviceId: string # nullable
  --startDateTime: string # format: date-time
  --timezoneName: string # nullable
  --travelAppointmentId: string # nullable
  --travelTimeMins: int # format: int32
]: any -> record<appointmentBookingFields: table<businessId: string, companyId: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, bookingForms: record<bookingConfirmationPage: string, bookingForm: string>, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerBookingFields: table<businessId: string, companyId: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "completeBooking" $completeBooking "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/appointments" $qp)
  let body = {appointmentBookingFields: $appointmentBookingFields, bookedBy: $bookedBy, bookingWindowId: $bookingWindowId, calendarId: $calendarId, customFields: $customFields, customerBookingFields: $customerBookingFields, customerId: $customerId, customerMessage: $customerMessage, email: $email, endDateTime: $endDateTime, groupSize: $groupSize, location: $location, locationId: $locationId, name: $name, notes: $notes, phone: $phone, phoneType: $phoneType, resourceGroupId: $resourceGroupId, resourceId: $resourceId, resourceIds: $resourceIds, serviceAllocationId: $serviceAllocationId, serviceId: $serviceId, startDateTime: $startDateTime, timezoneName: $timezoneName, travelAppointmentId: $travelAppointmentId, travelTimeMins: $travelTimeMins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Custom Fields Labels
#
# GET /consumer/v1/appointments/bookingfields
export def "consumer-appointments-bookingfields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location
]: nothing -> record<bookingFields: table<businessId: string, companyId: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/appointments/bookingfields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Custom Fields List
#
# GET /consumer/v1/appointments/customfields
export def "consumer-appointments-customfields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location
]: nothing -> record<customFields: table<fieldKey: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldPublic: bool, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/appointments/customfields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Appointment
#
# DELETE /consumer/v1/appointments/{id}
export def "consumer-appointments delete" [
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
  let full_url = (build-url $base $"/consumer/v1/appointments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Appointment
#
# GET /consumer/v1/appointments/{id}
export def "consumer-appointments get" [
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
  let full_url = (build-url $base $"/consumer/v1/appointments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Book Appointment
#
# PUT /consumer/v1/appointments/{id}/book
# --appointmentBookingFields item shape: {name?: string, value?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --customerBookingFields item shape: {name?: string, value?: string}
export def "consumer-appointments-book put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --appointmentBookingFields: list # nullable — item shape: {name?: string, value?: string}
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --customerBookingFields: list # nullable — item shape: {name?: string, value?: string}
  --customerMessage: string # nullable
  --email: string # nullable
  --groupSize: int # nullable, format: int32
  --name: string # nullable
  --notes: string # nullable
  --phone: string # nullable
  --phoneExt: string # nullable
  --phoneType: string # nullable
]: any -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/consumer/v1/appointments/($id)/book")
  let body = {appointmentBookingFields: $appointmentBookingFields, customFields: $customFields, customerBookingFields: $customerBookingFields, customerMessage: $customerMessage, email: $email, groupSize: $groupSize, name: $name, notes: $notes, phone: $phone, phoneExt: $phoneExt, phoneType: $phoneType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel Appointment
#
# PUT /consumer/v1/appointments/{id}/cancel
export def "consumer-appointments-cancel put" [
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
  let full_url = (build-url $base $"/consumer/v1/appointments/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirm Appointment
#
# PUT /consumer/v1/appointments/{id}/confirm
export def "consumer-appointments-confirm put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --undo: string@bool-completer # Use this parameter to undo the confirmed status
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "undo" $undo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumer/v1/appointments/($id)/confirm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set NoShow Status
#
# PUT /consumer/v1/appointments/{id}/noshow
export def "consumer-appointments-noshow put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/consumer/v1/appointments/($id)/noshow")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reschedule Appointment
#
# PUT /consumer/v1/appointments/{id}/reschedule
export def "consumer-appointments-reschedule put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDateTime: string # format: date-time
  --resourceId: string # nullable
  --resourceIds: string # nullable
  --serviceId: string # nullable
  --startDateTime: string # format: date-time
  --travelAppointmentId: string # nullable
  --travelTimeMins: int # format: int32
]: any -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/consumer/v1/appointments/($id)/reschedule")
  let body = {endDateTime: $endDateTime, resourceId: $resourceId, resourceIds: $resourceIds, serviceId: $serviceId, startDateTime: $startDateTime, travelAppointmentId: $travelAppointmentId, travelTimeMins: $travelTimeMins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reserve Appointment
#
# PUT /consumer/v1/appointments/{id}/reserve
# --appointmentBookingFields item shape: {name?: string, value?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --customerBookingFields item shape: {name?: string, value?: string}
export def "consumer-appointments-reserve put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sendNotifications: string@bool-completer
  --appointmentBookingFields: list # nullable — item shape: {name?: string, value?: string}
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --customerBookingFields: list # nullable — item shape: {name?: string, value?: string}
  --customerMessage: string # nullable
  --email: string # nullable
  --name: string # nullable
  --notes: string # nullable
  --phone: string # nullable
  --phoneExt: string # nullable
  --phoneType: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sendNotifications" $sendNotifications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumer/v1/appointments/($id)/reserve" $qp)
  let body = {appointmentBookingFields: $appointmentBookingFields, customFields: $customFields, customerBookingFields: $customerBookingFields, customerMessage: $customerMessage, email: $email, name: $name, notes: $notes, phone: $phone, phoneExt: $phoneExt, phoneType: $phoneType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Available Times
#
# GET /consumer/v1/availability/{serviceId}/{startDate}/{endDate}
export def "consumer-availability get" [
  serviceId: string
  startDate: string
  endDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # Format Military Time Start Time for availability search. Defaults to Business Hours Start (format: int32)
  --endTime: int # Format Military Time. End Time for availability search. Defaults to Business Hours End (format: int32)
  --locationId: string # Id of business location, defaults to primary business location
  --resourceId: string # Resource Id for availability search
  --resourceGroupId: string # Resource Group Id for availability search
  --resourceIds: string # Comma separated Resource Id's for availability search
  --roundRobin: string # Round robin choice 0=none, 1=random, 2=balanced
  --duration: int # Duration of the service if different from default (format: int32)
  --interval: int # Booking Interval if different than the default (format: int32)
  --timezoneName: string # Requested IANA timezone Id to view availability
  --tzOffset: int # Request timezone offset to view availability (format: int32)
  --destination: string # For calculating travel based availability, requires distance scope
  --dayAvailabilityStartDate: string # Format YYYY-DD-YY: Start date for day availability, defaults to startDate (format: date-time)
  --dayAvailability: int # Number of days of day availability to return (format: int32)
  --firstDayAvailable: string@bool-completer # Return available times for the first available day
]: nothing -> record<availableDays: table<available: bool, bookingCount: int, bookingLimit: int, closed: bool, date: string, object: string, reason: string, reasonCode: int>, availableTimes: table<allowableBookings: int, allowableCapacity: int, availableBookings: int, availableCapacity: int, date: string, displayTime: string, duration: int, endDateTime: string, resourceId: string, startDateTime: string, time: int, travelAppointmentId: string, travelTimeMins: int>, businessName: string, calendarId: string, calendarResourceGroupId: string, endDate: string, firstAvailableDate: string, locationId: string, object: string, resourceDescription: string, resourceId: string, resourceIds: string, resourceName: string, serviceDescription: string, serviceDuration: int, serviceId: string, serviceName: string, startDate: string, timezoneName: string, tzRequested: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "locationId" $locationId "scalar") (serialize-qp "resourceId" $resourceId "scalar") (serialize-qp "resourceGroupId" $resourceGroupId "scalar") (serialize-qp "resourceIds" $resourceIds "scalar") (serialize-qp "roundRobin" $roundRobin "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "timezoneName" $timezoneName "scalar") (serialize-qp "tzOffset" $tzOffset "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "dayAvailabilityStartDate" $dayAvailabilityStartDate "scalar") (serialize-qp "dayAvailability" $dayAvailability "scalar") (serialize-qp "firstDayAvailable" $firstDayAvailable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumer/v1/availability/($serviceId)/($startDate)/($endDate)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Available Days
#
# GET /consumer/v1/availability/{serviceId}/{startDate}/{endDate}/days
export def "consumer-availability-days get" [
  serviceId: string
  startDate: string
  endDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # Id of business location, defaults to primary business location
  --resourceId: string # Resource Id to filter on
  --tzOffset: int # Timezone offset to view availability for (format: int32)
]: nothing -> record<availableDays: table<available: bool, bookingCount: int, bookingLimit: int, closed: bool, date: string, object: string, reason: string, reasonCode: int>, object: string, resourceDescription: string, resourceId: string, resourceName: string, serviceDescription: string, serviceId: string, serviceName: string, tzRequested: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "resourceId" $resourceId "scalar") (serialize-qp "tzOffset" $tzOffset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumer/v1/availability/($serviceId)/($startDate)/($endDate)/days" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Unavailable Times
#
# GET /consumer/v1/availability/{serviceId}/{startDate}/{endDate}/unavailable
export def "consumer-availability-unavailable get" [
  serviceId: string
  startDate: string
  endDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # Id of business location, defaults to primary business location
  --resourceId: string # Resource Id to filter on
  --duration: int # Duration of the service if different from default (format: int32)
  --tzOffset: int # Request timezone offset to view unavailable times (format: int32)
  --skipTimePastUnavailability: string@bool-completer # Set as true to remove Time Past (TP) blocks in the response
]: nothing -> record<object: string, unavailableTimes: table<calendarId: string, date: string, endDateTime: string, entityId: int, entityType: string, fromTime: int, locationId: string, objectName: string, reason: string, reasonCode: string, resourceId: string, resourceName: string, serviceId: string, serviceName: string, startDateTime: string, toTime: int, tzOffset: int>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "resourceId" $resourceId "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "tzOffset" $tzOffset "scalar") (serialize-qp "skipTimePastUnavailability" $skipTimePastUnavailability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumer/v1/availability/($serviceId)/($startDate)/($endDate)/unavailable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Customers
#
# GET /consumer/v1/customers
export def "consumer-customers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location, defaults to primary business location
  --groupId: string # Filter by groupId
  --email: string # Filter by email address
  --lastname: string # Filter by lastname
  --deleted: string@bool-completer # Filter by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, birthdate: string, businessName: string, companyName: string, contact: record, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Customer
#
# POST /consumer/v1/customers
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --contact shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
export def "consumer-customers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --email: string # nullable
  --firstname: string # nullable
  --lastname: string # nullable
  --locationId: string # nullable
  --name: string # nullable
  --notificationType: string # 0 = default(Email), 1 = Email, 2 = SMS, 3 = Email and SMS (nullable)
  --sendLeadNotification: string@bool-completer
  --stripeCustomerId: string # nullable
  --type: int # nullable, format: int32
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/consumer/v1/customers")
  let body = {address: $address, contact: $contact, customFields: $customFields, email: $email, firstname: $firstname, lastname: $lastname, locationId: $locationId, name: $name, notificationType: $notificationType, sendLeadNotification: $sendLeadNotification, stripeCustomerId: $stripeCustomerId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Customer Booking Fields
#
# GET /consumer/v1/customers/bookingfields
export def "consumer-customers-bookingfields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location, defaults to primary business location
]: nothing -> record<bookingFields: table<businessId: string, companyId: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/customers/bookingfields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Country Codes
#
# GET /consumer/v1/customers/countries
export def "consumer-customers-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<code: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/consumer/v1/customers/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Customer Custom Fields
#
# GET /consumer/v1/customers/customfields
export def "consumer-customers-customfields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location, defaults to primary business location
  --leadQuestions: string@bool-completer # A true/false indicator to filter on custom fields used for lead questions
]: nothing -> record<customFields: table<fieldKey: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldPublic: bool, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "leadQuestions" $leadQuestions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/customers/customfields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Country States
#
# GET /consumer/v1/customers/states
export def "consumer-customers-states get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string
]: nothing -> table<code: string, country: string, countryName: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/customers/states" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Customer
#
# DELETE /consumer/v1/customers/{id}
export def "consumer-customers delete" [
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
  let full_url = (build-url $base $"/consumer/v1/customers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Customer
#
# GET /consumer/v1/customers/{id}
export def "consumer-customers get" [
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
  let full_url = (build-url $base $"/consumer/v1/customers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Customer
#
# PUT /consumer/v1/customers/{id}
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --contact shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
export def "consumer-customers put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --customFields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --email: string # nullable
  --firstname: string # nullable
  --lastname: string # nullable
  --locationId: string # nullable
  --name: string # nullable
  --notificationType: string # 0 = default(Email), 1 = Email, 2 = SMS, 3 = Email and SMS (nullable)
  --stripeCustomerId: string # nullable
  --type: int # nullable, format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/consumer/v1/customers/($id)")
  let body = {address: $address, contact: $contact, customFields: $customFields, email: $email, firstname: $firstname, lastname: $lastname, locationId: $locationId, name: $name, notificationType: $notificationType, stripeCustomerId: $stripeCustomerId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Locations
#
# GET /consumer/v1/locations
export def "consumer-locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Location name (full or partial)
  --nearestTo: string # Search by distance nearest Geocoords, City, Postal/Zip Code
  --proximity: int # Maximum distance to display (format: int32)
  --units: string # Distance either imperial(miles), metric(kilometers)
  --serviceId: string # Locations that offer this service
  --friendlyId: string # Frienldy Id of location
  --regionId: string # Locations within a specific region
  --ignorePrimary: string@bool-completer # Don't include the Primary Location
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit, default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, adminEmail: string, adminName: string, appointmentReminders: record, businessHolidays: list, businessHours: record, companyId: string, companyName: string, defaults: record, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list, settings: record, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record, website: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nearestTo" $nearestTo "scalar") (serialize-qp "proximity" $proximity "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "serviceId" $serviceId "scalar") (serialize-qp "friendlyId" $friendlyId "scalar") (serialize-qp "regionId" $regionId "scalar") (serialize-qp "ignorePrimary" $ignorePrimary "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Location
#
# GET /consumer/v1/locations/{id}
export def "consumer-locations get" [
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
  let full_url = (build-url $base $"/consumer/v1/locations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Resource Groups
#
# GET /consumer/v1/resourcegroups
export def "consumer-resourcegroups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location, defaults to primary business location
  --deleted: string@bool-completer # Filter results by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/resourcegroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Resource Group
#
# GET /consumer/v1/resourcegroups/{id}
export def "consumer-resourcegroups get" [
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
  let full_url = (build-url $base $"/consumer/v1/resourcegroups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Resources
#
# GET /consumer/v1/resources
export def "consumer-resources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location, defaults to primary business location
  --resourceGroupId: int # Filter by groupId (format: int32)
  --email: string # Filter by email address
  --name: string # Search by name, supports Partial name search
  --sortOrder: string # Specify sort order of response
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarId: string, groupId: string, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, outlookCalendarId: string, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "resourceGroupId" $resourceGroupId "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Resource
#
# GET /consumer/v1/resources/{id}
export def "consumer-resources get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarId: string, groupId: string, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, outlookCalendarId: string, recurringAvailability: bool, services: table<object: string, resourceId: int, resourceName: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/consumer/v1/resources/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Resource Linked Services
#
# GET /consumer/v1/resources/{id}/services
export def "consumer-resources-services get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<object: string, resourceId: int, resourceName: string, serviceId: int, serviceName: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumer/v1/resources/($id)/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Service Groups
#
# GET /consumer/v1/servicegroups
export def "consumer-servicegroups list" [
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
  let full_url = (build-url $base "/consumer/v1/servicegroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Service Group
#
# GET /consumer/v1/servicegroups/{id}
export def "consumer-servicegroups get" [
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
  let full_url = (build-url $base $"/consumer/v1/servicegroups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Services
#
# GET /consumer/v1/services
export def "consumer-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of business location, defaults to primary business location
  --serviceGroupId: int # Filter by groupId (format: int32)
  --defaultService: string@bool-completer # Filter by default service, default is false
  --allLocations: string@bool-completer # Search All Locations, default is false
  --scope: string@scope-completer # Filter by scope, Company, Location or All, default is All
  --name: string # Filter by Name, supports Partial name search
  --serviceId: string # Filter by ServiceId, using this parameter would ignore all other parameters
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
  --sortOrder: string@sortOrder-completer # Sort results using Natural Sort or Sorted alphabetically by Service Names, default is natural
  --sortDescending: string@bool-completer # Sort results in Descending Order, default true
]: nothing -> record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "serviceGroupId" $serviceGroupId "scalar") (serialize-qp "defaultService" $defaultService "scalar") (serialize-qp "allLocations" $allLocations "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "serviceId" $serviceId "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "sortDescending" $sortDescending "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Service Allocation
#
# GET /consumer/v1/services/allocations/{id}
export def "consumer-services-allocations get-by-id" [
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
  let full_url = (build-url $base $"/consumer/v1/services/allocations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Service
#
# GET /consumer/v1/services/{id}
export def "consumer-services get" [
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
  let full_url = (build-url $base $"/consumer/v1/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Service Allocations
#
# GET /consumer/v1/services/{id}/allocations
export def "consumer-services-allocations get-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locationId: string # id of the location, defaults to the primary location
  --resourceId: string # id of the resource to filter on
  --startDate: string # Format YYYY-MM-DD: Filter allocations on/after startDate (format: date-time)
  --endDate: string # Format YYYY-MM-DD. Filter allocations on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, resourceAddress: record, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "resourceId" $resourceId "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumer/v1/services/($id)/allocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Resources for Service
#
# GET /consumer/v1/services/{id}/resources
export def "consumer-services-resources get" [
  id: string
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
]: nothing -> record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarId: string, groupId: string, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, outlookCalendarId: string, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $locationId "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumer/v1/services/($id)/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
